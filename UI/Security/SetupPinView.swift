import SwiftUI

struct SetupPinView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lock: AppLockManager

    @State private var step = 1
    @State private var first = ""
    @State private var confirm = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section(header: Text("PIN uzunligi")) {
                Picker("Raqamlar soni", selection: $lock.pinLength) {
                    Text("4 raqam").tag(4)
                    Text("6 raqam").tag(6)
                }.pickerStyle(.segmented)
            }

            Section(header: Text(step == 1 ? "Yangi PIN" : "PIN tasdiqlash")) {
                SecureField(step == 1 ? "PIN kiriting" : "Yana bir marta", text: step == 1 ? $first : $confirm)
                    .keyboardType(.numberPad)
            }

            if let error {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Section {
                Button(step == 1 ? "Davom etish" : "Saqlash") {
                    if step == 1 {
                        guard first.count == lock.pinLength, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: first)) else {
                            error = "PIN \(lock.pinLength) ta raqamdan iborat bo‘lishi kerak"; return
                        }
                        error = nil; step = 2
                    } else {
                        guard confirm == first else { error = "PIN mos kelmadi"; return }
                        if lock.enablePin(first) {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            dismiss()
                        } else {
                            error = "PIN saqlashda xatolik"
                        }
                    }
                }
                if PinStore.shared.exists {
                    Button("PINni o‘chirish", role: .destructive) {
                        // xavfsizlik uchun joriy PIN so‘ralishi mumkin — qisqartma:
                        PinStore.shared.clear()
                        lock.isLocked = lock.biometricEnabled
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("PIN-kod")
    }
}
