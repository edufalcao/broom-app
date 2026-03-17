import SwiftUI

struct ConfidenceBadge: View {
    let confidence: OrphanConfidence

    private var icon: String {
        switch confidence {
        case .high: return "checkmark.circle.fill"
        case .medium: return "circle.fill"
        case .low: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch confidence {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .orange
        }
    }

    private var label: String {
        switch confidence {
        case .high: return "Safe to remove"
        case .medium: return "Likely orphaned"
        case .low: return "Review before removing"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(color)
        .accessibilityLabel("Confidence: \(label)")
    }
}
