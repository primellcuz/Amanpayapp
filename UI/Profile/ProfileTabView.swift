import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var lock: AppLockManager

    @AppStorage("pushEnabled") private var pushEnabled: Bool = true
    @AppStorage("biometricEnabled") private var biometricEnabled: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = "O‘zbek"

    @State private var showLogoutConfirm = false
    @State private var showLanguagePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard

                    HStack(spacing: 12) {
                        NavigationLink { PersonalInfoView(user: session.currentUser) } label: {
                            QuickAction(icon: "person.text.rectangle", title: "Shaxsiy ma’lumotlar")
                        }
                        NavigationLink { CardsPlaceholderView() } label: {
                            QuickAction(icon: "creditcard.fill", title: "To‘lov kartalari")
                        }
                    }
                    .padding(.horizontal, 16)

                    settingsCard
                    supportCard

                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right").imageScale(.medium)
                            Text("Chiqish").font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .padding(.top, 14)
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Chiqishni tasdiqlang", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Ha, chiqish", role: .destructive) {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    session.logout()
                }
                Button("Bekor qilish", role: .cancel) {}
            }
        }
    }

    // MARK: - Header
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AvatarView(
                    initials: initials(
                        first: session.currentUser?.first_name,
                        last: session.currentUser?.last_name,
                        phone: session.currentUser?.phone_number
                    )
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName(
                        first: session.currentUser?.first_name,
                        last: session.currentUser?.last_name,
                        phone: session.currentUser?.phone_number
                    ))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                    if let phone = session.currentUser?.phone_number {
                        Text(formatPhoneE164(phone))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").imageScale(.small)
                Text("Halol nasiya").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color.green)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.green.opacity(0.14))
            .clipShape(Capsule())
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Brand.bgTop.opacity(0.9), Brand.bgBottom.opacity(0.9)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 16)
    }

    // MARK: - Settings
    private var settingsCard: some View {
        VStack(spacing: 0) {
            SectionHeader(text: "Sozlamalar")

            ToggleRow(icon: "faceid", tint: .green, title: "Biometrik qulflov", isOn: Binding(
                get: { lock.biometricEnabled },
                set: { lock.setBiometricEnabled($0) }
            ))
            Divider().padding(.leading, 56)

            NavigationLink {
                SetupPinView().environmentObject(lock)
            } label: {
                Row(icon: "key.horizontal.fill", tint: .blue, title: "PIN-kod",
                    value: PinStore.shared.exists ? "\(lock.pinLength) raqam" : "O‘rnatilmagan")
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 16)
    } // ✅ shu qavs yetishmagan edi

    // MARK: - Support
    private var supportCard: some View {
        VStack(spacing: 0) {
            SectionHeader(text: "Yordam va ma’lumot")

            NavigationLink { HelpView() } label: {
                Row(icon: "questionmark.circle.fill", tint: .gray, title: "Yordam markazi")
            }
            Divider().padding(.leading, 56)

            NavigationLink { AboutView() } label: {
                Row(icon: "info.circle.fill", tint: .teal, title: "Biz haqimizda")
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers
    private func initials(first: String?, last: String?, phone: String?) -> String {
        let f = (first ?? "").trimmingCharacters(in: .whitespaces)
        let l = (last ?? "").trimmingCharacters(in: .whitespaces)
        if !f.isEmpty || !l.isEmpty {
            let i1 = f.first.map { String($0) } ?? ""
            let i2 = l.first.map { String($0) } ?? ""
            return (i1 + i2).uppercased()
        }
        let digits = phone?.filter(\.isNumber) ?? ""
        return digits.suffix(2).isEmpty ? "AP" : String(digits.suffix(2))
    }

    private func displayName(first: String?, last: String?, phone: String?) -> String {
        let f = (first ?? "").trimmingCharacters(in: .whitespaces)
        let l = (last ?? "").trimmingCharacters(in: .whitespaces)
        if !f.isEmpty || !l.isEmpty { return [f, l].filter{ !$0.isEmpty }.joined(separator: " ") }
        return formatPhoneE164(phone ?? "+998")
    }

    private func formatPhoneE164(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count >= 12 else { return phone }
        let cc = "+" + String(digits.prefix(3))
        let n  = String(digits.suffix(9))
        let p1 = String(n.prefix(2))
        let p2 = String(n.dropFirst(2).prefix(3))
        let p3 = String(n.dropFirst(5).prefix(2))
        let p4 = String(n.suffix(2))
        return "\(cc) \(p1) \(p2) \(p3) \(p4)"
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
            .environmentObject(SessionManager())
            .environmentObject(AppLockManager())
    }
    .preferredColorScheme(.light)
}

// MARK: - Reusable UI Pieces (changes not required from your version)
private struct AvatarView: View {
    let initials: String
    var body: some View {
        ZStack {
            Circle().fill(Brand.primary.opacity(0.12))
            Text(initials)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Brand.primary)
        }
        .frame(width: 54, height: 54)
        .overlay(Circle().strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
    }
}

private struct QuickAction: View {
    let icon: String
    let title: String
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6))
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Brand.primary)
            }
            .frame(height: 64)

            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 5)
    }
}

private struct SectionHeader: View {
    let text: String
    var body: some View {
        HStack {
            Text(text).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}

private struct Row: View {
    let icon: String
    let tint: Color
    let title: String
    var value: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.12))
                Image(systemName: icon).foregroundStyle(tint)
            }
            .frame(width: 36, height: 36)

            Text(title).foregroundStyle(.primary)
            Spacer()
            if let value { Text(value).foregroundStyle(.secondary) }
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ToggleRow: View {
    let icon: String
    let tint: Color
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.12))
                Image(systemName: icon).foregroundStyle(tint)
            }
            .frame(width: 36, height: 36)

            Text(title).foregroundStyle(.primary)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ButtonRow: View {
    let icon: String
    let tint: Color
    let title: String
    var value: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Row(icon: icon, tint: tint, title: title, value: value)
        }
    }
}

// MARK: - Stubs
private struct PersonalInfoView: View {
    let user: UserDTO?
    var body: some View {
        Form {
            Section("Foydalanuvchi") {
                Text("Ism: \(user?.first_name ?? "-")")
                Text("Familiya: \(user?.last_name ?? "-")")
                Text("Telefon: \(user?.phone_number ?? "-")")
                Text("Email: \(user?.email ?? "-")")
            }
        }
        .navigationTitle("Shaxsiy ma’lumotlar")
    }
}

private struct CardsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.fill").font(.system(size: 46)).foregroundStyle(.secondary)
            Text("Kartalar bo‘limi tez orada").font(.headline)
            Text("Hozircha tizimga karta qo‘shish yoqilmagan.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("To‘lov kartalari")
    }
}

private struct HelpView: View {
    var body: some View {
        List {
            Section("Tez-tez so‘raladigan savollar") {
                Text("Hisobni qanday yarataman?")
                Text("Parolni qanday almashtiraman?")
                Text("To‘lovda xatolik bo‘lsa nima qilaman?")
            }
            Section("Aloqa") {
                Text("support@amanpay.uz")
                Text("+998 90 123 45 67")
            }
        }
        .navigationTitle("Yordam markazi")
    }
}

private struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AmanPay").font(.title2.bold())
            Text("Qulay • Tez • Halol-nasiya").foregroundStyle(.secondary)
            Divider().padding(.vertical, 8)
            Text("AmanPay — onlayn to‘lov va halol nasiya xizmatlari uchun mobil ilova. Biz foydalanuvchilarga soddalik va xavfsizlikni taqdim etamiz.")
        }
        .padding()
        .navigationTitle("Biz haqimizda")
    }
}
