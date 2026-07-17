import SwiftUI

// MARK: - Primary Button
struct SSButton: View {
    let title: String
    var icon: String? = nil
    var style: SSButtonStyle = .primary
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    enum SSButtonStyle {
        case primary, secondary, ghost, danger, accent
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            SSHaptics.light()
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        SSIconImage(name: icon, size: 16)
                    }
                    Text(title)
                        .font(Font.SS.accentMedium)
                        .tracking(0.3)
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundView)
            .overlay(borderOverlay)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .ssShadow(style == .primary ? .glow : .subtle)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isEnabled ? "" : "Disabled")
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.SS.accent
        case .secondary:
            Color.SS.surfaceSecondary
        case .ghost:
            Color.clear
        case .danger:
            Color.SS.error.opacity(0.10)
        case .accent:
            Color.SS.gradientPrimary
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .ghost:
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.SS.separatorStrong, lineWidth: 1)
        case .secondary:
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.SS.separator, lineWidth: 1)
        default:
            EmptyView()
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return Color.SS.textPrimary
        case .ghost: return Color.SS.accent
        case .danger: return Color.SS.error
        case .accent: return .white
        }
    }
}

// MARK: - Text Field
struct SSTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    #if canImport(UIKit)
    var keyboardType: UIKeyboardType = .default
    #endif
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                SSIconImage(name: icon, size: 16)
                    .foregroundColor(isFocused ? Color.SS.accent : Color.SS.textTertiary)
                    .frame(width: 20)
            }

            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder)
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textTertiary))
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textPrimary)
                    .focused($isFocused)
            } else {
                TextField("", text: $text, prompt: Text(placeholder)
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textTertiary))
                    .font(Font.SS.bodyMedium)
                    .foregroundColor(Color.SS.textPrimary)
                    #if canImport(UIKit)
                    .keyboardType(keyboardType)
                    #endif
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 52)
        .background(Color.SS.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(
                    isFocused ? Color.SS.accent : Color.SS.separator,
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .ssShadow(.subtle)
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .accessibilityLabel(placeholder)
    }
}

// MARK: - Card
struct SSCard<Content: View>: View {
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = Radius.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.SS.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.SS.separator, lineWidth: 0.5)
            )
            .ssShadow(.medium)
    }
}

// MARK: - Accent Card
struct SSAccentCard<Content: View>: View {
    var accentColor: Color = Color.SS.accent
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(accentColor.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(accentColor.opacity(0.15), lineWidth: 1)
            )
            .ssShadow(.subtle)
    }
}

// MARK: - Divider
struct SSDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.SS.separator)
            .frame(height: 1)
    }
}

// MARK: - Chip / Tag
struct SSChip: View {
    let label: String
    var color: Color = Color.SS.accent
    var isSelected: Bool = false

    var body: some View {
        Text(label)
            .font(Font.SS.labelMedium)
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs + 3)
            .accessibilityLabel(label)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : color.opacity(0.25), lineWidth: 1)
            )
    }
}

// MARK: - Icon Button
struct SSIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var iconSize: CGFloat = 18
    var style: IconStyle = .ghost

    enum IconStyle { case ghost, filled, accent }

    let action: () -> Void

    var body: some View {
        Button(action: {
            SSHaptics.selection()
            action()
        }) {
            SSIconImage(name: icon, size: iconSize)
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
        .ssShadow(.subtle)
        .accessibilityLabel(icon.replacingOccurrences(of: "ss.", with: ""))
        .accessibilityAddTraits(.isButton)
    }

    private var foregroundColor: Color {
        switch style {
        case .ghost: return Color.SS.textSecondary
        case .filled: return Color.SS.textPrimary
        case .accent: return Color.SS.accent
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .ghost: return Color.SS.surfacePrimary
        case .filled: return Color.SS.surfaceSecondary
        case .accent: return Color.SS.accentSubtle
        }
    }

    private var borderColor: Color {
        switch style {
        case .ghost: return Color.SS.separator
        case .filled: return Color.SS.separator
        case .accent: return Color.SS.accent.opacity(0.2)
        }
    }
}

// MARK: - Progress Ring
struct SSProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 4
    var size: CGFloat = 60
    var color: Color = Color.SS.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Severity Bar
struct SSSeverityBar: View {
    let severity: Int
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.SS.surfaceTertiary)
                Capsule()
                    .fill(severityColor)
                    .frame(width: geo.size.width * CGFloat(severity) / 10.0)
                    .animation(.easeOut(duration: 0.4), value: severity)
            }
        }
        .frame(height: height)
    }

    private var severityColor: Color {
        switch severity {
        case 0...2: return Color.SS.severityNone
        case 3...4: return Color.SS.severityMild
        case 5...6: return Color.SS.severityModerate
        case 7...8: return Color.SS.severitySevere
        default: return Color.SS.severityCritical
        }
    }
}

// MARK: - Loading Dots
struct SSLoadingDots: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.SS.accent)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.0 : 0.4)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.2 * Double(index)),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Press Events
struct PressModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Navigation Bar
struct SSNavigationBar: View {
    var title: String = ""
    var subtitle: String? = nil
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil
    var leadingAction: (() -> Void)? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let leadingIcon = leadingIcon {
                SSIconButton(icon: leadingIcon, size: 38, iconSize: 16) {
                    leadingAction?()
                }
            } else {
                Spacer().frame(width: 38)
            }

            Spacer()

            VStack(spacing: 2) {
                if !title.isEmpty {
                    Text(title)
                        .font(Font.SS.titleMedium)
                        .foregroundColor(Color.SS.textPrimary)
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Font.SS.labelSmall)
                        .foregroundColor(Color.SS.textTertiary)
                }
            }

            Spacer()

            if let trailingIcon = trailingIcon {
                SSIconButton(icon: trailingIcon, size: 38, iconSize: 16) {
                    trailingAction?()
                }
            } else {
                Spacer().frame(width: 38)
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 52)
    }
}

// MARK: - Animated Number
struct SSAnimatedNumber: View {
    let value: Int
    var font: Font = Font.SS.dataLarge
    var color: Color = Color.SS.textPrimary

    var body: some View {
        Text("\(value)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: value)
    }
}

// MARK: - Empty State
struct SSEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            SSIconImage(name: icon, size: 48)
                .foregroundColor(Color.SS.textDisabled)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Font.SS.headlineMedium)
                    .foregroundColor(Color.SS.textSecondary)

                Text(subtitle)
                    .font(Font.SS.bodySmall)
                    .foregroundColor(Color.SS.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            if let actionTitle = actionTitle, let action = action {
                SSButton(title: actionTitle, style: .ghost, action: action)
                    .frame(width: 200)
            }
        }
        .padding(Spacing.xxxl)
    }
}

// MARK: - Toast
struct SSToast: View {
    let message: String
    var icon: String = "ss.checkmark"
    var color: Color = Color.SS.success

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SSIconImage(name: icon, size: 16)
                .foregroundColor(color)

            Text(message)
                .font(Font.SS.bodySmall)
                .foregroundColor(Color.SS.textPrimary)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.SS.surfacePrimary)
        )
        .ssShadow(.elevated)
        .padding(.horizontal, Spacing.lg)
    }
}
