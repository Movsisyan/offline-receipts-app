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
    
    @State private var iconBounce = false
    
    private var modeSelectionView: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Animated elegant icon
                ZStack {
                    Circle()
                        .fill(AppTheme.orangeLight)
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconBounce ? 1.05 : 1.0)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(AppTheme.orange)
                }
                .padding(.bottom, 32)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        iconBounce = true
                    }
                }
                
                Text("ADD RECEIPT")
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(AppTheme.gray)
                    .padding(.bottom, 8)
                
                Text("Choose your capture method")
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(AppTheme.black)
                
                Spacer()
                
                VStack(spacing: 12) {
                    // Single Page - Card
                    ModeSelectionCard(
                        icon: "doc",
                        title: "SINGLE PAGE",
                        subtitle: "Quick capture with instant processing"
                    ) {
                        withAnimation(AppTheme.springAnimation) {
                            captureMode = .single
                        }
                    }
                    
                    // Multi Page - Card
                    ModeSelectionCard(
                        icon: "doc.on.doc",
                        title: "MULTI-PAGE",
                        subtitle: "Add all pages, then process together"
                    ) {
                        withAnimation(AppTheme.springAnimation) {
                            captureMode = .multi
                        }
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
        ZStack {
            AppTheme.cream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Elegant icon
                Image(systemName: captureMode == .single ? "doc" : "doc.on.doc")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(AppTheme.orange)
                    .padding(.bottom, 24)
                
                Text(captureMode == .single ? "SINGLE PAGE" : "MULTI-PAGE")
                    .font(.system(.caption, design: .default, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(AppTheme.gray)
                    .padding(.bottom, 8)
                
                Text(captureMode == .single ? "Quick capture with instant processing" : "Add all pages, then process together")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AppTheme.black)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 16) {
                    if CameraCaptureView.isCameraAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.system(size: 14, weight: .light))
                                Text("TAKE PHOTO")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .tracking(1.5)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                    
                    Button {
                        showPhotoLibrary = true
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                                .font(.system(size: 14, weight: .light))
                            Text("CHOOSE FROM LIBRARY")
                                .font(.system(.caption2, design: .default, weight: .medium))
                                .tracking(1.5)
                        }
                        .foregroundStyle(AppTheme.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(AppTheme.lightGray, lineWidth: 1)
                        )
                    }
                    
                    // Back to mode selection
                    Button {
                        captureMode = nil
                    } label: {
                        Text("Change Mode")
                            .font(.system(.caption))
                            .foregroundStyle(AppTheme.gray)
                            .underline()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Captured Images View
    
    private var capturedImagesView: some View {
        VStack(spacing: 16) {
            // Mode indicator
            HStack {
                Image(systemName: captureMode == .single ? "doc" : "doc.on.doc")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(AppTheme.gray)
                Text(captureMode == .single ? "SINGLE PAGE" : "MULTI-PAGE")
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(AppTheme.gray)
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
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
                }
                
                // Page navigation (multi-page only)
                if capturedImages.count > 1 {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentPageIndex = max(0, currentPageIndex - 1)
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(AppTheme.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .disabled(currentPageIndex == 0)
                        .opacity(currentPageIndex == 0 ? 0 : 1)
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentPageIndex = min(capturedImages.count - 1, currentPageIndex + 1)
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(AppTheme.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .disabled(currentPageIndex == capturedImages.count - 1)
                        .opacity(currentPageIndex == capturedImages.count - 1 ? 0 : 1)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            // Page indicator dots (multi-page only)
            if capturedImages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<capturedImages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPageIndex ? AppTheme.orange : AppTheme.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
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
                        .font(.system(.caption))
                        .foregroundStyle(AppTheme.gray)
                    
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
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .medium))
                                Text("ADD PAGE")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .tracking(1)
                            }
                            .foregroundStyle(AppTheme.orange)
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
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 14, weight: .light))
                        Text("PROCESS RECEIPT")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .tracking(1.5)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
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
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .light))
                        Text("REMOVE")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .tracking(1)
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                    )
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
                HStack(spacing: 6) {
                    Image(systemName: hasProcessed ? "pencil" : "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .light))
                    Text((hasProcessed ? "Edit Pages" : (captureMode == .single ? "Retake" : "Start Over")).uppercased())
                        .font(.system(.caption2, design: .default, weight: .medium))
                        .tracking(1)
                }
                .foregroundStyle(AppTheme.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(AppTheme.lightGray, lineWidth: 1)
                )
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
                .scaleEffect(1.2)
                .tint(AppTheme.orange)
            
            Text(processingStatus.uppercased())
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(1)
                .foregroundStyle(AppTheme.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Parsed Result View
    
    private func parsedResultView(_ data: ParsedReceiptData) -> some View {
        ScrollView {
            VStack(spacing: 1) {
                // Header
                HStack {
                    Text("PARSED RECEIPT")
                        .font(.system(.caption2, design: .default, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(AppTheme.gray)
                    
                    Spacer()
                    
                    if captureMode == .multi {
                        Button {
                            hasProcessed = false
                            parsedData = nil
                            rawText = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .medium))
                                Text("RE-SCAN")
                                    .font(.system(.caption2, design: .default, weight: .medium))
                                    .tracking(0.5)
                            }
                            .foregroundStyle(AppTheme.orange)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Store Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("STORE")
                        .font(.system(.caption2, design: .default, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(AppTheme.gray)
                    
                    VStack(spacing: 8) {
                        if let store = data.storeName {
                            HermesInfoRow(label: "Name", value: store)
                        }
                        if let address = data.storeAddress {
                            HermesInfoRow(label: "Address", value: address)
                        }
                        if let phone = data.storePhone {
                            HermesInfoRow(label: "Phone", value: phone)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.white)
                
                // Transaction Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("TRANSACTION")
                        .font(.system(.caption2, design: .default, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(AppTheme.gray)
                    
                    VStack(spacing: 8) {
                        if let dateStr = data.dateString {
                            HermesInfoRow(label: "Date", value: dateStr)
                        }
                        if let txNum = data.transactionNumber {
                            HermesInfoRow(label: "Receipt #", value: txNum)
                        }
                        if let category = data.suggestedCategory {
                            HermesInfoRow(label: "Category", value: category)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.white)
                
                // Financial Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("AMOUNT")
                        .font(.system(.caption2, design: .default, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(AppTheme.gray)
                    
                    VStack(spacing: 8) {
                        if let subtotal = data.subtotal {
                            HermesInfoRow(label: "Subtotal", value: String(format: "$%.2f", subtotal))
                        }
                        if let tax = data.tax {
                            HermesInfoRow(label: "Tax", value: String(format: "$%.2f", tax))
                        }
                        if let tips = data.tips {
                            HermesInfoRow(label: "Tips", value: String(format: "$%.2f", tips))
                        }
                        if let total = data.total {
                            PremiumDivider()
                                .padding(.vertical, 4)
                            HStack {
                                Text("Total")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(AppTheme.black)
                                Spacer()
                                Text(String(format: "$%.2f", total))
                                    .font(.system(.title3, design: .default, weight: .medium))
                                    .foregroundStyle(AppTheme.orange)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.white)
                
                // Payment Information
                if data.paymentMethod != nil || data.cardLastFourDigits != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PAYMENT")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(AppTheme.gray)
                        
                        VStack(spacing: 8) {
                            if let method = data.paymentMethod {
                                HermesInfoRow(label: "Method", value: method)
                            }
                            if let lastFour = data.cardLastFourDigits {
                                HermesInfoRow(label: "Card", value: "•••• \(lastFour)")
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.white)
                }
                
                // Items List
                if let items = data.items, !items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ITEMS (\(items.count))")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(AppTheme.gray)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.black)
                                        if let qty = item.quantity, qty > 1 {
                                            Text("Qty: \(qty)")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.gray)
                                        }
                                    }
                                    Spacer()
                                    if let price = item.price {
                                        Text(String(format: "$%.2f", price))
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                if index < items.count - 1 {
                                    PremiumDivider()
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
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

// MARK: - Mode Selection Card

struct ModeSelectionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.cream)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(AppTheme.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.caption, design: .default, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.black)
                    
                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(AppTheme.gray)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.orange)
            }
            .padding(16)
            .background(AppTheme.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(
                color: isPressed ? AppTheme.elevatedShadowColor : AppTheme.cardShadowColor,
                radius: isPressed ? AppTheme.elevatedShadowRadius : AppTheme.cardShadowRadius,
                y: isPressed ? AppTheme.elevatedShadowY : AppTheme.cardShadowY
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(AppTheme.quickAnimation) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    AddReceiptView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
