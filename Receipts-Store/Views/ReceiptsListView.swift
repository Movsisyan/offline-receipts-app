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
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    
    @State private var searchText = ""
    @State private var selectedReceipt: Receipt?
    @State private var showAddReceipt = false
    @State private var selectedFolder: Folder?
    @State private var showUnfiledOnly = false
    @State private var showFolderManagement = false
    
    private var filteredReceipts: [Receipt] {
        var result = receipts
        
        // Filter by folder or unfiled
        if showUnfiledOnly {
            result = result.filter { $0.folder == nil }
        } else if let folder = selectedFolder {
            result = result.filter { $0.folder?.id == folder.id }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { receipt in
                receipt.displayName.localizedCaseInsensitiveContains(searchText) ||
                (receipt.rawText?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return result
    }
    
    private var unfolderedReceipts: [Receipt] {
        receipts.filter { $0.folder == nil }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Folder tabs
                folderTabsView
                
                // Content
                Group {
                    if selectedFolder == nil && !showUnfiledOnly && receipts.isEmpty {
                        emptyStateView
                    } else if filteredReceipts.isEmpty {
                        noResultsView
                    } else {
                        receiptsGrid
                    }
                }
            }
            .navigationTitle(showUnfiledOnly ? "Unfiled" : (selectedFolder?.name ?? "All Receipts"))
            .searchable(text: $searchText, prompt: "Search receipts")
            .navigationDestination(item: $selectedReceipt) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFolderManagement = true
                    } label: {
                        Image(systemName: "folder.badge.gearshape")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddReceipt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddReceipt) {
                AddReceiptView(initialFolder: selectedFolder)
            }
            .sheet(isPresented: $showFolderManagement) {
                NavigationStack {
                    FolderListView()
                }
            }
        }
    }
    
    // MARK: - Folder Tabs
    
    private var folderTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Receipts tab
                FolderTab(
                    name: "All",
                    icon: "tray.full",
                    color: .accentColor,
                    count: receipts.count,
                    isSelected: selectedFolder == nil && !showUnfiledOnly
                ) {
                    withAnimation {
                        selectedFolder = nil
                        showUnfiledOnly = false
                    }
                }
                
                // Unfoldered tab (only if there are unfoldered receipts and folders exist)
                if !folders.isEmpty && !unfolderedReceipts.isEmpty {
                    FolderTab(
                        name: "Unfiled",
                        icon: "tray",
                        color: .gray,
                        count: unfolderedReceipts.count,
                        isSelected: showUnfiledOnly
                    ) {
                        withAnimation {
                            selectedFolder = nil
                            showUnfiledOnly = true
                        }
                    }
                }
                
                // Folder tabs
                ForEach(folders) { folder in
                    FolderTab(
                        name: folder.name,
                        icon: folder.iconName,
                        color: folder.color,
                        count: folder.receiptCount,
                        isSelected: selectedFolder?.id == folder.id && !showUnfiledOnly
                    ) {
                        withAnimation {
                            selectedFolder = folder
                            showUnfiledOnly = false
                        }
                    }
                }
                
                // Add folder button
                Button {
                    showFolderManagement = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Receipts", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Tap the + button to scan your first receipt")
        }
    }
    
    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
        } description: {
            if let folder = selectedFolder {
                Text("No receipts found in '\(folder.name)'")
            } else {
                Text("No receipts match your search")
            }
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
                            // Move to folder
                            Menu {
                                Button {
                                    receipt.folder = nil
                                } label: {
                                    Label("No Folder", systemImage: "tray")
                                }
                                
                                ForEach(folders) { folder in
                                    Button {
                                        receipt.folder = folder
                                    } label: {
                                        Label(folder.name, systemImage: folder.iconName)
                                    }
                                }
                            } label: {
                                Label("Move to Folder", systemImage: "folder")
                            }
                            
                            Divider()
                            
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
            // Delete all image files for multi-page receipts
            for filename in receipt.imageFileNames {
                try? await ImageStorageService.shared.deleteImage(filename: filename)
            }
        }
        modelContext.delete(receipt)
    }
}

// MARK: - Folder Tab

struct FolderTab: View {
    let name: String
    let icon: String
    let color: Color
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.2))
                    .clipShape(Capsule())
            }
            .foregroundStyle(isSelected ? color : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.15) : Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Receipt Card

struct ReceiptCard: View {
    let receipt: Receipt
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail with page count badge
            ZStack(alignment: .topTrailing) {
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
                
                // Multi-page badge
                if receipt.isMultiPage {
                    Text("\(receipt.pageCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                        .padding(6)
                }
                
                // Folder indicator
                if let folder = receipt.folder {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: folder.iconName)
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(folder.color)
                                .clipShape(Circle())
                                .padding(6)
                            Spacer()
                        }
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
                for: receipt.primaryImageFileName,
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
        .modelContainer(for: [Receipt.self, Folder.self], inMemory: true)
}
