import Foundation

/// Provisional protected data policy (Phase 2).
/// Identifies data families that should NEVER appear in generic orphan results
/// because accidental deletion could cause data loss or security issues.
/// Will be promoted to a full policy in Phase 5.
enum ProtectedDataPolicy {

    // MARK: - Protected Bundle ID Prefixes

    /// Bundle ID prefixes for apps whose leftover data should never be flagged.
    static let protectedBundleIDPrefixes: [String] = [
        // Password managers
        "com.agilebits.onepassword",
        "com.lastpass.",
        "com.bitwarden.",
        "com.8bit.bitwarden",
        "org.keepassxc.",
        "com.keepassx.",
        "com.dashlane.",
        "com.enpass.",
        "com.roboform.",

        // VPN / proxy tools
        "net.mullvad.vpn",
        "com.nordvpn.",
        "com.expressvpn.",
        "com.wireguard.",
        "io.tailscale.",
        "com.privateinternetaccess.",
        "com.surfshark.",
        "com.protonvpn.",

        // Browsers (data stores — cookies, history, etc.)
        "com.apple.safari",
        "com.google.chrome",
        "org.mozilla.firefox",
        "org.mozilla.thunderbird",
        "company.thebrowser.browser",
        "com.brave.browser",
        "com.microsoft.edgemac",
        "com.operasoftware.opera",
        "com.vivaldi.vivaldi",

        // AI model / assistant data
        "com.openai.chatgpt",
        "com.anthropic.claude",
        "com.github.copilot",
        "com.lmstudio.",
        "com.ollama.",

        // iCloud-synced data
        "com.apple.icloud",
        "com.apple.mobilesync",
        "com.apple.cloudd",
        "com.apple.bird",

        // Automation / scripting tools
        "com.stairways.keyboardmaestro",
        "com.runningwithcrayons.alfred",
        "com.raycast.",
        "org.hammerspoon.",
        "com.hegenberg.bettertouchtool",
        "com.knollsoft.rectangle",
        "com.pqrs.karabiner",
        "net.sourceforge.skim-app.",
    ]

    // MARK: - Protected Path Components

    /// Path components that indicate protected data families.
    /// If any component of a candidate path matches one of these (case-insensitive),
    /// the candidate should be suppressed.
    static let protectedPathComponents: [String] = [
        // Password managers
        "1password",
        "onepassword",
        "lastpass",
        "bitwarden",
        "keepass",
        "keepassxc",
        "dashlane",
        "enpass",

        // VPN / proxy
        "mullvadvpn",
        "mullvad vpn",
        "nordvpn",
        "expressvpn",
        "wireguard",
        "tailscale",

        // iCloud-synced data
        "com.apple.icloud",
        "mobilesync",

        // AI model data
        "ollama",

        // Automation
        "keyboard maestro",
        "keyboardmaestro",
    ]

    // MARK: - Public API

    /// Returns `true` if the given bundle ID belongs to a protected data family.
    static func isProtected(bundleID: String) -> Bool {
        let lowered = bundleID.lowercased()
        return protectedBundleIDPrefixes.contains { lowered.hasPrefix($0) }
    }

    /// Returns `true` if the given path contains a component belonging to a protected data family.
    static func isProtected(path: URL) -> Bool {
        let loweredPath = path.path.lowercased()

        // Check path component matches
        for component in protectedPathComponents {
            if loweredPath.contains(component) {
                return true
            }
        }

        // Also check if the last path component (directory name) matches a protected bundle prefix
        let name = path.lastPathComponent.lowercased()
        return protectedBundleIDPrefixes.contains { name.hasPrefix($0) }
    }
}
