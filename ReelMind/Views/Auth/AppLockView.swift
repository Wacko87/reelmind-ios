import SwiftUI

public struct AppLockView: View {
    @Bindable var lockService = AppLockService.shared

    public init() {}

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 110, height: 110)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 8) {
                    Text("ReelMind Vault Locked")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("Authentication is required to view your saved reels, prompts, and AI knowledge.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let error = lockService.authenticationError {
                    VStack(spacing: 8) {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        if lockService.isPermissionDenied {
                            Button {
                                lockService.openSystemSettings()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "gearshape.fill")
                                    Text("Abrir Ajustes de iOS")
                                }
                                .font(.footnote.bold())
                                .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task {
                            await lockService.authenticate()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "faceid")
                                .font(.title3)
                            Text("Unlock Vault")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .clipShape(.rect(cornerRadius: 14))
                    }

                    if lockService.isPermissionDenied {
                        Button("Desactivar bloqueo Face ID") {
                            lockService.emergencyUnlock()
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .task {
            await lockService.authenticate()
        }
    }
}
