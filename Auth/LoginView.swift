import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionManager

    @State private var uzDigits: String = ""      // 0–9, uzunligi 9
    @State private var password: String = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorText: String?

    @FocusState private var focused: Field?
    private enum Field { case phone, password }

    private var phoneE164: String { "+998" + uzDigits }
    private var phoneValid: Bool { uzDigits.count == 9 }
    private var passValid: Bool { password.count >= 8 }
    private var canSubmit: Bool { phoneValid && passValid && !isLoading }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [Brand.secondary.opacity(0.22), .clear],
                                                     center: .center, startRadius: 6, endRadius: 120))
                                .frame(width: 160, height: 160)
                                .blur(radius: 22)

                            Image(systemName: "creditcard.fill")
                                .resizable().scaledToFit()
                                .frame(width: 62, height: 62)
                                .foregroundStyle(Brand.primary)
                                .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)
                        }

                        Text("Kirish")
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .foregroundStyle(Brand.ink)
                    }
                    .padding(.top, 36)

                    // Forma kartasi
                    VStack(spacing: 18) {

                        // Telefon — +998 prefiks + maskali kiritish
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Telefon raqam")
                                .font(.footnote).foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Text("+998")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                // 👇 Endi bu yerda faqat raqam va 9 ta limit
                                MaskedUZPhoneField(digits: $uzDigits)
                                    .focused($focused, equals: .phone)
                                    .frame(height: 22)
                                    .submitLabel(.next)
                                    .onSubmit { focused = .password }
                            }
                            .padding(.horizontal, 2)
                            .overlay(alignment: .trailing) {
                                Image(systemName: phoneValid ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(phoneValid ? .green : .secondary.opacity(0.4))
                                    .padding(.trailing, 8)
                            }
                        }

                        // Parol
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parol (kamida 8 belgi)")
                                .font(.footnote).foregroundStyle(.secondary)

                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Parolingiz", text: $password)
                                            .textContentType(.password)
                                            .focused($focused, equals: .password)
                                    } else {
                                        SecureField("Parolingiz", text: $password)
                                            .textContentType(.password)
                                            .focused($focused, equals: .password)
                                    }
                                }
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) { showPassword.toggle() }
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .imageScale(.medium)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityLabel(showPassword ? "Parolni yashirish" : "Parolni ko‘rsatish")
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        if let err = errorText {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Kirish
                        Button {
                            Task {
                                hideKeyboard()
                                errorText = nil
                                isLoading = true
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                let e = await session.login(phone: phoneE164, password: password)
                                errorText = e
                                isLoading = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isLoading { ProgressView().tint(.white) }
                                Text("Kirish")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSubmit ? Brand.primary : Color(.systemGray3))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Brand.primary.opacity(canSubmit ? 0.25 : 0.0), radius: 12, x: 0, y: 8)
                        }
                        .disabled(!canSubmit)

                        HStack {
                            NavigationLink("Ro‘yxatdan o‘tish") { RegisterView() }
                            Spacer()
                            Button("Parolni unutdingizmi?") { /* TODO */ }
                        }
                        .font(.footnote.weight(.semibold))
                        .tint(Brand.primary)
                        .padding(.top, 2)
                    }
                    .padding(20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                                   startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    )

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Yopish") { hideKeyboard() }
                Spacer()
                if focused == .phone { Button("Keyingi") { focused = .password } }
            }
        }
    }

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
    }
}

#Preview {
    NavigationStack {
        LoginView().environmentObject(SessionManager())
    }
    .preferredColorScheme(.light)
}
