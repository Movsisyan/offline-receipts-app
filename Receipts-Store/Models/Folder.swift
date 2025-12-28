//
//  Folder.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-28.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Folder {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var createdAt: Date
    var sortOrder: Int
    
    @Relationship(deleteRule: .nullify, inverse: \Receipt.folder)
    var receipts: [Receipt]
    
    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "007AFF",
        iconName: String = "folder.fill",
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.receipts = []
    }
    
    // MARK: - Color
    
    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }
    
    // MARK: - Receipt Count
    
    var receiptCount: Int {
        receipts.count
    }
    
    // MARK: - Preset Colors
    
    static let presetColors: [(name: String, hex: String)] = [
        ("Blue", "007AFF"),
        ("Purple", "AF52DE"),
        ("Pink", "FF2D55"),
        ("Red", "FF3B30"),
        ("Orange", "FF9500"),
        ("Yellow", "FFCC00"),
        ("Green", "34C759"),
        ("Teal", "5AC8FA"),
        ("Indigo", "5856D6"),
        ("Brown", "A2845E"),
        ("Gray", "8E8E93")
    ]
    
    // MARK: - Preset Icons
    
    static let presetIcons: [String] = [
        "folder.fill",
        "briefcase.fill",
        "airplane",
        "car.fill",
        "house.fill",
        "heart.fill",
        "star.fill",
        "tag.fill",
        "gift.fill",
        "cart.fill",
        "creditcard.fill",
        "building.2.fill",
        "fork.knife",
        "cup.and.saucer.fill",
        "tshirt.fill",
        "cross.case.fill"
    ]
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
