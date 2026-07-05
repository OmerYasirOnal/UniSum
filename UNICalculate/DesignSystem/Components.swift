//
//  Components.swift
//  UNICalculate — UniSum Design System
//
//  Reusable, composable UI building blocks styled with the design tokens in
//  Theme.swift. Screens should assemble these rather than re-implementing
//  cards, buttons, badges and rings inline.
//

import SwiftUI

// MARK: - Card container

struct CardModifier: ViewModifier {
    var padding: CGFloat = DS.Spacing.md
    var radius: CGFloat = DS.Radius.md
    var fill: Color = .cardBackground

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 0.75)
            )
            .softShadow()
    }
}

extension View {
    /// Wrap content in the standard elevated card surface.
    func card(padding: CGFloat = DS.Spacing.md,
              radius: CGFloat = DS.Radius.md,
              fill: Color = .cardBackground) -> some View {
        modifier(CardModifier(padding: padding, radius: radius, fill: fill))
    }

    /// Style a `List` row to host a floating card: clear background, no
    /// separator, tight symmetric insets. Keeps `List` behaviours (swipe
    /// actions, onDelete) while looking like a card stack.
    func plainCardRow(vertical: CGFloat = 5) -> some View {
        self
            .listRowInsets(EdgeInsets(top: vertical, leading: DS.Spacing.md,
                                      bottom: vertical, trailing: DS.Spacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

// MARK: - Buttons

/// Full-width gradient primary action button style.
struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(LinearGradient.brand)
                                  : AnyShapeStyle(Color.gray.opacity(0.4)))
            )
            .brandGlow(opacity: enabled ? 0.35 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Subtle tinted secondary button style.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.brandOnTint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(Color.brandTint)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Floating action button

struct FloatingAddButton: View {
    var systemImage: String = "plus"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(LinearGradient.brand))
                .brandGlow(radius: 18, y: 10, opacity: 0.45)
        }
        .accessibilityLabel(Text("add"))
    }
}

// MARK: - GPA ring

/// Circular progress ring visualising a GPA on a 0...maxGPA scale.
struct GPARing: View {
    let gpa: Double
    var maxGPA: Double = 4.0
    var centerText: String? = nil   // e.g. a letter grade shown large
    var size: CGFloat = 104
    var lineWidth: CGFloat = 11

    private var progress: Double { min(max(gpa / maxGPA, 0), 1) }
    private var color: Color { GradeColor.forGPA(gpa) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.hairline, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [color.opacity(0.65), color],
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                if let centerText {
                    Text(centerText)
                        .font(.system(size: size * 0.30, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                    Text(String(format: "%.2f", gpa))
                        .font(.system(size: size * 0.13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(format: "%.2f", gpa))
                        .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                    Text("/ \(String(format: "%.1f", maxGPA))")
                        .font(.system(size: size * 0.11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.5), value: progress)
    }
}

// MARK: - Grade badge

/// Small pill showing a letter grade, colored by its GPA value.
struct GradeBadge: View {
    let letter: String
    var gpa: Double? = nil
    var compact: Bool = false

    private var color: Color { GradeColor.forGPA(gpa ?? gpaGuess(for: letter)) }

    var body: some View {
        Text(letter)
            .font(.system(size: compact ? 13 : 15, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 3 : 5)
            .background(
                Capsule(style: .continuous).fill(color.opacity(0.14))
            )
    }

    /// Rough mapping so a letter without an explicit GPA still colors sensibly.
    private func gpaGuess(for letter: String) -> Double {
        switch letter.uppercased() {
        case "AA": return 4.0
        case "BA": return 3.5
        case "BB": return 3.0
        case "CB": return 2.5
        case "CC": return 2.0
        case "DC": return 1.5
        case "DD": return 1.0
        case "FD": return 0.5
        default:   return 0.0
        }
    }
}

// MARK: - Stat tile

/// Compact labelled value card, e.g. "Term GPA / 3.42".
struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    var systemImage: String? = nil
    var accent: Color = .brandPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(accent)
                }
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

// MARK: - Weight / progress bar

struct WeightBar: View {
    let fraction: Double        // 0...1
    var color: Color = .brandPrimary
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.hairline)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let systemImage: String
    let title: LocalizedStringKey
    var message: LocalizedStringKey? = nil
    var tint: Color = .brandPrimary

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(tint)
            }
            VStack(spacing: DS.Spacing.xxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.xl)
    }
}

// MARK: - App logo / wordmark

/// Rounded-square brand mark: graduation cap in the indigo→violet gradient.
struct AppLogoMark: View {
    var size: CGFloat = 72

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(LinearGradient.brand)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .brandGlow(radius: size * 0.22, y: size * 0.12, opacity: 0.4)
    }
}

/// Logo mark + "UniSum" wordmark, stacked vertically.
struct AppWordmark: View {
    var logoSize: CGFloat = 76

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            AppLogoMark(size: logoSize)
            Text("UniSum")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient.brand)
        }
    }
}

// MARK: - Section header

struct SectionHeaderLabel: View {
    let title: LocalizedStringKey
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
            }
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
}
