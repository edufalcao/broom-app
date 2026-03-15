import SwiftUI

struct CleaningSettingsView: View {
    @AppStorage("moveToTrash") private var moveToTrash = true
    @AppStorage("skipRunningApps") private var skipRunningApps = true
    @AppStorage("showDeveloperCaches") private var showDeveloperCaches = true
    @AppStorage("scanDSStores") private var scanDSStores = true
    @AppStorage("minTempFileAgeHours") private var minTempFileAgeHours = 24

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
