import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                GeneralSettingsView()
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }

                CleaningSettingsView()
                    .tabItem {
                        Label("Cleaning", systemImage: "trash")
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
            .frame(height: 390)

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 560)
    }
}
