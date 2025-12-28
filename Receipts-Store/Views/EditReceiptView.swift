//
//  EditReceiptView.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import SwiftUI
import SwiftData

struct EditReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var receipt: Receipt
    
    @State private var storeName: String
    @State private var transactionDate: Date
    @State private var totalString: String
    @State private var notes: String
    @State private var hasDate: Bool
    
    init(receipt: Receipt) {
        self.receipt = receipt
        _storeName = State(initialValue: receipt.storeName ?? "")
        _transactionDate = State(initialValue: receipt.transactionDate ?? Date())
        _hasDate = State(initialValue: receipt.transactionDate != nil)
        _notes = State(initialValue: receipt.notes ?? "")
        
        if let total = receipt.total {
            _totalString = State(initialValue: String(describing: total))
        } else {
            _totalString = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Store Information") {
                    TextField("Store Name", text: $storeName)
                }
                
                Section("Transaction Details") {
                    Toggle("Has Date", isOn: $hasDate)
                    
                    if hasDate {
                        DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                    }
                    
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Total", text: $totalString)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                if !receipt.items.isEmpty {
                    Section("Items (\(receipt.items.count))") {
                        ForEach(receipt.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    if let qty = item.quantity, qty > 1 {
                                        Text("Qty: \(qty)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(item.formattedPrice)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Receipt")
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
                }
            }
        }
    }
    
    private func saveChanges() {
        receipt.storeName = storeName.isEmpty ? nil : storeName
        receipt.transactionDate = hasDate ? transactionDate : nil
        receipt.notes = notes.isEmpty ? nil : notes
        
        if let totalDecimal = Decimal(string: totalString) {
            receipt.total = totalDecimal
        } else {
            receipt.total = nil
        }
        
        dismiss()
    }
}

#Preview {
    EditReceiptView(receipt: Receipt(
        imageFileName: "test.jpg",
        storeName: "Sample Store",
        transactionDate: Date(),
        total: 42.99
    ))
    .modelContainer(for: Receipt.self, inMemory: true)
}
