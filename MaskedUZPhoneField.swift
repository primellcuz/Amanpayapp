import SwiftUI
import UIKit

struct MaskedUZPhoneField: UIViewRepresentable {
    @Binding var digits: String            // 0–9, uzunligi 9
    var placeholder: String = "90 123 45 67"

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        tf.placeholder = placeholder
        tf.text = format(digits)
        tf.delegate = context.coordinator     // <- delegate orqali bloklaymiz
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        let f = format(digits)
        if uiView.text != f { uiView.text = f }
    }

    func makeCoordinator() -> Coordinator { Coordinator(digits: $digits) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var digits: String
        init(digits: Binding<String>) { _digits = digits }

        // Harf kiritishni bloklash, 9 ta raqamga cheklash va formatlash
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let r = Range(range, in: current) else { return false }
            let updated = current.replacingCharacters(in: r, with: string)

            // Faqat raqamlar, maksimal 9 ta
            let raw = updated.filter(\.isNumber)
            let newDigits = String(raw.prefix(9))

            // Binding va ko‘rinishni yangilash
            digits = newDigits
            textField.text = format(newDigits)

            return false // o‘zimiz qo‘lda yangiladik
        }
    }
}

// "## ### ## ##" -> "90 123 45 67"
private func format(_ digits: String) -> String {
    let d = digits.filter(\.isNumber)
    let a = d.prefix(2)
    let b = d.dropFirst(2).prefix(3)
    let c = d.dropFirst(5).prefix(2)
    let e = d.dropFirst(7).prefix(2)
    return [a, b, c, e].map { String($0) }.filter { !$0.isEmpty }.joined(separator: " ")
}
