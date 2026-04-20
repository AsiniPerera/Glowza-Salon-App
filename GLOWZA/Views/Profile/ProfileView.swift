import SwiftUI
import PhotosUI

// MARK: - ProfileView
struct ProfileView: View {

    @State private var vm = ProfileViewModel()
    @State private var showSignOutAlert   = false
    @State private var showChangePassword = false

    var body: some View {
        let vmBinding = Bindable(vm)

        ZStack(alignment: .top) {

            // ── Background ──
            LinearGradient(
                colors: [Color(hex: "FAF7F2"), Color(hex: "F0E9DF")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── Decorative arc ──
            Circle()
                .stroke(Color(hex: "C4A882").opacity(0.12), lineWidth: 52)
                .frame(width: 380, height: 380)
                .offset(x: -170, y: -210)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ──
                    VStack(spacing: 6) {
                        Text("My Profile")
                            .font(.system(size: 26, weight: .light))
                            .tracking(0.5)
                            .foregroundColor(Color(hex: "2C2420"))
                            .padding(.top, 60)

                        Text("Manage your personal details")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(Color(hex: "8C7B6E"))
                    }
                    .padding(.bottom, 32)

                    // ── Avatar ──
                    avatarRow(vmBinding: vmBinding)
                        .padding(.bottom, 32)

                    // ── Section label ──
                    sectionLabel("Personal Info")

                    // ── Fields ──
                    VStack(spacing: 14) {
                        salonField(icon: "person") {
                            TextField("Full Name", text: vmBinding.fullName)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "2C2420"))
                                .keyboardType(.default)
                        }

                        salonField(icon: "phone") {
                            TextField("Phone Number", text: vmBinding.phone)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "2C2420"))
                                .keyboardType(.phonePad)
                        }

                        salonField(icon: "envelope") {
                            TextField("Email Address", text: vmBinding.email)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "2C2420"))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }

                        // Validation error
                        if let err = vm.validationError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 13))
                                Text(err)
                                    .font(.system(size: 13, weight: .light))
                                Spacer()
                            }
                            .foregroundColor(Color(hex: "C0392B"))
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 28)

                    // ── Save button ──
                    Button(action: {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                        vm.saveProfile()
                    }) {
                        Group {
                            if vm.isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Changes")
                                    .font(.system(size: 16, weight: .medium))
                                    .tracking(0.4)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "C4A882"), Color(hex: "9A6E4A")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color(hex: "B8956A").opacity(0.28), radius: 12, x: 0, y: 5)
                    }
                    .disabled(vm.isSaving)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)

                    // ── Divider ──
                    HStack(spacing: 14) {
                        Rectangle().fill(Color(hex: "E8DDD4")).frame(height: 1)
                        Text("security")
                            .font(.system(size: 11, weight: .light))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "A09080"))
                        Rectangle().fill(Color(hex: "E8DDD4")).frame(height: 1)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)

                    // ── Change Password ──
                    VStack(spacing: 14) {
                        Button(action: { showChangePassword = true }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "F0E6D5"))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "lock.rotation")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(hex: "B8956A"))
                                }
                                Text("Change Password")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "2C2420"))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "C4A882"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: "E0D4C4"), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                        }

                        // ── Sign Out ──
                        Button(action: { showSignOutAlert = true }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "FBE9E8"))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "C0392B"))
                                }
                                Text("Sign Out")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "C0392B"))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "C0392B").opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(hex: "FBE9E8").opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: "C0392B").opacity(0.18), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 60)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // ── Saved Banner ──
            if vm.showSavedBanner {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "B8956A"))
                    Text("Profile saved!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "2C2420"))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 11)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.4), value: vm.showSavedBanner)
        .animation(.spring(response: 0.3), value: vm.validationError)
        .onChange(of: vm.selectedPhotoItem) { _, _ in vm.loadPhotoFromPicker() }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                NotificationCenter.default.post(name: .glowzaSignOut, object: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
        }
    }

    // MARK: - Avatar Row
    private func avatarRow(vmBinding: Bindable<ProfileViewModel>) -> some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let img = vm.avatarImage {
                        img.resizable().scaledToFill()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [Color(hex: "F7F0E6"), Color(hex: "EDE0CE")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            Text(vm.initials)
                                .font(.system(size: 34, weight: .ultraLight, design: .serif))
                                .foregroundColor(Color(hex: "B8956A"))
                        }
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "C4A882"), Color(hex: "9A6E4A")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: Color(hex: "B8956A").opacity(0.20), radius: 10, x: 0, y: 4)

                PhotosPicker(selection: vmBinding.selectedPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "C4A882"), Color(hex: "9A6E4A")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                            .shadow(color: Color(hex: "B8956A").opacity(0.3), radius: 4, x: 0, y: 2)
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 2, y: 2)
            }

            VStack(spacing: 3) {
                Text(vm.fullName.isEmpty ? "Your Name" : vm.fullName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "2C2420"))
                Text(vm.email.isEmpty ? "your@email.com" : vm.email)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "8C7B6E"))
            }
        }
    }

    // MARK: - Section Label
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(1.2)
            .foregroundColor(Color(hex: "A09080"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.bottom, 10)
    }

    // MARK: - Field Builder
    @ViewBuilder
    private func salonField<Content: View>(
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "B8956A").opacity(0.65))
                .frame(width: 20)
            content()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "E0D4C4"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Change Password Sheet
