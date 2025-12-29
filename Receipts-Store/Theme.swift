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
    
    /// Deep Hermès Orange for pressed states
    static let orangeDark = Color(hex: "D65A10") ?? .orange
    
    /// Light orange for subtle highlights
    static let orangeLight = Color(hex: "FFF4ED") ?? .orange.opacity(0.1)
    
    /// Warm cream background
    static let cream = Color(hex: "FAF8F5") ?? Color(.systemBackground)
    
    /// Pure white
    static let white = Color.white
    
    /// Warm off-white for subtle backgrounds
    static let offWhite = Color(hex: "F5F3F0") ?? Color(.secondarySystemBackground)
    
    /// Elegant black for text
    static let black = Color(hex: "1A1A1A") ?? .black
    
    /// Warm gray for secondary text
    static let gray = Color(hex: "8C8C8C") ?? .gray
    
    /// Light gray for borders
    static let lightGray = Color(hex: "E5E3E0") ?? Color(.separator)
    
    /// Very light gray for hover states
    static let hoverGray = Color(hex: "F0EEEB") ?? Color(.separator).opacity(0.5)
    
    /// Success green - muted elegant
    static let success = Color(hex: "4A7C59") ?? .green
    
    /// Error red - elegant
    static let error = Color(hex: "C53030") ?? .red
    
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
    
    // MARK: - Shadows
    
    static let cardShadowColor = Color.black.opacity(0.04)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2
    
    // Elevated shadow for interactive elements
    static let elevatedShadowColor = Color.black.opacity(0.08)
    static let elevatedShadowRadius: CGFloat = 16
    static let elevatedShadowY: CGFloat = 4
    
    // MARK: - Animations
    
    static let springAnimation = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let quickAnimation = Animation.easeOut(duration: 0.15)
    static let smoothAnimation = Animation.easeInOut(duration: 0.25)
}

// MARK: - Premium Section Header

struct PremiumSectionHeader: View {
    let title: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(AppTheme.orange.opacity(0.7))
            }
            
            Text(title.uppercased())
                .font(.system(.caption, design: .default, weight: .medium))
                .foregroundStyle(AppTheme.gray)
                .tracking(2)
            
            Spacer()
        }
    }
}

// MARK: - Premium Info Row

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

// MARK: - Premium Divider

struct PremiumDivider: View {
    var inset: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(AppTheme.lightGray.opacity(0.7))
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

// MARK: - Hermès Info Row

struct HermesInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = AppTheme.black
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Premium Empty State

struct PremiumEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Get Started"
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated icon with subtle pulse
            ZStack {
                Circle()
                    .fill(AppTheme.orangeLight)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(AppTheme.orange)
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(.title3, design: .serif, weight: .regular))
                    .foregroundStyle(AppTheme.black)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            if let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Text(actionLabel.uppercased())
                            .font(.system(.caption, design: .default, weight: .semibold))
                            .tracking(2)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(AppTheme.orange)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.orange.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Hermès Button Style

struct HermesButtonStyle: ButtonStyle {
    var isFilled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .default, weight: .semibold))
            .tracking(2)
            .foregroundStyle(isFilled ? .white : AppTheme.orange)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isFilled {
                        Capsule()
                            .fill(configuration.isPressed ? AppTheme.orangeDark : AppTheme.orange)
                    } else {
                        Capsule()
                            .strokeBorder(AppTheme.orange, lineWidth: 1.5)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppTheme.quickAnimation, value: configuration.isPressed)
    }
}

// MARK: - Hermès Card

struct HermesCard<Content: View>: View {
    var showBorder: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .background(AppTheme.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(showBorder ? AppTheme.lightGray : .clear, lineWidth: 0.5)
            )
    }
}

// MARK: - Hermès Section

struct HermesSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.orange)
                }
                
                Text(title.uppercased())
                    .font(.system(.caption2, design: .default, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.gray)
            }
            
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.white)
    }
}

// MARK: - Hermès Text Field

struct HermesTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(.caption2, design: .default, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(AppTheme.gray)
            
            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.black)
                .keyboardType(keyboardType)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(AppTheme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(AppTheme.lightGray.opacity(0.5), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Hermès Currency Field

struct HermesCurrencyField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.gray)
            Spacer()
            HStack(spacing: 2) {
                Text("$")
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(AppTheme.gray)
                TextField("0.00", text: $value)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(AppTheme.black)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            AppTheme.white.opacity(0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Pressed Button Effect

struct PressedButtonModifier: ViewModifier {
    var isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(AppTheme.quickAnimation, value: isPressed)
    }
}
