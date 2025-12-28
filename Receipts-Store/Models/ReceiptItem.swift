//
//  ReceiptItem.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import Foundation
import SwiftData

@Model
final class ReceiptItem {
    var id: UUID
    var name: String
    var quantity: Int?
    var price: Decimal?
    
    @Relationship(inverse: \Receipt.items)
    var receipt: Receipt?
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int? = nil,
        price: Decimal? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.price = price
    }
    
    var formattedPrice: String {
        guard let price = price else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: price as NSDecimalNumber) ?? "—"
    }
    
    var displayQuantity: String {
        guard let qty = quantity, qty > 1 else { return "" }
        return "×\(qty)"
    }
}
