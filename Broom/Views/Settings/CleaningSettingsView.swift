import SwiftUI

struct CleaningSettingsView: View {
    @AppStorage("moveToTrash") private var moveToTrash = true
    @AppStorage("skipRunningApps") private var skipRunningApps = true
    @AppStorage("showDeveloperCaches") private var showDeveloperCaches = true
    @AppStorage("scanDSStores") private var scanDSStores = true
    @AppStorage("minTempFileAgeHours") private var minTempFileAgeHours = 24

    var body: some View {
        Form {
            Picker("Default delete method:", selection: $moveToTrash) {
                Text("Move to Trash").tag(true)
                Text("Delete permanently").tag(false)
            }

            Toggle("Skip caches for currently running apps", isOn: $skipRunningApps)

            Stepper("Minimum temp file age: \(minTempFileAgeHours)h", value: $minTempFileAgeHours, in: 1...168, step: 6)

            Toggle("Show developer caches (Xcode, npm, pip, etc.)", isOn: $showDeveloperCaches)

            Toggle("Scan .DS_Store files", isOn: $scanDSStores)
        }
        .padding()
    }
}
