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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.offWhite)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(AppTheme.gray)
            }
            
            VStack(spacing: 8) {
                Text("No Results")
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(AppTheme.black)
                
                Text(showUnfiledOnly ? "No unfiled receipts to display" : "Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Receipts Grid
    
    private var receiptsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(filteredReceipts.enumerated()), id: \.element.id) { index, receipt in
                    HermesReceiptCard(receipt: receipt)
                        .onTapGesture {
                            withAnimation(AppTheme.springAnimation) {
                                selectedReceipt = receipt
                            }
                        }
                        .contextMenu {
                            Menu {
                                Button {
                                    withAnimation {
                                        receipt.folder = nil
                                    }
                                } label: {
                                    Label("Remove from Folder", systemImage: "tray")
                                }
                                
                                ForEach(folders) { folder in
                                    Button {
                                        withAnimation {
                                            receipt.folder = folder
                                        }
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
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
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
            VStack(spacing: 10) {
                Text(name.uppercased())
                    .font(.system(.caption2, design: .default, weight: isSelected ? .semibold : .medium))
                    .tracking(1.5)
                    .foregroundStyle(isSelected ? AppTheme.orange : AppTheme.gray)
                
                // Animated underline
                Capsule()
                    .fill(AppTheme.orange)
                    .frame(height: 2)
                    .scaleX(isSelected ? 1 : 0)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(AppTheme.springAnimation, value: isSelected)
    }
}

// Scale X modifier
extension View {
    func scaleX(_ scale: CGFloat) -> some View {
        self.scaleEffect(x: scale, y: 1, anchor: .center)
    }
}

// MARK: - Hermès Receipt Card

struct HermesReceiptCard: View {
    let receipt: Receipt
    
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    } else {
                        Rectangle()
                            .fill(AppTheme.offWhite)
                            .overlay {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(AppTheme.gray.opacity(0.5))
                                } else {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 24, weight: .ultraLight))
                                        .foregroundStyle(AppTheme.gray.opacity(0.5))
                                }
                            }
                    }
                }
                .frame(height: 150)
                .clipped()
                
                // Multi-page badge
                if receipt.isMultiPage {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 8, weight: .semibold))
                        Text("\(receipt.pageCount)")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(AppTheme.orange)
                            .shadow(color: AppTheme.orange.opacity(0.3), radius: 4, y: 2)
                    )
                    .padding(10)
                }
            }
            
            // Details - fixed height for consistency
            VStack(alignment: .leading, spacing: 6) {
                Text(receipt.displayName.uppercased())
                    .font(.system(.caption2, design: .default, weight: .semibold))
                    .tracking(0.8)
                    .lineLimit(1)
                    .foregroundStyle(AppTheme.black)
                
                HStack(alignment: .bottom) {
                    Text(receipt.formattedDate)
                        .font(.system(.caption2))
                        .foregroundStyle(AppTheme.gray)
                    
                    Spacer()
                    
                    Text(receipt.formattedTotal)
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundStyle(AppTheme.orange)
                }
                
                // Folder indicator - always visible for consistent height
                HStack(spacing: 5) {
                    if let folder = receipt.folder {
                        Circle()
                            .fill(folder.color)
                            .frame(width: 5, height: 5)
                        Text(folder.name)
                            .font(.system(.caption2))
                            .foregroundStyle(AppTheme.gray)
                    } else {
                        // Invisible placeholder to maintain height
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 5, height: 5)
                        Text(" ")
                            .font(.system(.caption2))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.white)
        }
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(
            color: isPressed ? AppTheme.elevatedShadowColor : AppTheme.cardShadowColor,
            radius: isPressed ? AppTheme.elevatedShadowRadius : AppTheme.cardShadowRadius,
            y: isPressed ? AppTheme.elevatedShadowY : AppTheme.cardShadowY
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.quickAnimation, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
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
                withAnimation(.easeOut(duration: 0.3)) {
                    self.thumbnailImage = image
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    ReceiptsListView()
        .modelContainer(for: [Receipt.self, Folder.self], inMemory: true)
}
