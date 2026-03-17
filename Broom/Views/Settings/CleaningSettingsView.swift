import SwiftUI

struct CleaningSettingsView: View {
    @AppStorage("moveToTrash") private var moveToTrash = AppPreferences.defaultMoveToTrash
    @AppStorage("skipRunningApps") private var skipRunningApps = AppPreferences.defaultSkipRunningApps
    @AppStorage("showDeveloperCaches") private var showDeveloperCaches = AppPreferences.defaultShowDeveloperCaches
    @AppStorage("scanDSStores") private var scanDSStores = AppPreferences.defaultScanDSStores
    @AppStorage("minTempFileAgeHours") private var minTempFileAgeHours = AppPreferences.defaultTempFileAgeHours
    @AppStorage("orphanStaleAgeDays") private var orphanStaleAgeDays = AppPreferences.defaultOrphanStaleAgeDays

    private let ageOptions = [1, 6, 12, 24, 48, 168]
    private let orphanAgeOptions = [7, 14, 30, 60, 90]

    var body: some View {
        Form {
            Picker("Default delete method:", selection: $moveToTrash) {
                Text("Move to Trash").tag(true)
                Text("Delete permanently").tag(false)
            }

            Toggle("Skip caches for currently running apps", isOn: $skipRunningApps)

            Picker("Minimum temp file age:", selection: $minTempFileAgeHours) {
                ForEach(ageOptions, id: \.self) { hours in
                    Text(hours < 24 ? "\(hours)h" : "\(hours / 24)d").tag(hours)
                }
            }

            Picker("Minimum leftover age:", selection: $orphanStaleAgeDays) {
                ForEach(orphanAgeOptions, id: \.self) { days in
                    Text("\(days) days").tag(days)
                }
            }
            Text("Only show leftovers older than this")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Show developer caches (Xcode, npm, pip, etc.)", isOn: $showDeveloperCaches)

            Toggle("Scan .DS_Store files", isOn: $scanDSStores)
        }
        .padding()
    }
}
