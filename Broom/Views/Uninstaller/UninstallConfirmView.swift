import SwiftUI

struct UninstallConfirmView: View {
    let plan: UninstallPlan
    @Binding var moveToTrash: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                AppIconView(icon: plan.app.icon, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Uninstall \(plan.app.name)?")
                        .font(.title3.bold())
                    Text("\(plan.selectedCount) items selected")
                        .foregroundStyle(.secondary)
                    Text(SizeFormatter.format(plan.totalSize))
                        .font(.headline)
                }

                Spacer()
            }

            Toggle("Move files to Trash", isOn: $moveToTrash)

            List(plan.filesToRemove) { file in
                HStack(spacing: 12) {
                    Image(systemName: file.path.pathExtension.lowercased() == "app" ? "app.fill" : "folder.fill")
                        .frame(width: 20)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .lineLimit(1)
                        Text(file.path.path)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }

                    Spacer()

                    SizeLabel(bytes: file.size)
                }
                .padding(.vertical, 2)
            }
            .frame(minHeight: 220)

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(moveToTrash ? "Move to Trash" : "Delete Permanently", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            }
        }
        .padding(20)
        .frame(width: 560)
        .frame(minHeight: 360, idealHeight: 460)
    }
}
