//
//  FolderManagementView.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-28.
//

import SwiftUI
import SwiftData

// MARK: - Folder List View

struct FolderListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    
    @State private var showCreateFolder = false
    @State private var folderToEdit: Folder?
    @State private var showDeleteConfirmation = false
    @State private var folderToDelete: Folder?
    
    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()
            
            List {
                ForEach(folders) { folder in
                    FolderRow(folder: folder)
                        .listRowBackground(AppTheme.white)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            folderToEdit = folder
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                folderToDelete = folder
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                folderToEdit = folder
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(AppTheme.orange)
                        }
                }
                .onMove(perform: moveFolder)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateFolder = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(AppTheme.orange)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showCreateFolder) {
            CreateFolderView()
        }
        .sheet(item: $folderToEdit) { folder in
            EditFolderView(folder: folder)
        }
        .confirmationDialog(
            "Delete Folder",
            isPresented: $showDeleteConfirmation,
            presenting: folderToDelete
        ) { folder in
            Button("Delete Folder Only", role: .destructive) {
                deleteFolder(folder, deleteReceipts: false)
            }
            Button("Delete Folder and Receipts", role: .destructive) {
                deleteFolder(folder, deleteReceipts: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: { folder in
            Text("What would you like to do with the \(folder.receiptCount) receipt(s) in '\(folder.name)'?")
        }
        .overlay {
            if folders.isEmpty {
                PremiumEmptyState(
                    icon: "folder",
                    title: "No Folders",
                    message: "Create folders to organize your receipts.",
                    action: { showCreateFolder = true },
                    actionLabel: "Create Folder"
                )
            }
        }
        .tint(AppTheme.orange)
    }
    
    private func moveFolder(from source: IndexSet, to destination: Int) {
        var updatedFolders = folders
        updatedFolders.move(fromOffsets: source, toOffset: destination)
        
        for (index, folder) in updatedFolders.enumerated() {
            folder.sortOrder = index
        }
    }
    
    private func deleteFolder(_ folder: Folder, deleteReceipts: Bool) {
        if deleteReceipts {
            // Delete all receipts in the folder
            for receipt in folder.receipts {
                // Delete images
                Task {
                    for filename in receipt.imageFileNames {
                        try? await ImageStorageService.shared.deleteImage(filename: filename)
                    }
                }
                modelContext.delete(receipt)
            }
        } else {
            // Just remove folder reference from receipts
            for receipt in folder.receipts {
                receipt.folder = nil
            }
        }
        
        modelContext.delete(folder)
    }
}

// MARK: - Folder Row

struct FolderRow: View {
    let folder: Folder
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(folder.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: folder.iconName)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(folder.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(AppTheme.black)
                
                Text("\(folder.receiptCount) receipt\(folder.receiptCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(AppTheme.gray)
            }
            
            Spacer()
            
            // Count badge
            if folder.receiptCount > 0 {
                Text("\(folder.receiptCount)")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.cream)
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.gray.opacity(0.5))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Create Folder View

struct CreateFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedColorHex = Folder.presetColors[0].hex
    @State private var selectedIcon = Folder.presetIcons[0]
    
    var body: some View {
        NavigationStack {
            FolderFormView(
                name: $name,
                selectedColorHex: $selectedColorHex,
                selectedIcon: $selectedIcon
            )
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createFolder()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func createFolder() {
        let folder = Folder(
            name: name.trimmingCharacters(in: .whitespaces),
            colorHex: selectedColorHex,
            iconName: selectedIcon
        )
        modelContext.insert(folder)
        dismiss()
    }
}

// MARK: - Edit Folder View

struct EditFolderView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var folder: Folder
    
    @State private var name: String
    @State private var selectedColorHex: String
    @State private var selectedIcon: String
    
    init(folder: Folder) {
        self.folder = folder
        _name = State(initialValue: folder.name)
        _selectedColorHex = State(initialValue: folder.colorHex)
        _selectedIcon = State(initialValue: folder.iconName)
    }
    
    var body: some View {
        NavigationStack {
            FolderFormView(
                name: $name,
                selectedColorHex: $selectedColorHex,
                selectedIcon: $selectedIcon
            )
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        folder.name = name.trimmingCharacters(in: .whitespaces)
        folder.colorHex = selectedColorHex
        folder.iconName = selectedIcon
        dismiss()
    }
}

// MARK: - Folder Form View

struct FolderFormView: View {
    @Binding var name: String
    @Binding var selectedColorHex: String
    @Binding var selectedIcon: String
    
    var body: some View {
        ZStack {
            AppTheme.cream.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    VStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(Color(hex: selectedColorHex) ?? AppTheme.orange)
                        
                        Text(name.isEmpty ? "Folder Name" : name)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(name.isEmpty ? AppTheme.gray : AppTheme.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(AppTheme.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    // Name
                    VStack(alignment: .leading, spacing: 16) {
                        Text("NAME")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(AppTheme.gray)
                        
                        TextField("Folder name", text: $name)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.black)
                            .padding(.vertical, 12)
                    }
                    .padding(20)
                    .background(AppTheme.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    // Color
                    VStack(alignment: .leading, spacing: 16) {
                        Text("COLOR")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(AppTheme.gray)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            ForEach(Folder.presetColors, id: \.hex) { preset in
                                Circle()
                                    .fill(Color(hex: preset.hex) ?? .gray)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if selectedColorHex == preset.hex {
                                            Circle()
                                                .strokeBorder(AppTheme.white, lineWidth: 3)
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .shadow(color: selectedColorHex == preset.hex ? (Color(hex: preset.hex) ?? .gray).opacity(0.4) : .clear, radius: 4, y: 2)
                                    .onTapGesture {
                                        selectedColorHex = preset.hex
                                    }
                            }
                        }
                    }
                    .padding(20)
                    .background(AppTheme.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    // Icon
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ICON")
                            .font(.system(.caption2, design: .default, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(AppTheme.gray)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            ForEach(Folder.presetIcons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(selectedIcon == icon ? .white : AppTheme.black)
                                    .background {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? AppTheme.orange) : AppTheme.cream)
                                    }
                                    .onTapGesture {
                                        selectedIcon = icon
                                    }
                            }
                        }
                    }
                    .padding(20)
                    .background(AppTheme.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .padding(20)
            }
        }
    }
}

// MARK: - Folder Picker View

struct FolderPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    
    @Binding var selectedFolder: Folder?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // No folder option
                        Button {
                            selectedFolder = nil
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(AppTheme.gray)
                                    .frame(width: 32)
                                
                                Text("No Folder")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.black)
                                
                                Spacer()
                                
                                if selectedFolder == nil {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(AppTheme.orange)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                        }
                        
                        PremiumDivider()
                            .padding(.leading, 64)
                        
                        // Folders
                        ForEach(folders) { folder in
                            Button {
                                selectedFolder = folder
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: folder.iconName)
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundStyle(folder.color)
                                        .frame(width: 32)
                                    
                                    Text(folder.name)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.black)
                                    
                                    Spacer()
                                    
                                    if selectedFolder?.id == folder.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(AppTheme.orange)
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                            }
                            
                            if folder.id != folders.last?.id {
                                PremiumDivider()
                                    .padding(.leading, 64)
                            }
                        }
                    }
                    .background(AppTheme.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(20)
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gray)
                }
            }
        }
        .tint(AppTheme.orange)
    }
}

#Preview {
    NavigationStack {
        FolderListView()
    }
    .modelContainer(for: [Folder.self, Receipt.self], inMemory: true)
}
