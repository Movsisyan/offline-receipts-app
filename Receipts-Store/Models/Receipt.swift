//
//  Receipt.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import Foundation
import SwiftData

@Model
final class Receipt {
    var id: UUID
    var imageFileName: String
    var rawText: String?
    var storeName: String?
    var transactionDate: Date?
    var total: Decimal?
    var notes: String?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var items: [ReceiptItem]
    
    init(
        id: UUID = UUID(),
        imageFileName: String,
        rawText: String? = nil,
        storeName: String? = nil,
        transactionDate: Date? = nil,
        total: Decimal? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        items: [ReceiptItem] = []
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.rawText = rawText
        self.storeName = storeName
        self.transactionDate = transactionDate
        self.total = total
        self.notes = notes
        self.createdAt = createdAt
        self.items = items
    }
    
    var formattedTotal: String {
        guard let total = total else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: total as NSDecimalNumber) ?? "—"
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
}
