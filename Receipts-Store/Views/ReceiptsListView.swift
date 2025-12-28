//
//  ReceiptsListView.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import SwiftUI
import SwiftData

struct ReceiptsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.createdAt, order: .reverse) private var receipts: [Receipt]
    
    @State private var searchText = ""
    @State private var selectedReceipt: Receipt?
    @State private var showAddReceipt = false
    
    private var filteredReceipts: [Receipt] {
        guard !searchText.isEmpty else { return receipts }
        return receipts.filter { receipt in
            receipt.displayName.localizedCaseInsensitiveContains(searchText) ||
            (receipt.rawText?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if receipts.isEmpty {
                    emptyStateView
                } else {
                    receiptsGrid
                }
            }
            .navigationTitle("Receipts")
            .searchable(text: $searchText, prompt: "Search receipts")
            .navigationDestination(item: $selectedReceipt) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddReceipt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddReceipt) {
                AddReceiptView()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Receipts", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Tap the + button to scan your first receipt")
        }
    }
    
    // MARK: - Receipts Grid
    
    private var receiptsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredReceipts) { receipt in
                    ReceiptCard(receipt: receipt)
                        .onTapGesture {
                            selectedReceipt = receipt
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteReceipt(receipt)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func deleteReceipt(_ receipt: Receipt) {
        Task {
            // Delete the image file
            try? await ImageStorageService.shared.deleteImage(filename: receipt.imageFileName)
        }
        modelContext.delete(receipt)
    }
}

// MARK: - Receipt Card

struct ReceiptCard: View {
    let receipt: Receipt
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 140)
                        .overlay {
                            Image(systemName: "doc.text")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(receipt.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(receipt.formattedTotal)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        do {
            let image = try await ImageStorageService.shared.createThumbnail(
                for: receipt.imageFileName,
                size: CGSize(width: 200, height: 200)
            )
            await MainActor.run {
                self.thumbnailImage = image
            }
        } catch {
            // Silently fail - placeholder will show
        }
    }
}

#Preview {
    ReceiptsListView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
