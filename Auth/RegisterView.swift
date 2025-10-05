import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var session: SessionManager

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var uzDigits  = ""      // 0–9, uzunligi 9
    @State private var password  = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorText: String?

    @FocusState private var focused: Field?
    private enum Field { case first, last, phone, password }

    private var phoneE164: String { "+998" + uzDigits }
    private var phoneValid: Bool { uzDigits.count == 9 }
    private var passValid: Bool { password.count >= 8 }
    private var nameValid: Bool { firstName.trimmingCharacters(in: .whitespaces).count >= 2 &&
                                  lastName.trimmingCharacters(in: .whitespaces).count  >= 2 }
    private var canSubmit: Bool { nameValid && phoneValid && passValid && !isLoading }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.bgTop, Brand.bgBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [Brand.secondary.opacity(0.22), .clear],
                                                     center: .center, startRadius: 6, endRadius: 120))
                                .frame(width: 140, height: 140)
                                .blur(radius: 18)

                            Image(systemName: "person.crop.circle.badge.plus")
                                .resizable().scaledToFit()
                                .frame(width: 58, height: 58)
                                .foregroundStyle(Brand.primary)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 6)
                        }
                        Text("Ro‘yxatdan o‘tish")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(Brand.ink)
                    }
                    .padding(.top, 36)

                    // Forma karta
                    VStack(spacing: 16) {

                        // Ism
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ism").font(.footnote).foregroundStyle(.secondary)
                            TextField("Ali", text: $firstName)
                                .textContentType(.givenName)
                                .focused($focused, equals: .first)
                                .submitLabel(.next)
                                .onSubmit { focused = .last }
                                .padding(.vertical, 12).padding(.horizontal, 14)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Familiya
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Familiya").font(.footnote).foregroundStyle(.secondary)
                            TextField("Valiyev", text: $lastName)
                                .textContentType(.familyName)
                                .focused($focused, equals: .last)
                                .submitLabel(.next)
                                .onSubmit { focused = .phone }
                                .padding(.vertical, 12).padding(.horizontal, 14)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Telefon — +998 prefiks + maska
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Telefon raqam").font(.footnote).foregroundStyle(.secondary)
                            HStack(spacing: 10) {
                                Text("+998")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                MaskedUZPhoneField(digits: $uzDigits)
                                    .focused($focused, equals: .phone)
                                    .frame(height: 22)
                                    .submitLabel(.next)
                                    .onSubmit { focused = .password }
                            }
                            .overlay(alignment: .trailing) {
                                Image(systemName: phoneValid ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(phoneValid ? .green : .secondary.opacity(0.4))
                                    .padding(.trailing, 8)
                            }
                        }

                        // Parol
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parol (kamida 8 belgi)").font(.footnote).foregroundStyle(.secondary)
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Parolingiz", text: $password)
                                            .textContentType(.newPassword)
                                            .focused($focused, equals: .password)
                                    } else {
                                        SecureField("Parolingiz", text: $password)
                                            .textContentType(.newPassword)
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

                        // Ro‘yxatdan o‘tish tugmasi
                        Button {
                            Task {
                                hideKeyboard()
                                errorText = nil
                                isLoading = true
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                let err = await session.register(
                                    phone: phoneE164,
                                    first: firstName.trimmingCharacters(in: .whitespaces),
                                    last:  lastName.trimmingCharacters(in: .whitespaces),
                                    password: password
                                )
                                errorText = err
                                isLoading = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isLoading { ProgressView().tint(.white) }
                                Text("Ro‘yxatdan o‘tish")
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
                    }
                    .padding(20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 12)

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
                switch focused {
                case .first: Button("Keyingi") { focused = .last }
                case .last:  Button("Keyingi") { focused = .phone }
                case .phone: Button("Keyingi") { focused = .password }
                default: EmptyView()
                }
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
        RegisterView()
            .environmentObject(SessionManager())
    }
    .preferredColorScheme(.light)
}
