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
        List {
            ForEach(folders) { folder in
                FolderRow(folder: folder)
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
                        .tint(.orange)
                    }
            }
            .onMove(perform: moveFolder)
        }
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateFolder = true
                } label: {
                    Image(systemName: "plus")
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
                ContentUnavailableView {
                    Label("No Folders", systemImage: "folder")
                } description: {
                    Text("Create folders to organize your receipts")
                } actions: {
                    Button("Create Folder") {
                        showCreateFolder = true
                    }
                }
            }
        }
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
        HStack(spacing: 12) {
            Image(systemName: folder.iconName)
                .font(.title2)
                .foregroundStyle(folder.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name)
                    .font(.body)
                
                Text("\(folder.receiptCount) receipt\(folder.receiptCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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
        Form {
            Section {
                // Preview
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: selectedColorHex) ?? Color.accentColor)
                        
                        Text(name.isEmpty ? "Folder Name" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                    }
                    .padding()
                    Spacer()
                }
            }
            
            Section("Name") {
                TextField("Folder name", text: $name)
            }
            
            Section("Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(Folder.presetColors, id: \.hex) { preset in
                        Circle()
                            .fill(Color(hex: preset.hex) ?? .gray)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if selectedColorHex == preset.hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture {
                                selectedColorHex = preset.hex
                            }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(Folder.presetIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .frame(width: 36, height: 36)
                            .foregroundStyle(selectedIcon == icon ? .white : .primary)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? Color.accentColor) : Color.clear)
                            }
                            .onTapGesture {
                                selectedIcon = icon
                            }
                    }
                }
                .padding(.vertical, 8)
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
            List {
                // No folder option
                Button {
                    selectedFolder = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 32)
                        
                        Text("No Folder")
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if selectedFolder == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                
                // Folders
                ForEach(folders) { folder in
                    Button {
                        selectedFolder = folder
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: folder.iconName)
                                .font(.title2)
                                .foregroundStyle(folder.color)
                                .frame(width: 32)
                            
                            Text(folder.name)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if selectedFolder?.id == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FolderListView()
    }
    .modelContainer(for: [Folder.self, Receipt.self], inMemory: true)
}