private struct ChangePasswordSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var current  = ""
    @State private var newPwd   = ""
    @State private var confirm  = ""
    @State private var showCurrent = false
    @State private var showNew     = false
    @State private var showConfirm = false
    @State private var errorMsg: String? = nil
    @State private var saved    = false
    @State private var isSaving = false

    var body: some View {
        ZStack {
            // ── Background ──
            LinearGradient(
                colors: [Color(hex: "FAF7F2"), Color(hex: "F0E9DF")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── Decorative arc ──
            Circle()
                .stroke(Color(hex: "C4A882").opacity(0.10), lineWidth: 52)
                .frame(width: 340, height: 340)
                .offset(x: 160, y: -200)

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color(hex: "C4A882").opacity(0.30))
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 28)

                // ── Title ──
                VStack(spacing: 6) {
                    Text("Change Password")
                        .font(.system(size: 24, weight: .light))
                        .tracking(0.5)
                        .foregroundColor(Color(hex: "2C2420"))
                    Text("Choose a strong new password")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "8C7B6E"))
                }
                .padding(.bottom, 32)

                // ── Fields ──
                VStack(spacing: 14) {
                    pwdField("Current Password", icon: "lock",             text: $current,  show: $showCurrent)
                    pwdField("New Password",     icon: "lock.open",        text: $newPwd,   show: $showNew)
                    pwdField("Confirm Password", icon: "checkmark.shield", text: $confirm,  show: $showConfirm)

                    if let err = errorMsg {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                            Text(err)
                                .font(.system(size: 13, weight: .light))
                            Spacer()
                        }
                        .foregroundColor(Color(hex: "C0392B"))
                        .padding(.horizontal, 4)
                        .transition(.opacity)
                    }

                    if saved {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                            Text("Password updated!")
                                .font(.system(size: 13, weight: .light))
                            Spacer()
                        }
                        .foregroundColor(Color(hex: "4A8A6A"))
                        .padding(.horizontal, 4)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 28)

                // ── Update button ──
                Button(action: handleSave) {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Update Password")
                                .font(.system(size: 16, weight: .medium))
                                .tracking(0.4)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "C4A882"), Color(hex: "9A6E4A")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(hex: "B8956A").opacity(0.28), radius: 12, x: 0, y: 5)
                }
                .disabled(isSaving)
                .padding(.horizontal, 28)
                .padding(.top, 28)

                // Cancel
                Button("Cancel") { dismiss() }
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "8C7B6E"))
                    .padding(.top, 18)

                Spacer()
            }
        }
        .animation(.spring(response: 0.3), value: errorMsg)
        .animation(.spring(response: 0.3), value: saved)
    }

    private func pwdField(_ label: String, icon: String, text: Binding<String>, show: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "B8956A").opacity(0.65))
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Color(hex: "8C7B6E"))
                if show.wrappedValue {
                    TextField("", text: text)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "2C2420"))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } else {
                    SecureField("", text: text)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "2C2420"))
                }
            }
            Spacer()
            Button(action: { show.wrappedValue.toggle() }) {
                Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "B8956A").opacity(0.55))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "E0D4C4"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    private func handleSave() {
        errorMsg = nil
        saved    = false
        guard !current.isEmpty  else { errorMsg = "Enter your current password."; return }
        guard newPwd.count >= 8 else { errorMsg = "New password must be at least 8 characters."; return }
        guard newPwd == confirm  else { errorMsg = "Passwords don't match."; return }

        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSaving = false
            saved    = true
            current  = ""
            newPwd   = ""
            confirm  = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        }
    }
}

// MARK: - Sign Out Notification
extension Notification.Name {
    static let glowzaSignOut = Notification.Name("GlowzaSignOut")
}

#Preview {
    ProfileView()
}
