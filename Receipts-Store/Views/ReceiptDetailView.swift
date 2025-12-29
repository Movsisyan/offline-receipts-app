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
        ZStack {
            AppTheme.cream.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
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
                .padding(20)
            }
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
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(AppTheme.black)
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
        .tint(AppTheme.orange)
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
                        .onTapGesture {
                            showFullScreenImage = true
                        }
                        .overlay(alignment: .bottomTrailing) {
                            // Zoom hint
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption2)
                                Text("Tap to zoom")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .padding(12)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 200)
                        .overlay {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                        }
                }
                
                // Page navigation arrows
                if receipt.isMultiPage && !loadedImages.isEmpty {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentPageIndex = max(0, currentPageIndex - 1)
                            }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4)
                        }
                        .disabled(currentPageIndex == 0)
                        .opacity(currentPageIndex == 0 ? 0.3 : 1)
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentPageIndex = min(receipt.pageCount - 1, currentPageIndex + 1)
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4)
                        }
                        .disabled(currentPageIndex == receipt.pageCount - 1)
                        .opacity(currentPageIndex == receipt.pageCount - 1 ? 0.3 : 1)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            // Page indicator
            if receipt.isMultiPage {
                HStack(spacing: 6) {
                    ForEach(0..<receipt.pageCount, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPageIndex ? AppTheme.accent : Color.gray.opacity(0.3))
                            .frame(width: index == currentPageIndex ? 20 : 8, height: 8)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentPageIndex = index
                                }
                            }
                    }
                }
                
                Text("Page \(currentPageIndex + 1) of \(receipt.pageCount)")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
    
    private var parsedInfoSection: some View {
        VStack(spacing: 1) {
            // Store Info
            VStack(alignment: .leading, spacing: 16) {
                Text("STORE")
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(AppTheme.gray)
                
                VStack(spacing: 12) {
                    HermesInfoRow(label: "Name", value: receipt.displayName)
                    
                    if let address = receipt.storeAddress, !address.isEmpty {
                        HermesInfoRow(label: "Address", value: address)
                    }
                    
                    if let phone = receipt.storePhone, !phone.isEmpty {
                        HermesInfoRow(label: "Phone", value: phone)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.white)
            
            // Transaction Info
            VStack(alignment: .leading, spacing: 16) {
                Text("TRANSACTION")
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(AppTheme.gray)
                
                VStack(spacing: 12) {
                    HermesInfoRow(label: "Date", value: receipt.formattedDate)
                    
                    if let txNumber = receipt.transactionNumber, !txNumber.isEmpty {
                        HermesInfoRow(label: "Receipt #", value: txNumber)
                    }
                    
                    HermesInfoRow(label: "Category", value: receipt.category.rawValue)
                    
                    if let folder = receipt.folder {
                        HStack {
                            Text("Folder")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.gray)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(folder.color)
                                    .frame(width: 8, height: 8)
                                Text(folder.name)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.black)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.white)
            
            // Amount
            VStack(alignment: .leading, spacing: 16) {
                Text("AMOUNT")
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(AppTheme.gray)
                
                VStack(spacing: 12) {
                    if receipt.subtotal != nil {
                        HermesInfoRow(label: "Subtotal", value: receipt.formattedSubtotal)
                    }
                    
                    if receipt.tax != nil {
                        HermesInfoRow(label: "Tax", value: receipt.formattedTax)
                    }
                    
                    if receipt.tips != nil {
                        HermesInfoRow(label: "Tips", value: receipt.formattedTips)
                    }
                    
                    PremiumDivider()
                        .padding(.vertical, 4)
                    
                    HStack {
                        Text("Total")
                            .font(.system(.subheadline, design: .serif, weight: .regular))
                            .foregroundStyle(AppTheme.black)
                        
                        Spacer()
                        
                        Text(receipt.formattedTotal)
                            .font(.system(.title2, design: .default, weight: .medium))
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.white)
            
            // Payment
            VStack(alignment: .leading, spacing: 16) {
                Text("PAYMENT")
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(AppTheme.gray)
                
                HermesInfoRow(label: "Method", value: receipt.paymentDisplay)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(AppTheme.lightGray, lineWidth: 1)
        )
    }
    
    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ITEMS")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
                .padding(.bottom, 16)
            
            ForEach(receipt.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.black)
                        if !item.displayQuantity.isEmpty {
                            Text(item.displayQuantity)
                                .font(.caption)
                                .foregroundStyle(AppTheme.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.formattedPrice)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.orange)
                }
                .padding(.vertical, 12)
                
                if item.id != receipt.items.last?.id {
                    PremiumDivider()
                }
            }
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(AppTheme.lightGray, lineWidth: 1)
        )
    }
    
    private func rawTextSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("RAW TEXT")
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(AppTheme.gray)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Text("COPY")
                        .font(.system(.caption2, design: .default, weight: .regular))
                        .tracking(1)
                        .foregroundStyle(AppTheme.orange)
                }
            }
            .padding(.bottom, 16)
            
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppTheme.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.offWhite)
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(AppTheme.lightGray, lineWidth: 1)
        )
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NOTES")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
                .padding(.bottom, 16)
            
            if let notes = receipt.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Tap Edit to add notes")
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(AppTheme.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(AppTheme.lightGray, lineWidth: 1)
        )
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
        ZStack {
            Color.black.ignoresSafeArea()
            
            if images.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("No Images")
                        .font(.system(.caption, design: .default, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.5))
                }
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
                                                withAnimation(.easeOut(duration: 0.2)) {
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
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Custom page indicator and close button
            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Page indicator
                if images.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? AppTheme.orange : Color.white.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
                }
            }
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
