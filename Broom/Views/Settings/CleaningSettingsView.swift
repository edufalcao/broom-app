import SwiftUI

struct CleaningSettingsView: View {
    @AppStorage("moveToTrash") private var moveToTrash = AppPreferences.defaultMoveToTrash
    @AppStorage("skipRunningApps") private var skipRunningApps = AppPreferences.defaultSkipRunningApps
    @AppStorage("showDeveloperCaches") private var showDeveloperCaches = AppPreferences.defaultShowDeveloperCaches
    @AppStorage("scanDSStores") private var scanDSStores = AppPreferences.defaultScanDSStores
    @AppStorage("minTempFileAgeHours") private var minTempFileAgeHours = AppPreferences.defaultTempFileAgeHours

    private let ageOptions = [1, 6, 12, 24, 48, 168]

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

            Toggle("Show developer caches (Xcode, npm, pip, etc.)", isOn: $showDeveloperCaches)

            Toggle("Scan .DS_Store files", isOn: $scanDSStores)
        }
        .padding()
    }
}
