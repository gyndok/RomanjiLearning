import SwiftUI

struct ImportResultView: View {
    @Environment(ImportExportService.self) private var importService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.themeMatcha.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.themeMatcha)
                }

                Text("Import Complete")
                    .font(.rounded(.title2, weight: .semibold))
                    .foregroundStyle(.themeText)

                if let result = importService.importResult {
                    VStack(spacing: 12) {
                        resultRow(
                            icon: "plus.circle.fill",
                            label: "Phrases Imported",
                            value: "\(result.importedCount)",
                            color: .themeMatcha
                        )

                        if result.duplicateCount > 0 {
                            resultRow(
                                icon: "arrow.triangle.2.circlepath",
                                label: "Duplicates Skipped",
                                value: "\(result.duplicateCount)",
                                color: .themeVermillion
                            )
                        }

                        if result.errorCount > 0 {
                            resultRow(
                                icon: "exclamationmark.triangle.fill",
                                label: "Rows with Errors",
                                value: "\(result.errorCount)",
                                color: .themeVermillion
                            )
                        }
                    }
                    .padding()
                    .themeCard(cornerRadius: 14)
                }

                Spacer()

                Button {
                    importService.reset()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.rounded(.headline, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.sakuraIndigo)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.scale)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func resultRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.rounded(.body))
                .foregroundStyle(.themeText)

            Spacer()

            Text(value)
                .font(.rounded(.body, weight: .semibold))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }
}
