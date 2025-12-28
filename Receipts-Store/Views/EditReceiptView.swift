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
    
    // Store Info
    @State private var storeName: String
    @State private var storeAddress: String
    @State private var storePhone: String
    
    // Transaction
    @State private var transactionDate: Date
    @State private var hasDate: Bool
    @State private var transactionNumber: String
    
    // Financial
    @State private var subtotalString: String
    @State private var taxString: String
    @State private var tipsString: String
    @State private var totalString: String
    
    // Payment
    @State private var paymentMethod: PaymentMethod
    @State private var cardLastFour: String
    
    // Organization
    @State private var category: ReceiptCategory
    @State private var notes: String
    @State private var selectedFolder: Folder?
    @State private var showFolderPicker = false
    
    init(receipt: Receipt) {
        self.receipt = receipt
        
        // Store Info
        _storeName = State(initialValue: receipt.storeName ?? "")
        _storeAddress = State(initialValue: receipt.storeAddress ?? "")
        _storePhone = State(initialValue: receipt.storePhone ?? "")
        
        // Transaction
        _transactionDate = State(initialValue: receipt.transactionDate ?? Date())
        _hasDate = State(initialValue: receipt.transactionDate != nil)
        _transactionNumber = State(initialValue: receipt.transactionNumber ?? "")
        
        // Financial
        _subtotalString = State(initialValue: receipt.subtotal.map { String(describing: $0) } ?? "")
        _taxString = State(initialValue: receipt.tax.map { String(describing: $0) } ?? "")
        _tipsString = State(initialValue: receipt.tips.map { String(describing: $0) } ?? "")
        _totalString = State(initialValue: receipt.total.map { String(describing: $0) } ?? "")
        
        // Payment
        _paymentMethod = State(initialValue: receipt.paymentMethod)
        _cardLastFour = State(initialValue: receipt.cardLastFourDigits ?? "")
        
        // Organization
        _category = State(initialValue: receipt.category)
        _notes = State(initialValue: receipt.notes ?? "")
        _selectedFolder = State(initialValue: receipt.folder)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Store Information
                Section("Store Information") {
                    TextField("Store Name", text: $storeName)
                    TextField("Address", text: $storeAddress)
                    TextField("Phone", text: $storePhone)
                        .keyboardType(.phonePad)
                }
                
                // Transaction Details
                Section("Transaction Details") {
                    Toggle("Has Date", isOn: $hasDate)
                    
                    if hasDate {
                        DatePicker("Date", selection: $transactionDate, displayedComponents: .date)
                    }
                    
                    TextField("Receipt/Transaction #", text: $transactionNumber)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ReceiptCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }
                
                // Financial Breakdown
                Section("Financial Details") {
                    CurrencyField(label: "Subtotal", value: $subtotalString)
                    CurrencyField(label: "Tax", value: $taxString)
                    CurrencyField(label: "Tips", value: $tipsString)
                    CurrencyField(label: "Total", value: $totalString)
                }
                
                // Payment Information
                Section("Payment") {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Label(method.rawValue, systemImage: method.icon)
                                .tag(method)
                        }
                    }
                    
                    if paymentMethod == .creditCard || paymentMethod == .debitCard {
                        TextField("Last 4 Digits", text: $cardLastFour)
                            .keyboardType(.numberPad)
                    }
                }
                
                // Notes
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                // Folder
                Section("Folder") {
                    Button {
                        showFolderPicker = true
                    } label: {
                        HStack {
                            if let folder = selectedFolder {
                                Image(systemName: folder.iconName)
                                    .foregroundStyle(folder.color)
                                Text(folder.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                Text("No Folder")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                // Items (read-only display)
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
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView(selectedFolder: $selectedFolder)
            }
        }
    }
    
    private func saveChanges() {
        // Store Info
        receipt.storeName = storeName.isEmpty ? nil : storeName
        receipt.storeAddress = storeAddress.isEmpty ? nil : storeAddress
        receipt.storePhone = storePhone.isEmpty ? nil : storePhone
        
        // Transaction
        receipt.transactionDate = hasDate ? transactionDate : nil
        receipt.transactionNumber = transactionNumber.isEmpty ? nil : transactionNumber
        
        // Financial
        receipt.subtotal = Decimal(string: subtotalString)
        receipt.tax = Decimal(string: taxString)
        receipt.tips = Decimal(string: tipsString)
        receipt.total = Decimal(string: totalString)
        
        // Payment
        receipt.paymentMethod = paymentMethod
        receipt.cardLastFourDigits = cardLastFour.isEmpty ? nil : cardLastFour
        
        // Organization
        receipt.category = category
        receipt.notes = notes.isEmpty ? nil : notes
        receipt.folder = selectedFolder
        
        dismiss()
    }
}

// MARK: - Currency Field Helper

struct CurrencyField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack {
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $value)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        }
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
