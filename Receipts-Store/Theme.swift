//
//  Theme.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-28.
//

import SwiftUI

// MARK: - Hermès-Inspired App Theme

enum AppTheme {
    
    // MARK: - Brand Colors
    
    /// Hermès Orange - The iconic brand color
    static let orange = Color(hex: "F37021") ?? .orange
    
    /// Deep Hermès Orange for accents
    static let orangeDark = Color(hex: "E55A00") ?? .orange
    
    /// Warm cream background
    static let cream = Color(hex: "FAF8F5") ?? Color(.systemBackground)
    
    /// Pure white
    static let white = Color.white
    
    /// Warm off-white
    static let offWhite = Color(hex: "F5F3F0") ?? Color(.secondarySystemBackground)
    
    /// Elegant black for text
    static let black = Color(hex: "1A1A1A") ?? .black
    
    /// Warm gray for secondary text
    static let gray = Color(hex: "8C8C8C") ?? .gray
    
    /// Light gray for borders
    static let lightGray = Color(hex: "E5E3E0") ?? Color(.separator)
    
    /// Success green - muted elegant
    static let success = Color(hex: "4A7C59") ?? .green
    
    // MARK: - Semantic Colors
    
    static let primary = black
    static let secondary = gray
    static let accent = orange
    static let background = cream
    static let cardBackground = white
    static let textSecondary = gray
    static let textTertiary = Color(hex: "B5B5B5") ?? .gray
    
    // MARK: - Typography
    
    /// Elegant display font (serif)
    static func displayFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    
    /// Clean body font
    static let titleFont = Font.system(.title2, design: .serif, weight: .regular)
    static let headlineFont = Font.system(.headline, design: .default, weight: .medium)
    static let bodyFont = Font.system(.body, design: .default, weight: .regular)
    static let captionFont = Font.system(.caption, design: .default, weight: .regular)
    
    // MARK: - Spacing
    
    static let spacing: CGFloat = 16
    static let cornerRadius: CGFloat = 4
    static let smallCornerRadius: CGFloat = 2
    
    // MARK: - Shadows (minimal)
    
    static let cardShadowColor = Color.black.opacity(0.04)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2
}

// MARK: - Premium Components

struct PremiumSectionHeader: View {
    let title: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(.caption, design: .default, weight: .medium))
                .foregroundStyle(AppTheme.gray)
                .tracking(2)
            
            Spacer()
        }
    }
}

struct PremiumInfoRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var valueColor: Color = AppTheme.black
    var isBold: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: .default, weight: isBold ? .semibold : .regular))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

struct PremiumDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.lightGray)
            .frame(height: 1)
    }
}

// MARK: - Hermès Info Row

struct HermesInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.black)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct PremiumEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Get Started"
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(AppTheme.orange)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .regular))
                    .foregroundStyle(AppTheme.black)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let action = action {
                Button(action: action) {
                    Text(actionLabel.uppercased())
                        .font(.system(.caption, design: .default, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(AppTheme.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Hermès Button Style

struct HermesButtonStyle: ButtonStyle {
    var isFilled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .default, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(isFilled ? .white : AppTheme.orange)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isFilled ? AppTheme.orange : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(AppTheme.orange, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
