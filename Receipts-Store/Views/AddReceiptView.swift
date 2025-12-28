//
//  AddReceiptView.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import SwiftUI
import SwiftData

enum ReceiptCaptureMode {
    case single
    case multi
}

struct AddReceiptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Initial folder (when adding from a folder view)
    var initialFolder: Folder?
    
    // Mode selection
    @State private var captureMode: ReceiptCaptureMode?
    
    // Multi-page support
    @State private var capturedImages: [UIImage] = []
    @State private var currentPageIndex = 0
    
    // Folder selection
    @State private var selectedFolder: Folder?
    @State private var showFolderPicker = false
    
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var isProcessing = false
    @State private var processingStatus = "Preparing..."
    @State private var parsedData: ParsedReceiptData?
    @State private var rawText: String?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var hasProcessed = false
    
    init(initialFolder: Folder? = nil) {
        self.initialFolder = initialFolder
        _selectedFolder = State(initialValue: initialFolder)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if captureMode == nil {
                    // Mode selection
                    modeSelectionView
                } else if !capturedImages.isEmpty {
                    // Show captured images
                    capturedImagesView
                } else {
                    // Show capture options based on mode
                    captureOptionsView
                }
            }
            .padding()
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if parsedData != nil && !isProcessing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveReceipt()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureView { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView(selectedFolder: $selectedFolder)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Mode Selection View
    
    private var modeSelectionView: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Elegant icon
                Image(systemName: "doc.text")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(AppTheme.orange)
                    .padding(.bottom, 24)
                
                Text("ADD RECEIPT")
                    .font(.system(.caption, design: .default, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(AppTheme.gray)
                    .padding(.bottom, 8)
                
                Text("Choose your capture method")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AppTheme.black)
                
                Spacer()
                
                VStack(spacing: 16) {
                    // Single Page
                    Button {
                        captureMode = .single
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SINGLE PAGE")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.black)
                                
                                Text("Quick capture with instant processing")
                                    .font(.system(.caption))
                                    .foregroundStyle(AppTheme.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(AppTheme.gray)
                        }
                        .padding(20)
                        .background(AppTheme.white)
                        .overlay(
                            Rectangle()
                                .strokeBorder(AppTheme.lightGray, lineWidth: 1)
                        )
                    }
                    
                    // Multi Page
                    Button {
                        captureMode = .multi
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MULTI-PAGE")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.black)
                                
                                Text("Add all pages, then process together")
                                    .font(.system(.caption))
                                    .foregroundStyle(AppTheme.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(AppTheme.gray)
                        }
                        .padding(20)
                        .background(AppTheme.white)
                        .overlay(
                            Rectangle()
                                .strokeBorder(AppTheme.lightGray, lineWidth: 1)
                        )
                    }
                    
                    // Folder selection
                    Button {
                        showFolderPicker = true
                    } label: {
                        HStack {
                            if let folder = selectedFolder {
                                Circle()
                                    .fill(folder.color)
                                    .frame(width: 8, height: 8)
                            }
                            
                            Text(selectedFolder?.name.uppercased() ?? "NO FOLDER")
                                .font(.system(.caption2, design: .default, weight: .medium))
                                .tracking(1)
                                .foregroundStyle(selectedFolder != nil ? AppTheme.orange : AppTheme.gray)
                            
                            Spacer()
                            
                            Text("CHANGE")
                                .font(.system(.caption2, design: .default, weight: .regular))
                                .tracking(1)
                                .foregroundStyle(AppTheme.orange)
                        }
                        .padding(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Handle Captured Image
    
    private func handleCapturedImage(_ image: UIImage) {
        capturedImages.append(image)
        currentPageIndex = capturedImages.count - 1
        
        if captureMode == .single {
            // Single mode: process immediately
            Task {
                await processAllImages()
            }
        } else {
            // Multi mode: just add, don't process
            hasProcessed = false
            parsedData = nil
            rawText = nil
        }
    }
    
    // MARK: - Capture Options
    
    private var captureOptionsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: captureMode == .single ? "doc" : "doc.on.doc")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(captureMode == .single ? "Single Page Receipt" : "Multi-Page Receipt")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text(captureMode == .single ? "Take a photo to scan immediately" : "Add all pages, then process together")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                if CameraCaptureView.isCameraAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Button {
                    showPhotoLibrary = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Back to mode selection
                Button {
                    captureMode = nil
                } label: {
                    Text("Change Mode")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Captured Images View
    
    private var capturedImagesView: some View {
        VStack(spacing: 16) {
            // Mode indicator
            HStack {
                Image(systemName: captureMode == .single ? "doc" : "doc.on.doc")
                    .foregroundStyle(.secondary)
                Text(captureMode == .single ? "Single Page" : "Multi-Page")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            // Page indicator and image preview
            ZStack {
                // Current page image
                if currentPageIndex < capturedImages.count {
                    Image(uiImage: capturedImages[currentPageIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: hasProcessed ? 150 : 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Page navigation (multi-page only)
                if capturedImages.count > 1 {
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
                                currentPageIndex = min(capturedImages.count - 1, currentPageIndex + 1)
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                        }
                        .disabled(currentPageIndex == capturedImages.count - 1)
                        .opacity(currentPageIndex == capturedImages.count - 1 ? 0.3 : 1)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            // Page indicator dots (multi-page only)
            if capturedImages.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<capturedImages.count, id: \.self) { index in
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
            }
            
            // Page count and add more button (multi-page mode)
            if captureMode == .multi {
                HStack {
                    Text("\(capturedImages.count) page\(capturedImages.count == 1 ? "" : "s") added")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !isProcessing && !hasProcessed {
                        Menu {
                            if CameraCaptureView.isCameraAvailable {
                                Button {
                                    showCamera = true
                                } label: {
                                    Label("Take Photo", systemImage: "camera")
                                }
                            }
                            
                            Button {
                                showPhotoLibrary = true
                            } label: {
                                Label("Choose from Library", systemImage: "photo")
                            }
                        } label: {
                            Label("Add Page", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            // Processing button or results
            if isProcessing {
                processingView
            } else if hasProcessed, let parsed = parsedData {
                parsedResultView(parsed)
            } else if captureMode == .multi {
                // Process button - only for multi-page mode
                Button {
                    Task {
                        await processAllImages()
                    }
                } label: {
                    Label("Process Receipt", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Action buttons
            if !isProcessing {
                actionButtons
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Remove current page (multi-page with multiple images)
            if captureMode == .multi && capturedImages.count > 1 && !hasProcessed {
                Button {
                    removeCurrentPage()
                } label: {
                    Label("Remove", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Retake/Start over
            Button {
                if hasProcessed && captureMode == .multi {
                    // Allow adding more pages after processing
                    hasProcessed = false
                    parsedData = nil
                    rawText = nil
                } else {
                    // Start over
                    capturedImages = []
                    currentPageIndex = 0
                    parsedData = nil
                    rawText = nil
                    hasProcessed = false
                }
            } label: {
                Label(
                    hasProcessed ? "Edit Pages" : (captureMode == .single ? "Retake" : "Start Over"),
                    systemImage: hasProcessed ? "pencil" : "arrow.counterclockwise"
                )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func removeCurrentPage() {
        guard capturedImages.count > 1 else { return }
        capturedImages.remove(at: currentPageIndex)
        currentPageIndex = min(currentPageIndex, capturedImages.count - 1)
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(processingStatus)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Parsed Result View
    
    private func parsedResultView(_ data: ParsedReceiptData) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Parsed Receipt")
                        .font(.headline)
                    Spacer()
                    if captureMode == .multi {
                        Button {
                            hasProcessed = false
                            parsedData = nil
                            rawText = nil
                        } label: {
                            Label("Re-scan", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                }
                
                // Store Information
                VStack(spacing: 8) {
                    SectionHeader(title: "Store", icon: "storefront")
                    
                    if let store = data.storeName {
                        ParsedRow(label: "Name", value: store)
                    }
                    if let address = data.storeAddress {
                        ParsedRow(label: "Address", value: address)
                    }
                    if let phone = data.storePhone {
                        ParsedRow(label: "Phone", value: phone)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Transaction Details
                VStack(spacing: 8) {
                    SectionHeader(title: "Transaction", icon: "calendar")
                    
                    if let dateStr = data.dateString {
                        ParsedRow(label: "Date", value: dateStr)
                    }
                    if let txNum = data.transactionNumber {
                        ParsedRow(label: "Receipt #", value: txNum)
                    }
                    if let category = data.suggestedCategory {
                        ParsedRow(label: "Category", value: category)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Financial Breakdown
                VStack(spacing: 8) {
                    SectionHeader(title: "Amount", icon: "dollarsign.circle")
                    
                    if let subtotal = data.subtotal {
                        ParsedRow(label: "Subtotal", value: String(format: "$%.2f", subtotal))
                    }
                    if let tax = data.tax {
                        ParsedRow(label: "Tax", value: String(format: "$%.2f", tax))
                    }
                    if let tips = data.tips {
                        ParsedRow(label: "Tips", value: String(format: "$%.2f", tips))
                    }
                    if let total = data.total {
                        ParsedRow(label: "Total", value: String(format: "$%.2f", total), valueColor: .green, isBold: true)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Payment Information
                if data.paymentMethod != nil || data.cardLastFourDigits != nil {
                    VStack(spacing: 8) {
                        SectionHeader(title: "Payment", icon: "creditcard")
                        
                        if let method = data.paymentMethod {
                            ParsedRow(label: "Method", value: method)
                        }
                        if let lastFour = data.cardLastFourDigits {
                            ParsedRow(label: "Card", value: "••••\(lastFour)")
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Items List
                if let items = data.items, !items.isEmpty {
                    VStack(spacing: 8) {
                        SectionHeader(title: "Items (\(items.count))", icon: "list.bullet")
                        
                        ForEach(items, id: \.self) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline)
                                    if let qty = item.quantity, qty > 1 {
                                        Text("Qty: \(qty)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if let price = item.price {
                                    Text(String(format: "$%.2f", price))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxHeight: 300)
    }
    
    // MARK: - Image Processing
    
    private func processAllImages() async {
        guard !capturedImages.isEmpty else { return }
        
        isProcessing = true
        defer { 
            isProcessing = false
            hasProcessed = true
        }
        
        do {
            // Step 1: OCR all pages
            if capturedImages.count == 1 {
                processingStatus = "Extracting text..."
            } else {
                processingStatus = "Extracting text from \(capturedImages.count) pages..."
            }
            
            var allText = ""
            for (index, image) in capturedImages.enumerated() {
                if capturedImages.count > 1 {
                    processingStatus = "Reading page \(index + 1) of \(capturedImages.count)..."
                }
                let pageText = try await TextRecognitionService.shared.recognizeText(in: image)
                if !pageText.isEmpty {
                    if !allText.isEmpty && capturedImages.count > 1 {
                        allText += "\n\n--- Page \(index + 2) ---\n\n"
                    }
                    allText += pageText
                }
            }
            
            rawText = allText
            
            guard !allText.isEmpty else {
                errorMessage = "Could not extract any text from the image\(capturedImages.count > 1 ? "s" : ""). Try clearer photos."
                showError = true
                return
            }
            
            // Step 2: LLM Parsing
            processingStatus = "Analyzing receipt..."
            
            let parsingService = ReceiptParsingService.shared
            
            if await parsingService.isModelAvailable {
                parsedData = try await parsingService.parseReceipt(from: allText)
            } else {
                processingStatus = "Using basic parsing..."
                parsedData = await parsingService.parseReceiptWithFallback(from: allText)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Save Receipt
    
    private func saveReceipt() {
        guard !capturedImages.isEmpty else { return }
        
        Task {
            do {
                // Save all images
                var filenames: [String] = []
                for image in capturedImages {
                    let filename = try await ImageStorageService.shared.saveImage(image)
                    filenames.append(filename)
                }
                
                // Create receipt using the parsed data
                let receipt: Receipt
                if let parsed = parsedData {
                    receipt = parsed.createReceipt(imageFileNames: filenames, rawText: rawText)
                } else {
                    receipt = Receipt(imageFileNames: filenames, rawText: rawText)
                }
                
                // Assign folder if selected
                receipt.folder = selectedFolder
                
                // Save to SwiftData
                await MainActor.run {
                    modelContext.insert(receipt)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save receipt: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

struct ParsedRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(isBold ? .semibold : .medium)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    AddReceiptView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
