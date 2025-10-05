import SwiftUI
import CoreHaptics
import Combine
import UIKit

struct SplashView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.88
    @State private var haloPulse = false
    @State private var sweepOffset: CGFloat = -160
    @State private var grainOpacity: Double = 0.0

    @StateObject private var haptics = HapticsManager()  // 🔔

    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            RadialGradient(colors: [Color.black.opacity(0.06), .clear],
                           center: .center, startRadius: 2, endRadius: 420)
            .ignoresSafeArea()
            .blendMode(.multiply)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Brand.secondary.opacity(haloPulse ? 0.26 : 0.12), .clear],
                                             center: .center, startRadius: 6, endRadius: 180))
                        .frame(width: 220, height: 220)
                        .blur(radius: 28)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: haloPulse)

                    Group {
                        if UIImage(named: "AmanPayGlyph") != nil {
                            Image("AmanPayGlyph").renderingMode(.original).resizable().scaledToFit()
                        } else {
                            Image(systemName: "creditcard.fill").resizable().scaledToFit().foregroundStyle(Brand.primary)
                        }
                    }
                    .frame(width: 112, height: 112)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)

                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .white.opacity(0.75), .clear],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 8, height: 160)
                        .rotationEffect(.degrees(22))
                        .offset(x: sweepOffset)
                        .blendMode(.screen)
                        .opacity(logoOpacity * 0.9)
                }

                Text("AmanPay")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(Brand.ink)
                    .opacity(logoOpacity)

                Text("Qulay • Tez • Halol-Nasiya")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .opacity(logoOpacity)
                    .padding(.top, 2)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Brand.primary)
                    .opacity(logoOpacity)
                    .padding(.top, 8)
            }
            .padding(32)

            NoiseOverlay().opacity(grainOpacity).allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                logoOpacity = 1.0; logoScale = 1.0; grainOpacity = 0.07
            }
            haloPulse = true
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                sweepOffset = 160
            }

            // 🔔 Haptics
            haptics.prepare()
            // Haptics
            haptics.prepare()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                haptics.playPremiumSplash()
            }

        }
    }
}


// MARK: - Haptics Manager (CoreHaptics + fallback)


final class HapticsManager: ObservableObject {
    private var engine: CHHapticEngine?
    private var supports: Bool { CHHapticEngine.capabilitiesForHardware().supportsHaptics }
    private var observers: [NSObjectProtocol] = []

    func prepare() {
        guard supports else { return }
        // Agar allaqachon bor bo‘lsa, qayta yaratmang
        if engine == nil {
            do {
                engine = try CHHapticEngine()
                engine?.playsHapticsOnly = true        // ✅ audio sessiyani minimallashtiradi
                try engine?.start()
                // Handlers
                engine?.resetHandler = { [weak self] in
                    do { try self?.engine?.start() } catch { }
                }
                engine?.stoppedHandler = { reason in
                    // xohlasa logging — majburiy emas
                }
                // App lifecycle: bg/fg
                installLifecycleObservers()
            } catch {
                engine = nil
            }
        } else {
            // mavjud engine bo‘lsa ishga tushirishga urinish
            do { try engine?.start() } catch { }
        }
    }

    func stop() {                      // ✅ tashqi joydan chaqirish uchun
        engine?.stop(completionHandler: { _ in })
        engine = nil
        removeLifecycleObservers()
    }

    deinit { stop() }

