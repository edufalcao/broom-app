import AppKit
import SwiftUI

struct AppIconView: View {
    let icon: NSImage?
    var size: CGFloat = 32

    var body: some View {
        if let icon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
        }
    }
}
