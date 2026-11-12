import SwiftUI
import Combine

/// Wraps the BFSI Login/Dashboard/Transfer/Scanner/Profile flow so it
/// can be pushed from the domain selection screen.
struct BFSIEntryView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        Group {
            if session.isLoggedIn && session.bfsiOTPVerified {
                RootTabView()
                    .toolbar(.hidden, for: .navigationBar)
            } else if session.isLoggedIn && !session.bfsiOTPVerified {
                OTPVerificationView(title: "DemoBank", tint: .indigo, icon: "building.columns.fill") {
                    session.bfsiOTPVerified = true
                }
            } else {
                LoginView()
            }
        }
        .navigationTitle("BFSI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
