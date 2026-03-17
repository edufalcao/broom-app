import Foundation

enum UninstallArtifactSource: String, CaseIterable, Sendable {
    case appBundle = "App Bundle"
    case userData = "User Data"
    case preferences = "Preferences"
    case caches = "Caches"
    case webData = "Web Data"
    case savedState = "Saved State"
    case logs = "Logs & Diagnostics"
    case launchItems = "Launch Items"
    case helpers = "Helpers"
    case receipts = "Receipts & System Support"
    case groupContainers = "Group Containers"
    case appScripts = "App Scripts"
}
