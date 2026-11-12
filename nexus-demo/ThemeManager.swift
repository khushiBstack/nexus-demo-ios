import SwiftUI
import UIKit
import Combine

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "appIsDarkMode")
        }
    }

    @Published var showShakeToast: Bool = false
    private var toastTask: Task<Void, Never>?

    private init() {
        isDarkMode = UserDefaults.standard.bool(forKey: "appIsDarkMode")
    }

    func toggle() {
        isDarkMode.toggle()
        triggerToast()
    }

    private func triggerToast() {
        toastTask?.cancel()
        showShakeToast = true
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showShakeToast = false
        }
    }
}

// MARK: - Shake detection

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

// MARK: - ShakeDetectingWindow
// UIWindow subclass that intercepts motionEnded at the window level.
// Works regardless of which view controller is currently active.

final class ShakeDetectingWindow: UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

// MARK: - ShakeWindowInstaller
// Patches the existing SwiftUI-managed window by swizzling its class to
// ShakeDetectingWindow. No rootViewController transfer needed — the window
// already has one; we just change how it handles motion events.

enum ShakeWindowInstaller {
    static func install() {
        // Toggle theme on shake
        NotificationCenter.default.addObserver(
            forName: .deviceDidShake,
            object: nil,
            queue: .main
        ) { _ in ThemeManager.shared.toggle() }

        // Re-patch whenever a window becomes key (covers domain navigation)
        NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { _ in ShakeWindowInstaller.patchAllWindows() }

        // Initial patches — staggered to cover slow SwiftUI window setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { patchAllWindows() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { patchAllWindows() }
    }

    static func patchAllWindows() {
        // Intentionally empty. Swapping a live window's class with object_setClass
        // crashes on newer iOS/iPadOS (-[ShakeDetectingWindow priorityLevel]:
        // unrecognized selector), because UIKit's real window class has members
        // the subclass lacks. Shake is now detected by ShakeDetectorView, which is
        // attached through SwiftUI (see .onShake()).
    }
}

// MARK: - Shake detection without swizzling

/// Invisible first-responder view that reports shake gestures.
final class ShakeResponderView: UIView {
    override var canBecomeFirstResponder: Bool { true }

    private var observers: [NSObjectProtocol] = []

    override func didMoveToWindow() {
        super.didMoveToWindow()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
        guard window != nil else { return }
        becomeFirstResponder()
        // Re-claim first responder whenever focus may have been lost
        // (sheet dismissed, keyboard closed, app re-activated, window became key).
        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIWindow.didBecomeKeyNotification,
            UIResponder.keyboardDidHideNotification
        ]
        for name in names {
            let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                guard let self, self.window != nil, !self.isFirstResponder else { return }
                self.becomeFirstResponder()
            }
            observers.append(token)
        }
    }

    deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

struct ShakeDetectorView: UIViewRepresentable {
    func makeUIView(context: Context) -> ShakeResponderView {
        let v = ShakeResponderView()
        v.isUserInteractionEnabled = false
        v.isAccessibilityElement = false
        return v
    }
    func updateUIView(_ uiView: ShakeResponderView, context: Context) {
        if uiView.window != nil, !uiView.isFirstResponder { uiView.becomeFirstResponder() }
    }
}

extension View {
    /// Attach once at the app root to receive `.deviceDidShake` notifications.
    func shakeDetector() -> some View {
        background(ShakeDetectorView().allowsHitTesting(false).accessibilityHidden(true))
    }
}

// MARK: - Readable width on iPad

/// Caps content width on regular-width devices (iPad) and centres it.
/// No effect on iPhone (compact width). Safe to apply to a screen root.
struct ReadableWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSize
    var maxWidth: CGFloat = 700

    func body(content: Content) -> some View {
        if hSize == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

extension View {
    func readableWidth(_ maxWidth: CGFloat = 700) -> some View {
        modifier(ReadableWidthModifier(maxWidth: maxWidth))
    }
}

// MARK: - Toast overlay view

struct ShakeThemeToast: View {
    let isDarkMode: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                .foregroundStyle(isDarkMode ? .yellow : .orange)
                .accessibilityHidden(true)
            Text(isDarkMode ? "Dark Mode On" : "Light Mode On")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .accessibilityLabel(isDarkMode ? "Dark mode enabled" : "Light mode enabled")
        .accessibilityIdentifier("shakeThemeToast")
    }
}
