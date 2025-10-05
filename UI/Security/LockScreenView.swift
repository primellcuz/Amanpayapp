import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject private var lock: AppLockManager

    @State private var pin: String = ""
    @State private var error: String?
    @State private var triedBiometric = false   // auto-promptni faqat 1 marta qilish

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("AmanPay qulflangan")
                    .font(.title3.weight(.semibold))

                if lock.hasPin {
                    Text("PIN-kodni kiriting")
                        .foregroundStyle(.secondary)

                    PinDots(count: lock.pinLength, filled: pin.count)

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 6)
                    }

                    if lock.biometricEnabled && lock.biometricAvailable {
                        Button {
                            Task {
                                let ok = await lock.unlockWithBiometricsAsync()
                                if !ok { error = "Biometrik tekshiruv bekor qilindi" }
                            }
                        } label: {
                            Label("Face ID bilan ochish", systemImage: "faceid")
                                .font(.callout.weight(.semibold))
                        }
                        .padding(.top, 4)
                    }

                    NumberPad { digit in
                        if digit == "<" {
                            if !pin.isEmpty { pin.removeLast() }
                        } else {
                            if pin.count < lock.pinLength { pin.append(digit) }
                            if pin.count == lock.pinLength {
                                if lock.unlockWithPin(pin) {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                } else {
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    error = "PIN noto‘g‘ri"
                                    pin.removeAll()
                                }
                            }
                        }
                    }
                    .padding(.top, 8)

                } else {
                    // PIN yo‘q — faqat biometrik (agar yoqilgan bo‘lsa) yoki umuman qulflamaslik
                    if lock.biometricEnabled && lock.biometricAvailable {
                        Text("Face ID orqali oching")
                            .foregroundStyle(.secondary)

                        Button {
                            Task {
                                let ok = await lock.authenticateAsync(allowPasscode: false)
                                if !ok { error = "Biometrik tekshiruv bekor qilindi" }
                            }
                        } label: {
                            Label("Face ID bilan ochish", systemImage: "faceid")
                                .font(.callout.weight(.semibold))
                        }
                        .padding(.top, 6)

                        if let error {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.top, 6)
                        }
                    } else {
                        // PIN ham yo‘q, biometrik ham yo‘q — qulflash shart emas
                        Text("Qulflash yoqilmagan")
                            .foregroundStyle(.secondary)
                            .task { lock.isLocked = false } // darhol ochamiz
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 24)
        }
        .onAppear {
            // PIN yo‘q va biometrik bor — avtomatik Face ID prompt
            if !lock.hasPin, lock.biometricEnabled, lock.biometricAvailable, !triedBiometric {
                triedBiometric = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Task { _ = await lock.authenticateAsync(allowPasscode: false) }
                }
            }
        }
    }
}

// MARK: - Helpers (shu faylda)

/// PIN nuqtalar indikatorlari
private struct PinDots: View {
    let count: Int
    let filled: Int
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i < filled ? Color.primary : Color.secondary.opacity(0.25))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 6)
    }
}

/// Raqamli klaviatura
private struct NumberPad: View {
    let tap: (String) -> Void
    init(tap: @escaping (String) -> Void) { self.tap = tap }

    var body: some View {
        VStack(spacing: 12) {
            ForEach([["1","2","3"], ["4","5","6"], ["7","8","9"]], id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { d in
                        Key(d, tap: tap)
                    }
                }
            }
            HStack(spacing: 12) {
                Spacer().frame(width: 64)
                Key("0", tap: tap)
                Key("<", tap: tap, system: "delete.left")
            }
        }
    }

    private struct Key: View {
        let label: String
        let tap: (String) -> Void
        var system: String?

        init(_ label: String, tap: @escaping (String) -> Void, system: String? = nil) {
            self.label = label
            self.tap = tap
            self.system = system
        }

        var body: some View {
            Button { tap(label) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray6))
                        .frame(width: 64, height: 52)
                    if let system {
                        Image(systemName: system)
                    } else {
                        Text(label)
                            .font(.title2.weight(.semibold))
                    }
                }
            }
        }
    }
}
