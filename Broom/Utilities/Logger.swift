import os

enum Log {
    static let scanner = Logger(subsystem: Constants.bundleIdentifier, category: "scanner")
    static let cleaner = Logger(subsystem: Constants.bundleIdentifier, category: "cleaner")
    static let orphan = Logger(subsystem: Constants.bundleIdentifier, category: "orphan")
    static let uninstaller = Logger(subsystem: Constants.bundleIdentifier, category: "uninstaller")
    static let ui = Logger(subsystem: Constants.bundleIdentifier, category: "ui")
}
