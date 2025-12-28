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
        
        if showUnfiledOnly {
            result = result.filter { $0.folder == nil }
        } else if let folder = selectedFolder {
            result = result.filter { $0.folder?.id == folder.id }
        }
        
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
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cream background
                AppTheme.cream
                    .ignoresSafeArea()
                
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
            }
            .navigationTitle(showUnfiledOnly ? "Unfiled" : (selectedFolder?.name ?? "Receipts"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search")
            .navigationDestination(item: $selectedReceipt) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFolderManagement = true
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(AppTheme.black)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddReceipt = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(AppTheme.orange)
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
        .tint(AppTheme.orange)
    }
    
    // MARK: - Folder Tabs
    
    private var folderTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // All tab
                HermesTab(
                    name: "All",
                    isSelected: selectedFolder == nil && !showUnfiledOnly
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFolder = nil
                        showUnfiledOnly = false
                    }
                }
                
                // Unfiled tab
                if !folders.isEmpty && !unfolderedReceipts.isEmpty {
                    HermesTab(
                        name: "Unfiled",
                        isSelected: showUnfiledOnly
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFolder = nil
                            showUnfiledOnly = true
                        }
                    }
                }
                
                // Folder tabs
                ForEach(folders) { folder in
                    HermesTab(
                        name: folder.name,
                        isSelected: selectedFolder?.id == folder.id && !showUnfiledOnly
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFolder = folder
                            showUnfiledOnly = false
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(AppTheme.white)
        .overlay(alignment: .bottom) {
            AppTheme.lightGray.frame(height: 1)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        PremiumEmptyState(
            icon: "doc.text",
            title: "No Receipts",
            message: "Capture your first receipt to begin organizing your expenses.",
            action: { showAddReceipt = true },
            actionLabel: "Add Receipt"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(AppTheme.gray)
            
            Text("No Results")
                .font(.system(.body, design: .serif))
                .foregroundStyle(AppTheme.black)
            
            Text(showUnfiledOnly ? "No unfiled receipts" : "Try a different search")
                .font(.caption)
                .foregroundStyle(AppTheme.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Receipts Grid
    
    private var receiptsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(filteredReceipts) { receipt in
                    HermesReceiptCard(receipt: receipt)
                        .onTapGesture {
                            selectedReceipt = receipt
                        }
                        .contextMenu {
                            Menu {
                                Button {
                                    receipt.folder = nil
                                } label: {
                                    Label("Remove from Folder", systemImage: "tray")
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
            .padding(20)
        }
    }
    
    private func deleteReceipt(_ receipt: Receipt) {
        Task {
            for filename in receipt.imageFileNames {
                try? await ImageStorageService.shared.deleteImage(filename: filename)
            }
        }
        modelContext.delete(receipt)
    }
}

// MARK: - Hermès Tab

struct HermesTab: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(name.uppercased())
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(isSelected ? AppTheme.orange : AppTheme.gray)
                
                Rectangle()
                    .fill(isSelected ? AppTheme.orange : Color.clear)
                    .frame(height: 2)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Hermès Receipt Card

struct HermesReceiptCard: View {
    let receipt: Receipt
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(AppTheme.offWhite)
                            .overlay {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 24, weight: .thin))
                                    .foregroundStyle(AppTheme.gray)
                            }
                    }
                }
                .frame(height: 160)
                .clipped()
                
                // Multi-page badge
                if receipt.isMultiPage {
                    Text("\(receipt.pageCount)")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.orange)
                        .padding(8)
                }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(receipt.displayName.uppercased())
                    .font(.system(.caption2, design: .default, weight: .medium))
                    .tracking(0.5)
                    .lineLimit(1)
                    .foregroundStyle(AppTheme.black)
                
                HStack {
                    Text(receipt.formattedDate)
                        .font(.system(.caption2))
                        .foregroundStyle(AppTheme.gray)
                    
                    Spacer()
                    
                    Text(receipt.formattedTotal)
                        .font(.system(.caption, design: .default, weight: .medium))
                        .foregroundStyle(AppTheme.orange)
                }
                
                // Folder indicator
                if let folder = receipt.folder {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(folder.color)
                            .frame(width: 6, height: 6)
                        Text(folder.name)
                            .font(.system(.caption2))
                            .foregroundStyle(AppTheme.gray)
                    }
                }
            }
            .padding(12)
            .background(AppTheme.white)
        }
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
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
        } catch {}
    }
}

#Preview {
    ReceiptsListView()
        .modelContainer(for: [Receipt.self, Folder.self], inMemory: true)
}
