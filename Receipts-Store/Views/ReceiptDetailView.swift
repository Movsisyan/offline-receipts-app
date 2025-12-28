//
//  ReceiptDetailView.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var receipt: Receipt
    
    @State private var fullImage: UIImage?
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var showFullScreenImage = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Receipt Image
                receiptImageSection
                
                // Parsed Information
                parsedInfoSection
                
                // Line Items
                if !receipt.items.isEmpty {
                    lineItemsSection
                }
                
                // Raw OCR Text
                if let rawText = receipt.rawText, !rawText.isEmpty {
                    rawTextSection(rawText)
                }
                
                // Notes
                notesSection
            }
            .padding()
        }
        .navigationTitle(receipt.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditReceiptView(receipt: receipt)
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            FullScreenImageView(image: fullImage)
        }
        .confirmationDialog("Delete Receipt", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteReceipt()
            }
        } message: {
            Text("Are you sure you want to delete this receipt? This cannot be undone.")
        }
        .task {
            await loadFullImage()
        }
    }
    
    // MARK: - Sections
    
    private var receiptImageSection: some View {
        ZStack {
            if let image = fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture {
                        showFullScreenImage = true
                    }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        ProgressView()
                    }
            }
        }
    }
    
    private var parsedInfoSection: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Store", value: receipt.displayName, icon: "storefront")
            InfoRow(label: "Date", value: receipt.formattedDate, icon: "calendar")
            InfoRow(label: "Total", value: receipt.formattedTotal, icon: "dollarsign.circle", valueColor: .green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)
            
            ForEach(receipt.items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.subheadline)
                        if !item.displayQuantity.isEmpty {
                            Text(item.displayQuantity)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
                
                if item.id != receipt.items.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func rawTextSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Raw Text")
                    .font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
            }
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            
            if let notes = receipt.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No notes")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Actions
    
    private func loadFullImage() async {
        fullImage = await ImageStorageService.shared.loadImageAsync(filename: receipt.imageFileName)
    }
    
    private func deleteReceipt() {
        Task {
            try? await ImageStorageService.shared.deleteImage(filename: receipt.imageFileName)
        }
        modelContext.delete(receipt)
        dismiss()
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage?
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                        }
                                    }
                                }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptDetailView(receipt: Receipt(
            imageFileName: "test.jpg",
            rawText: "Sample receipt text",
            storeName: "Sample Store",
            transactionDate: Date(),
            total: 42.99
        ))
    }
    .modelContainer(for: Receipt.self, inMemory: true)
}
