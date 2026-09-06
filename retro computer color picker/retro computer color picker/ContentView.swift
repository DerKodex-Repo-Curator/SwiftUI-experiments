// Created by https://github.com/mikelikesdesign

import SwiftUI

struct ScreenColor: Equatable {
    var hue: Double = 0.55
    var saturation: Double = 0.48
    var brightness: Double = 0.92

    var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }
    var uiColor: UIColor { UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1) }
    var hex: String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(format: "#%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }
}

struct ContentView: View {
    @State private var screen = ScreenColor()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                RetroComputerView(screenColor: screen.uiColor)
                    .frame(height: min(440, max(320, geometry.size.height * 0.48)))
                    .accessibilityLabel("3D beige retro computer with a \(screen.hex) screen")
                Spacer(minLength: 24)
                controls
            }
            .frame(
                maxWidth: 540,
                minHeight: max(0, geometry.size.height - 44)
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.055, green: 0.063, blue: 0.06).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Customize screen color")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.78))
            }
            SaturationBrightnessPicker(screen: $screen)
                .frame(height: 118)
            HuePicker(hue: $screen.hue)
                .frame(height: 28)
        }
        .padding(20)
        .frame(maxWidth: 440)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.065)))
    }
}

private struct SaturationBrightnessPicker: View {
    @Binding var screen: ScreenColor
    private let inset: CGFloat = 13

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width - inset * 2)
            let height = max(1, geometry.size.height - inset * 2)
            ZStack(alignment: .topLeading) {
                // Extend the edge colors underneath the thumb's safe inset, so
                // every thumb position corresponds exactly to the displayed color.
                LinearGradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: inset / geometry.size.width),
                    .init(color: Color(hue: screen.hue, saturation: 1, brightness: 1), location: 1 - inset / geometry.size.width),
                    .init(color: Color(hue: screen.hue, saturation: 1, brightness: 1), location: 1)
                ], startPoint: .leading, endPoint: .trailing)
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: inset / geometry.size.height),
                    .init(color: .black, location: 1 - inset / geometry.size.height),
                    .init(color: .black, location: 1)
                ], startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(screen.color)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                    .position(x: inset + screen.saturation * width, y: inset + (1 - screen.brightness) * height)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .highPriorityGesture(DragGesture(minimumDistance: 0).onChanged { value in
                screen.saturation = min(1, max(0, (value.location.x - inset) / width))
                screen.brightness = 1 - min(1, max(0, (value.location.y - inset) / height))
            })
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Screen saturation and brightness")
        .accessibilityValue("Saturation \(Int(screen.saturation * 100)) percent, brightness \(Int(screen.brightness * 100)) percent")
        .accessibilityAdjustableAction { direction in
            screen.saturation = min(1, max(0, screen.saturation + (direction == .increment ? 0.05 : -0.05)))
        }
        .accessibilityAction(named: "Increase brightness") { screen.brightness = min(1, screen.brightness + 0.05) }
        .accessibilityAction(named: "Decrease brightness") { screen.brightness = max(0, screen.brightness - 0.05) }
    }
}

private struct HuePicker: View {
    @Binding var hue: Double

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width - 28)
            ZStack(alignment: .leading) {
                LinearGradient(colors: (0...12).map { Color(hue: Double($0) / 12, saturation: 0.85, brightness: 1) }, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 12)
                    .clipShape(Capsule())
                    .padding(.horizontal, 14)
                Circle()
                    .fill(Color(hue: hue, saturation: 0.85, brightness: 1))
                    .frame(width: 26, height: 26)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                    .offset(x: 1 + hue * width)
            }
            .frame(height: 28)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(DragGesture(minimumDistance: 0).onChanged { value in
                hue = min(1, max(0, (value.location.x - 14) / width))
            })
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Screen hue")
        .accessibilityValue("\(Int(hue * 360)) degrees")
        .accessibilityAdjustableAction { direction in
            hue = min(1, max(0, hue + (direction == .increment ? 0.025 : -0.025)))
        }
    }
}

#Preview {
    ContentView()
}
