import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var bfsiStore: BFSIStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Accounts", systemImage: "house.fill") }

            NavigationStack { TransferView() }
                .tabItem { Label("Transfer", systemImage: "arrow.left.arrow.right") }

            NavigationStack { BFSIApplePayView() }
                .tabItem { Label("Pay", systemImage: "apple.logo") }

            NavigationStack { BFSIKYCView() }
                .tabItem { Label("KYC", systemImage: "person.badge.shield.checkmark.fill") }

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.indigo)

        .overlay(alignment: .top) {
            if let msg = bfsiStore.networkStatusMessage {
                NetworkBanner(message: msg, isOnline: bfsiStore.isOnline)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.4), value: bfsiStore.networkStatusMessage)
                    .zIndex(999)
            }
        }
    }
}

// MARK: - Network banner

struct NetworkBanner: View {
    let message: String
    let isOnline: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isOnline ? "wifi" : "wifi.slash")
                .accessibilityHidden(true)
            Text(message).font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(isOnline ? Color.green : Color.red)
    }
}

#Preview {
    RootTabView()
        .environmentObject(SessionStore())
        .environmentObject(BFSIStore())
}
