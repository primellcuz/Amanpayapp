import SwiftUI

struct SetupPinView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lock: AppLockManager

    @State private var step = 1
    @State private var first = ""
    @State private var confirm = ""
    @State private var error: String?

    @State private var showDisableSheet = false   // ✅

    var body: some View {
        Form {
            Section(header: Text("PIN uzunligi")) {
                Picker("Raqamlar soni", selection: $lock.pinLength) {
                    Text("4 raqam").tag(4 as Int)
                    Text("6 raqam").tag(6 as Int)
                }.pickerStyle(.segmented)
            }

            Section(header: Text(step == 1 ? "Yangi PIN" : "PIN tasdiqlash")) {
                SecureField(step == 1 ? "PIN kiriting" : "Yana bir marta",
                            text: step == 1 ? $first : $confirm)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)     // raqamli klaviatura
                    .onChange(of: first)   { first   = first.filter(\.isNumber) }   // ✅ faqat raqam
                    .onChange(of: confirm){ confirm = confirm.filter(\.isNumber) } // ✅ faqat raqam
            }

            if let error {
                Text(error).foregroundStyle(.red).font(.footnote)
            }

            Section {
                Button(step == 1 ? "Davom etish" : "Saqlash") {
                    if step == 1 {
                        guard first.count == lock.pinLength else {
                            error = "PIN \(lock.pinLength) ta raqamdan iborat bo‘lishi kerak"; return
                        }
                        error = nil; step = 2
                    } else {
                        guard confirm == first else { error = "PIN mos kelmadi"; return }
                        if lock.enablePin(first) {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            lock.lock()                  // ✅ darhol qulflash
                            dismiss()
                        } else {
                            error = "PIN saqlashda xatolik"
                        }
                    }
                }

                if PinStore.shared.exists {
                    Button("PINni o‘chirish", role: .destructive) {
                        showDisableSheet = true       // ✅ joriy PIN so‘raymiz
                    }
                }
            }
        }
        .navigationTitle("PIN-kod")
        .sheet(isPresented: $showDisableSheet) {
            DisablePinSheet { enteredPin in
                if lock.disablePin(current: enteredPin) {   // ✅ server emas, lokal tekshiruv
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    showDisableSheet = false
                    dismiss()
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Joriy PIN ni so‘rash uchun kichik modal
private struct DisablePinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    let onConfirm: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Joriy PIN") {
                    SecureField("PIN kiriting", text: $current)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .onChange(of: current) { current = current.filter(\.isNumber) }
                }
                Section {
                    Button("O‘chirish", role: .destructive) {
                        onConfirm(current)
                    }
                    Button("Bekor qilish", role: .cancel) { dismiss() }
                }
            }
            .navigationTitle("PINni o‘chirish")
        }
        .interactiveDismissDisabled() // tortib yopib bo‘lmasin
    }
}
