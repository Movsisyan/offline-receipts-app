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
    
    // Multi-page support
    @State private var loadedImages: [UIImage] = []
    @State private var currentPageIndex = 0
    
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
            FullScreenImageView(images: loadedImages, initialIndex: currentPageIndex)
        }
        .confirmationDialog("Delete Receipt", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteReceipt()
            }
        } message: {
            Text("Are you sure you want to delete this receipt? This cannot be undone.")
        }
        .task {
            await loadAllImages()
        }
    }
    
    // MARK: - Sections
    
    private var receiptImageSection: some View {
        VStack(spacing: 12) {
            // Image with page navigation
            ZStack {
                if !loadedImages.isEmpty && currentPageIndex < loadedImages.count {
                    Image(uiImage: loadedImages[currentPageIndex])
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
                
                // Page navigation arrows
                if receipt.isMultiPage {
                    HStack {
                        Button {
                            withAnimation {
                                currentPageIndex = max(0, currentPageIndex - 1)
                            }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .disabled(currentPageIndex == 0)
                        .opacity(currentPageIndex == 0 ? 0.3 : 1)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                currentPageIndex = min(receipt.pageCount - 1, currentPageIndex + 1)
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .disabled(currentPageIndex == receipt.pageCount - 1)
                        .opacity(currentPageIndex == receipt.pageCount - 1 ? 0.3 : 1)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            // Page indicator
            if receipt.isMultiPage {
                HStack(spacing: 8) {
                    ForEach(0..<receipt.pageCount, id: \.self) { index in
                        Circle()
                            .fill(index == currentPageIndex ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation {
                                    currentPageIndex = index
                                }
                            }
                    }
                }
                
                Text("Page \(currentPageIndex + 1) of \(receipt.pageCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var parsedInfoSection: some View {
        VStack(spacing: 16) {
            // Store Info
            VStack(spacing: 12) {
                InfoRow(label: "Store", value: receipt.displayName, icon: "storefront")
                
                if let address = receipt.storeAddress, !address.isEmpty {
                    InfoRow(label: "Address", value: address, icon: "mappin.and.ellipse")
                }
                
                if let phone = receipt.storePhone, !phone.isEmpty {
                    InfoRow(label: "Phone", value: phone, icon: "phone")
                }
            }
            
            Divider()
            
            // Transaction Info
            VStack(spacing: 12) {
                InfoRow(label: "Date", value: receipt.formattedDate, icon: "calendar")
                
                if let txNumber = receipt.transactionNumber, !txNumber.isEmpty {
                    InfoRow(label: "Receipt #", value: txNumber, icon: "number")
                }
                
                InfoRow(label: "Category", value: receipt.category.rawValue, icon: receipt.category.icon)
            }
            
            Divider()
            
            // Financial Breakdown
            VStack(spacing: 12) {
                if receipt.subtotal != nil {
                    InfoRow(label: "Subtotal", value: receipt.formattedSubtotal, icon: "cart")
                }
                
                if receipt.tax != nil {
                    InfoRow(label: "Tax", value: receipt.formattedTax, icon: "percent")
                }
                
                if receipt.tips != nil {
                    InfoRow(label: "Tips", value: receipt.formattedTips, icon: "heart")
                }
                
                InfoRow(label: "Total", value: receipt.formattedTotal, icon: "dollarsign.circle", valueColor: .green)
            }
            
            Divider()
            
            // Payment Info
            VStack(spacing: 12) {
                InfoRow(label: "Payment", value: receipt.paymentDisplay, icon: receipt.paymentMethod.icon)
            }
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
    
    private func loadAllImages() async {
        var images: [UIImage] = []
        for filename in receipt.imageFileNames {
            if let image = await ImageStorageService.shared.loadImageAsync(filename: filename) {
                images.append(image)
            }
        }
        await MainActor.run {
            loadedImages = images
        }
    }
    
    private func deleteReceipt() {
        Task {
            // Delete all image files
            for filename in receipt.imageFileNames {
                try? await ImageStorageService.shared.deleteImage(filename: filename)
            }
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
    let images: [UIImage]
    let initialIndex: Int
    
    @State private var currentIndex: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    init(images: [UIImage], initialIndex: Int = 0) {
        self.images = images
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if images.isEmpty {
                    Text("No images")
                        .foregroundStyle(.white)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            GeometryReader { geometry in
                                Image(uiImage: images[index])
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
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
                
                // Page indicator for multi-page
                if images.count > 1 {
                    VStack {
                        Spacer()
                        Text("Page \(currentIndex + 1) of \(images.count)")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(.bottom, 60)
                    }
                }
            }
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
            imageFileNames: ["test.jpg"],
            rawText: "Sample receipt text",
            storeName: "Sample Store",
            transactionDate: Date(),
            total: 42.99
        ))
    }
    .modelContainer(for: Receipt.self, inMemory: true)
}
