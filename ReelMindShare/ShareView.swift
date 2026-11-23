import SwiftUI

public struct ShareView: View {
    public let urlString: String
    public let onDismiss: () -> Void
    public let onSubmit: (String) async -> Result<String, Error>

    @State private var isSubmitting = false
    @State private var statusMessage: String? = nil
    @State private var isSuccess = false

    public init(
        urlString: String,
        onDismiss: @escaping () -> Void,
        onSubmit: @escaping (String) async -> Result<String, Error>
    ) {
        self.urlString = urlString
        self.onDismiss = onDismiss
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("ReelMind")
                        .font(.headline.bold())
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Dismiss share sheet")
            }

            Divider()

            // Shared URL Preview
            VStack(alignment: .leading, spacing: 6) {
                Text("Content to Analyze:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.purple)
                    Text(urlString.isEmpty ? "Detecting shared URL..." : urlString)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 10))
            }

            if let message = statusMessage {
                HStack(spacing: 6) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isSuccess ? .green : .red)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(isSuccess ? .green : .red)
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel", action: onDismiss)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 12))

                Button {
                    Task {
                        isSubmitting = true
                        statusMessage = nil
                        let result = await onSubmit(urlString)
                        switch result {
                        case .success(let title):
                            isSuccess = true
                            statusMessage = "Saved: \(title)"
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            onDismiss()
                        case .failure(let error):
                            isSuccess = false
                            statusMessage = error.localizedDescription
                        }
                        isSubmitting = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isSubmitting ? "Ingesting..." : "Save to Vault")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(urlString.isEmpty || isSubmitting ? Color.gray : Color.purple)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .disabled(urlString.isEmpty || isSubmitting)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(.horizontal, 20)
    }
}
