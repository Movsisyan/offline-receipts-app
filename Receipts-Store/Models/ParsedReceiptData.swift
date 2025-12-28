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
    @Guide(description: "Name of the store or merchant where the purchase was made")
    var storeName: String?
    
    @Guide(description: "Transaction date in YYYY-MM-DD format if available")
    var dateString: String?
    
    @Guide(description: "Total amount paid including tax")
    var total: Double?
    
    @Guide(description: "Currency code like USD, EUR, etc. Default to USD if not clear")
    var currency: String?
    
    @Guide(description: "List of individual items purchased")
    var items: [ParsedItem]?
}

// MARK: - Conversion to SwiftData Models

extension ParsedReceiptData {
    /// Converts the parsed date string to a Date object
    var parsedDate: Date? {
        guard let dateString = dateString else { return nil }
        
        let formatters: [DateFormatter] = {
            let formats = ["yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "MMM dd, yyyy"]
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
}
