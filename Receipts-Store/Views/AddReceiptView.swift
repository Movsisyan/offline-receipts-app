//
//  AddReceiptView.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import SwiftUI
import SwiftData

struct AddReceiptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var processingStatus = "Preparing..."
    @State private var parsedData: ParsedReceiptData?
    @State private var rawText: String?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let image = capturedImage {
                    // Show captured image and processing state
                    capturedImageView(image)
                } else {
                    // Show capture options
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
                
                if parsedData != nil {
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
                    capturedImage = image
                    Task {
                        await processImage(image)
                    }
                }
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker { image in
                    capturedImage = image
                    Task {
                        await processImage(image)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Capture Options
    
    private var captureOptionsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            Text("Capture or select a receipt image")
                .font(.title3)
                .foregroundStyle(.secondary)
            
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
            }
        }
    }
    
    // MARK: - Captured Image View
    
    private func capturedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if isProcessing {
                processingView
            } else if let parsed = parsedData {
                parsedResultView(parsed)
            }
            
            Spacer()
            
            // Retake button
            if !isProcessing {
                Button {
                    capturedImage = nil
                    parsedData = nil
                    rawText = nil
                } label: {
                    Label("Retake Photo", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
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
        VStack(spacing: 12) {
            Text("Parsed Receipt")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let store = data.storeName {
                    HStack {
                        Text("Store")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(store)
                            .fontWeight(.medium)
                    }
                }
                
                if let dateStr = data.dateString {
                    HStack {
                        Text("Date")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(dateStr)
                            .fontWeight(.medium)
                    }
                }
                
                if let total = data.total {
                    HStack {
                        Text("Total")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", total))
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
                
                if let items = data.items, !items.isEmpty {
                    Divider()
                    Text("\(items.count) item(s) found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Image Processing
    
    private func processImage(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Step 1: OCR
            processingStatus = "Extracting text..."
            let extractedText = try await TextRecognitionService.shared.recognizeText(in: image)
            rawText = extractedText
            
            guard !extractedText.isEmpty else {
                errorMessage = "Could not extract any text from the image. Try a clearer photo."
                showError = true
                return
            }
            
            // Step 2: LLM Parsing
            processingStatus = "Analyzing receipt..."
            
            let parsingService = ReceiptParsingService.shared
            
            if await parsingService.isModelAvailable {
                parsedData = try await parsingService.parseReceipt(from: extractedText)
            } else {
                // Fallback to regex parser
                processingStatus = "Using basic parsing..."
                parsedData = await parsingService.parseReceiptWithFallback(from: extractedText)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Save Receipt
    
    private func saveReceipt() {
        guard let image = capturedImage else { return }
        
        Task {
            do {
                // Save image
                let filename = try await ImageStorageService.shared.saveImage(image)
                
                // Create receipt
                let receipt = Receipt(
                    imageFileName: filename,
                    rawText: rawText,
                    storeName: parsedData?.storeName,
                    transactionDate: parsedData?.parsedDate,
                    total: parsedData?.totalAsDecimal,
                    items: parsedData?.createReceiptItems() ?? []
                )
                
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

#Preview {
    AddReceiptView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
