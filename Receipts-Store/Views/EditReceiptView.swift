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
            ZStack {
                AppTheme.cream.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Store Information
                        storeSection
                        
                        // Transaction Details
                        transactionSection
                        
                        // Financial Details
                        financialSection
                        
                        // Payment
                        paymentSection
                        
                        // Organization
                        organizationSection
                        
                        // Notes
                        notesSection
                        
                        // Items (read-only)
                        if !receipt.items.isEmpty {
                            itemsSection
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gray)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.orange)
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView(selectedFolder: $selectedFolder)
            }
        }
        .tint(AppTheme.orange)
    }
    
    // MARK: - Store Section
    
    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STORE")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
            
            VStack(spacing: 0) {
                HermesRowTextField(label: "Name", text: $storeName)
                PremiumDivider()
                HermesRowTextField(label: "Address", text: $storeAddress)
                PremiumDivider()
                HermesRowTextField(label: "Phone", text: $storePhone, keyboardType: .phonePad)
            }
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Transaction Section
    
    private var transactionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TRANSACTION")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
            
            VStack(spacing: 0) {
                // Has Date Toggle
                HStack {
                    Text("Has Date")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.gray)
                    Spacer()
                    Toggle("", isOn: $hasDate)
                        .labelsHidden()
                        .tint(AppTheme.orange)
                }
                .padding(.vertical, 12)
                
                if hasDate {
                    PremiumDivider()
                    HStack {
                        Text("Date")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.gray)
                        Spacer()
                        DatePicker("", selection: $transactionDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.vertical, 8)
                }
                
                PremiumDivider()
                HermesRowTextField(label: "Receipt #", text: $transactionNumber)
                
                PremiumDivider()
                
                // Category Picker
                HStack {
                    Text("Category")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.gray)
                    Spacer()
                    Picker("", selection: $category) {
                        ForEach(ReceiptCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .labelsHidden()
                    .tint(AppTheme.black)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Financial Section
    
    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AMOUNT")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
            
            VStack(spacing: 0) {
                HermesRowCurrencyField(label: "Subtotal", value: $subtotalString)
                PremiumDivider()
                HermesRowCurrencyField(label: "Tax", value: $taxString)
                PremiumDivider()
                HermesRowCurrencyField(label: "Tips", value: $tipsString)
                PremiumDivider()
                
                // Total with emphasis
                HStack {
                    Text("Total")
                        .font(.system(.subheadline, design: .serif, weight: .regular))
                        .foregroundStyle(AppTheme.black)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.orange)
                        TextField("0.00", text: $totalString)
                            .font(.system(.title3, design: .default, weight: .medium))
                            .foregroundStyle(AppTheme.orange)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Payment Section
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PAYMENT")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
            
            VStack(spacing: 0) {
                // Payment Method
                HStack {
                    Text("Method")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.gray)
                    Spacer()
                    Picker("", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Label(method.rawValue, systemImage: method.icon)
                                .tag(method)
                        }
                    }
                    .labelsHidden()
                    .tint(AppTheme.black)
                }
                .padding(.vertical, 8)
                
                if paymentMethod == .creditCard || paymentMethod == .debitCard {
                    PremiumDivider()
                    HermesRowTextField(label: "Last 4 Digits", text: $cardLastFour, keyboardType: .numberPad)
                }
            }
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Organization Section
    
    private var organizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ORGANIZATION")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
            
            Button {
                showFolderPicker = true
            } label: {
                HStack {
                    Text("Folder")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.gray)
                    
                    Spacer()
                    
                    if let folder = selectedFolder {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 8, height: 8)
                            Text(folder.name)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.black)
                        }
                    } else {
                        Text("None")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.gray)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.gray)
                }
            }
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NOTES")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
            
            TextEditor(text: $notes)
                .font(.subheadline)
                .foregroundStyle(AppTheme.black)
                .frame(minHeight: 80)
                .padding(12)
                .background(AppTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Items Section
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ITEMS (\(receipt.items.count))")
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(2)
                .foregroundStyle(AppTheme.gray)
            
            VStack(spacing: 0) {
                ForEach(receipt.items) { item in
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
                        Text(item.formattedPrice)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.gray)
                    }
                    .padding(.vertical, 8)
                    
                    if item.id != receipt.items.last?.id {
                        PremiumDivider()
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    // MARK: - Save
    
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

// MARK: - Hermès Row Text Field

struct HermesRowTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gray)
            Spacer()
            TextField("", text: $text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.black)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboardType)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Hermès Row Currency Field

struct HermesRowCurrencyField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gray)
            Spacer()
            HStack(spacing: 4) {
                Text("$")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.gray)
                TextField("0.00", text: $value)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.black)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 12)
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
