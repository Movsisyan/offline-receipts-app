//
//  ParsedReceiptData.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import Foundation
import FoundationModels

/// Represents a single item parsed from a receipt
@Generable
struct ParsedItem: Hashable {
    @Guide(description: "Name or description of the item purchased")
    var name: String
    
    @Guide(description: "Quantity of items, defaults to 1 if not specified")
    var quantity: Int?
    
    @Guide(description: "Price of the item in decimal format")
    var price: Double?
}

/// Structured output from LLM parsing of receipt text
@Generable
struct ParsedReceiptData {
    // Store information
    @Guide(description: "Name of the store or merchant where the purchase was made")
    var storeName: String?
    
    @Guide(description: "Full street address of the store if available")
    var storeAddress: String?
    
    @Guide(description: "Store phone number if available")
    var storePhone: String?
    
    // Transaction details
    @Guide(description: "Transaction date in YYYY-MM-DD format if available")
    var dateString: String?
    
    @Guide(description: "Transaction or receipt number for reference")
    var transactionNumber: String?
    
    // Financial breakdown
    @Guide(description: "Subtotal amount before tax and tips")
    var subtotal: Double?
    
    @Guide(description: "Tax amount charged")
    var tax: Double?
    
    @Guide(description: "Tip or gratuity amount if applicable")
    var tips: Double?
    
    @Guide(description: "Total amount paid including tax and tips")
    var total: Double?
    
    @Guide(description: "Currency code like USD, EUR, CAD. Default to USD if not clear")
    var currency: String?
    
    // Payment information
    @Guide(description: "Payment method: Cash, Credit Card, Debit Card, Apple Pay, Gift Card, or Other")
    var paymentMethod: String?
    
    @Guide(description: "Last 4 digits of the card used if visible")
    var cardLastFourDigits: String?
    
    // Category suggestion
    @Guide(description: "Suggested category: Groceries, Restaurant, Gas & Fuel, Shopping, Entertainment, Travel, Healthcare, Utilities, or Other")
    var suggestedCategory: String?
    
    // Items
    @Guide(description: "List of individual items purchased with their prices")
    var items: [ParsedItem]?
}

// MARK: - Conversion to SwiftData Models

extension ParsedReceiptData {
    /// Converts the parsed date string to a Date object
    var parsedDate: Date? {
        guard let dateString = dateString else { return nil }
        
        let formatters: [DateFormatter] = {
            let formats = ["yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "MMM dd, yyyy", "MMMM dd, yyyy", "MM-dd-yyyy"]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                return formatter
            }
        }()
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
    
    /// Converts the parsed total to Decimal
    var totalAsDecimal: Decimal? {
        guard let total = total else { return nil }
        return Decimal(total)
    }
    
    var subtotalAsDecimal: Decimal? {
        guard let subtotal = subtotal else { return nil }
        return Decimal(subtotal)
    }
    
    var taxAsDecimal: Decimal? {
        guard let tax = tax else { return nil }
        return Decimal(tax)
    }
    
    var tipsAsDecimal: Decimal? {
        guard let tips = tips else { return nil }
        return Decimal(tips)
    }
    
    /// Parses payment method string to enum
    var parsedPaymentMethod: PaymentMethod {
        guard let method = paymentMethod?.lowercased() else { return .unknown }
        
        if method.contains("cash") { return .cash }
        if method.contains("credit") { return .creditCard }
        if method.contains("debit") { return .debitCard }
        if method.contains("apple") { return .applePay }
        if method.contains("gift") { return .giftCard }
        if method.contains("other") { return .other }
        
        return .unknown
    }
    
    /// Parses category string to enum
    var parsedCategory: ReceiptCategory {
        guard let category = suggestedCategory?.lowercased() else { return .uncategorized }
        
        if category.contains("grocer") { return .groceries }
        if category.contains("restaurant") || category.contains("food") || category.contains("dining") { return .restaurant }
        if category.contains("gas") || category.contains("fuel") { return .gas }
        if category.contains("shop") || category.contains("retail") { return .shopping }
        if category.contains("entertain") || category.contains("movie") { return .entertainment }
        if category.contains("travel") || category.contains("hotel") || category.contains("flight") { return .travel }
        if category.contains("health") || category.contains("medical") || category.contains("pharmacy") { return .healthcare }
        if category.contains("utilit") || category.contains("electric") || category.contains("water") { return .utilities }
        if category.contains("other") { return .other }
        
        return .uncategorized
    }
    
    /// Creates ReceiptItem models from parsed items
    func createReceiptItems() -> [ReceiptItem] {
        guard let items = items else { return [] }
        return items.map { item in
            ReceiptItem(
                name: item.name,
                quantity: item.quantity,
                price: item.price.map { Decimal($0) }
            )
        }
    }
    
    /// Creates a Receipt model from this parsed data
    func createReceipt(imageFileName: String, rawText: String?) -> Receipt {
        Receipt(
            imageFileName: imageFileName,
            rawText: rawText,
            storeName: storeName,
            storeAddress: storeAddress,
            storePhone: storePhone,
            transactionDate: parsedDate,
            transactionNumber: transactionNumber,
            subtotal: subtotalAsDecimal,
            tax: taxAsDecimal,
            tips: tipsAsDecimal,
            total: totalAsDecimal,
            currency: currency ?? "USD",
            paymentMethod: parsedPaymentMethod,
            cardLastFourDigits: cardLastFourDigits,
            category: parsedCategory,
            items: createReceiptItems()
        )
    }
}
