import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            CleaningSettingsView()
                .tabItem {
                    Label("Cleaning", systemImage: "trash")
                }

            ProjectsSettingsView()
                .tabItem {
                    Label("Projects", systemImage: "archivebox")
                }

            SafeListSettingsView()
                .tabItem {
                    Label("Safe List", systemImage: "shield")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 400)
    }
}
