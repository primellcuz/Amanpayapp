import Foundation
import Combine
import LocalAuthentication

final class AppLockManager: ObservableObject {
    static let shared = AppLockManager()

    @Published var isLocked: Bool = false
    @Published var pinLength: Int = 4

    @Published var biometricAvailable: Bool = false
    @Published var biometricEnabled: Bool = UserDefaults.standard.bool(forKey: "biometricEnabled")

    private var cancellables = Set<AnyCancellable>()

    init() {
        biometricAvailable = canUseBiometrics()
        // App startida PIN bo‘lsa yoki biometrik yoqilgan bo‘lsa lock
        isLocked = PinStore.shared.exists || biometricEnabled
        // AppStorage bilan sync:
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.biometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
            }.store(in: &cancellables)
    }

    // MARK: - PIN
    func enablePin(_ newPin: String) -> Bool {
        guard newPin.count == pinLength else { return false }
        let ok = PinStore.shared.save(pin: newPin)
        if ok { isLocked = true } // keyingi safar lock
        return ok
    }
    func changePin(old: String, new: String) -> Bool {
        guard PinStore.shared.verify(pin: old) else { return false }
        return enablePin(new)
    }
    func disablePin(current: String) -> Bool {
        guard PinStore.shared.verify(pin: current) else { return false }
        PinStore.shared.clear()
        // Agar biometric ham o‘chiq bo‘lsa — lock shart emas
        isLocked = biometricEnabled
        return true
    }

    func unlockWithPin(_ pin: String) -> Bool {
        let ok = PinStore.shared.verify(pin: pin)
        if ok { isLocked = false }
        return ok
    }

    func lock() { isLocked = true }

    // MARK: - Biometrics
    func setBiometricEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: "biometricEnabled")
        biometricEnabled = on
        if on { isLocked = true }
    }

    @discardableResult
    func unlockWithBiometrics(reason: String = "AmanPay ni ochish uchun Face ID/Touch ID") -> Bool {
        guard biometricEnabled else { return false }
        let ctx = LAContext()
        var err: NSError?
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        guard ctx.canEvaluatePolicy(policy, error: &err) else { return false }

        var success = false
        let sem = DispatchSemaphore(value: 0)
        ctx.evaluatePolicy(policy, localizedReason: reason) { ok, _ in
            success = ok
            sem.signal()
        }
        sem.wait()
        if success { isLocked = false }
        return success
    }

    func canUseBiometrics() -> Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }
}

