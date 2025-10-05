import Foundation
import Combine
import LocalAuthentication

@MainActor
final class AppLockManager: ObservableObject {
    static let shared = AppLockManager()

    @Published var isLocked: Bool = false
    @Published var pinLength: Int = 4

    @Published var biometricAvailable: Bool = false
    @Published var biometricEnabled: Bool = UserDefaults.standard.bool(forKey: "biometricEnabled")
    @Published var hasPin: Bool = PinStore.shared.exists

    private var cancellables = Set<AnyCancellable>()

    init() {
        biometricAvailable = canUseBiometrics()
        // Start holati: PIN bor yoki biometrik yoqilgan bo‘lsa — lock
        isLocked = hasPin || biometricEnabled

        // UserDefaults bilan sync (biometrik toggleni kuzatish)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let enabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
                // Defer publishing to avoid "Publishing changes from within view updates" warnings
                Task { @MainActor in
                    self.biometricEnabled = enabled
                    if !self.hasPin && !enabled {
                        self.isLocked = false
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - PIN
    func enablePin(_ newPin: String) -> Bool {
        guard newPin.count == pinLength else { return false }
        let ok = PinStore.shared.save(pin: newPin)
        if ok {
            hasPin = true
            isLocked = true // darhol qulflash
        }
        return ok
    }

    func changePin(old: String, new: String) -> Bool {
        guard PinStore.shared.verify(pin: old) else { return false }
        return enablePin(new)
    }

    func disablePin(current: String) -> Bool {
        guard PinStore.shared.verify(pin: current) else { return false }
        PinStore.shared.clear()
        hasPin = false
        // Biometrik yoqilgan bo‘lsa — lock qoladi, aks holda ochiladi
        isLocked = biometricEnabled
        return true
    }

    func unlockWithPin(_ pin: String) -> Bool {
        guard hasPin else { return false }
        let ok = PinStore.shared.verify(pin: pin)
        if ok { isLocked = false }
        return ok
    }

    func lock() { isLocked = true }

    // MARK: - Biometrics / Passcode (ASYNC, non-blocking)
    /// Universal autentifikatsiya: biometrik + ixtiyoriy passcode fallback
    @MainActor
    func authenticateAsync(
        reason: String = "AmanPay ni ochish uchun Face ID/Touch ID",
        allowPasscode: Bool = true
    ) async -> Bool {
        let ctx = LAContext()
        var err: NSError?

        // Siyosat: passcode ruxsat etilsa – .deviceOwnerAuthentication (bio -> passcode fallback),
        // aks holda faqat biometrik
        let policy: LAPolicy = allowPasscode ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics

        guard ctx.canEvaluatePolicy(policy, error: &err) else {
            return false
        }

        ctx.localizedCancelTitle = "Bekor qilish"
        // Fallback matni: biometrik-only rejimda ko‘rsatmaymiz
        ctx.localizedFallbackTitle = allowPasscode ? "Parolni kiriting" : ""

        let ok: Bool = await withCheckedContinuation { cont in
            ctx.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                cont.resume(returning: success)
            }
        }

        if ok { isLocked = false }
        return ok
    }

    /// Faqat biometrik (passcodesiz) qulay wrapper
    @MainActor
    func unlockWithBiometricsAsync(
        reason: String = "AmanPay ni ochish uchun Face ID/Touch ID"
    ) async -> Bool {
        await authenticateAsync(reason: reason, allowPasscode: false)
    }

    // ⚠️ Eski (bloklovchi) usulni o‘chirib tashlaymiz yoki faolsizlantiramiz — semaphore bo‘lmasin
    @available(*, unavailable, message: "Use authenticateAsync()/unlockWithBiometricsAsync()")
    func unlockWithBiometrics(reason: String = "") -> Bool { false }

    // MARK: - Helper
    func canUseBiometrics() -> Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }
}