    // MARK: - Lifecycle observers
    private func installLifecycleObservers() {
        removeLifecycleObservers()
        let c = NotificationCenter.default
        observers.append(c.addObserver(forName: UIApplication.willResignActiveNotification,
                                       object: nil, queue: .main) { [weak self] _ in
            self?.engine?.stop(completionHandler: { _ in })
        })
        observers.append(c.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                       object: nil, queue: .main) { [weak self] _ in
            do { try self?.engine?.start() } catch { }
        })
        observers.append(c.addObserver(forName: UIApplication.willTerminateNotification,
                                       object: nil, queue: .main) { [weak self] _ in
            self?.stop()
        })
    }

    private func removeLifecycleObservers() {
        let c = NotificationCenter.default
        for o in observers { c.removeObserver(o) }
        observers.removeAll()
    }

    /// PayPal-ruhidagi "premium" splash vibro: intro → pulsing → double-tick → shimmer
    func playPremiumSplash() {
        guard supports else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            return
        }

        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []

        // 0) Intro tick
        events.append(
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.55),
                    .init(parameterID: .hapticSharpness, value: 0.70)
                ],
                relativeTime: 0.00
            )
        )

        // 1) Breathing pulse (smooth ramp up/down)
        let t1: TimeInterval = 0.12
        let d1: TimeInterval = 0.24
        events.append(
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.0),
                    .init(parameterID: .hapticSharpness, value: 0.55)
                ],
                relativeTime: t1,
                duration: d1
            )
        )
        curves.append(
            CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.55),
                    .init(relativeTime: d1 * 0.50, value: 0.80),
                    .init(relativeTime: d1, value: 0.55)
                ],
                relativeTime: t1
            )
        )

        // 2) Double tick (crisp)
        for (i, t) in [0.48, 0.62].enumerated() {
            let intensity: Float = i == 0 ? 0.80 : 0.65
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        .init(parameterID: .hapticIntensity, value: intensity),
                        .init(parameterID: .hapticSharpness, value: 0.85)
                    ],
                    relativeTime: t
                )
            )
        }

        // 3) Shimmer (uchta juda qisqa, yengil)
        for (i, t) in [0.90, 1.02, 1.10].enumerated() {
            let intensity: Float = [0.28, 0.36, 0.24][i]
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        .init(parameterID: .hapticIntensity, value: intensity),
                        .init(parameterID: .hapticSharpness, value: 0.95)
                    ],
                    relativeTime: t
                )
            )
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }

    /// (ixtiyoriy) Keyingi sahifaga o‘tganda “soft success”
    func playSuccess() {
        guard supports else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        var ev: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient,
                          parameters: [.init(parameterID: .hapticIntensity, value: 0.55),
                                       .init(parameterID: .hapticSharpness, value: 0.6)],
                          relativeTime: 0.0),
            CHHapticEvent(eventType: .hapticTransient,
                          parameters: [.init(parameterID: .hapticIntensity, value: 0.85),
                                       .init(parameterID: .hapticSharpness, value: 0.75)],
                          relativeTime: 0.09)
        ]
        do {
            let pattern = try CHHapticPattern(events: ev, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}



// MARK: - Noise overlay (subtle film grain for premium feel)
private struct NoiseOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            let noise = NoiseGenerator.seeded(42)
            let step: CGFloat = 3
            for x in stride(from: 0, to: size.width, by: step) {
                for y in stride(from: 0, to: size.height, by: step) {
                    let n = noise.value(at: CGPoint(x: x, y: y))
                    let alpha = 0.04 + 0.02 * n
                    ctx.fill(Path(CGRect(x: x, y: y, width: step, height: step)),
                             with: .color(Color.black.opacity(alpha)))
                }
            }
        }
        .ignoresSafeArea()
        .blendMode(.overlay)
    }
}

// Tiny value-noise generator (deterministic, lightweight)
private struct NoiseGenerator {
    private let seed: UInt64
    static func seeded(_ s: UInt64) -> NoiseGenerator { .init(seed: s) }
    func value(at p: CGPoint) -> CGFloat {
        let x = UInt64(p.x * 1337.0)
        let y = UInt64(p.y * 420.0)
        var z = seed ^ x &* 0x9E3779B185EBCA87 &+ y &* 0xC2B2AE3D27D4EB4F
        z ^= z >> 30; z &*= 0xBF58476D1CE4E5B9
        z ^= z >> 27; z &*= 0x94D049BB133111EB
        z ^= z >> 31
        let f = Double(z & 0xFFFFFFFF) / Double(UInt32.max)
        return CGFloat(f)
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.light)
}
