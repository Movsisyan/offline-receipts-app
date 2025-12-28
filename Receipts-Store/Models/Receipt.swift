//
//  Receipt.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import Foundation
import SwiftData

/// Category for organizing receipts
enum ReceiptCategory: String, Codable, CaseIterable {
    case uncategorized = "Uncategorized"
    case groceries = "Groceries"
    case restaurant = "Restaurant"
    case gas = "Gas & Fuel"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case travel = "Travel"
    case healthcare = "Healthcare"
    case utilities = "Utilities"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .uncategorized: return "doc.text"
        case .groceries: return "cart"
        case .restaurant: return "fork.knife"
        case .gas: return "fuelpump"
        case .shopping: return "bag"
        case .entertainment: return "tv"
        case .travel: return "airplane"
        case .healthcare: return "cross.case"
        case .utilities: return "bolt"
        case .other: return "ellipsis.circle"
        }
    }
}

/// Payment method used for the transaction
enum PaymentMethod: String, Codable, CaseIterable {
    case unknown = "Unknown"
    case cash = "Cash"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case applePay = "Apple Pay"
    case giftCard = "Gift Card"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .cash: return "dollarsign"
        case .creditCard: return "creditcard"
        case .debitCard: return "creditcard.fill"
        case .applePay: return "apple.logo"
        case .giftCard: return "giftcard"
        case .other: return "ellipsis.circle"
        }
    }
}

@Model
final class Receipt {
    var id: UUID
    var imageFileName: String
    var rawText: String?
    
    // Store information
    var storeName: String?
    var storeAddress: String?
    var storePhone: String?
    
    // Transaction details
    var transactionDate: Date?
    var transactionNumber: String?
    
    // Financial breakdown
    var subtotal: Decimal?
    var tax: Decimal?
    var tips: Decimal?
    var total: Decimal?
    var currency: String?
    
    // Payment information
    var paymentMethodRaw: String?
    var cardLastFourDigits: String?
    
    // Organization
    var categoryRaw: String?
    var notes: String?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var items: [ReceiptItem]
    
    // MARK: - Computed Properties for Enums
    
    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw ?? "") ?? .unknown }
        set { paymentMethodRaw = newValue.rawValue }
    }
    
    var category: ReceiptCategory {
        get { ReceiptCategory(rawValue: categoryRaw ?? "") ?? .uncategorized }
        set { categoryRaw = newValue.rawValue }
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        imageFileName: String,
        rawText: String? = nil,
        storeName: String? = nil,
        storeAddress: String? = nil,
        storePhone: String? = nil,
        transactionDate: Date? = nil,
        transactionNumber: String? = nil,
        subtotal: Decimal? = nil,
        tax: Decimal? = nil,
        tips: Decimal? = nil,
        total: Decimal? = nil,
        currency: String? = "USD",
        paymentMethod: PaymentMethod = .unknown,
        cardLastFourDigits: String? = nil,
        category: ReceiptCategory = .uncategorized,
        notes: String? = nil,
        createdAt: Date = Date(),
        items: [ReceiptItem] = []
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.rawText = rawText
        self.storeName = storeName
        self.storeAddress = storeAddress
        self.storePhone = storePhone
        self.transactionDate = transactionDate
        self.transactionNumber = transactionNumber
        self.subtotal = subtotal
        self.tax = tax
        self.tips = tips
        self.total = total
        self.currency = currency
        self.paymentMethodRaw = paymentMethod.rawValue
        self.cardLastFourDigits = cardLastFourDigits
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.items = items
    }
    
    // MARK: - Formatted Properties
    
    var formattedTotal: String {
        formatCurrency(total)
    }
    
    var formattedSubtotal: String {
        formatCurrency(subtotal)
    }
    
    var formattedTax: String {
        formatCurrency(tax)
    }
    
    var formattedTips: String {
        formatCurrency(tips)
    }
    
    var formattedDate: String {
        guard let date = transactionDate else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var displayName: String {
        storeName ?? "Unknown Store"
    }
    
    var paymentDisplay: String {
        if let lastFour = cardLastFourDigits, !lastFour.isEmpty {
            return "\(paymentMethod.rawValue) ••••\(lastFour)"
        }
        return paymentMethod.rawValue
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ value: Decimal?) -> String {
        guard let value = value else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? "—"
    }
}
