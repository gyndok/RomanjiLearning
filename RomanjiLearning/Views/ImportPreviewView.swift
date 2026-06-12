import SwiftUI

struct ImportPreviewView: View {
    @Environment(ImportExportService.self) private var importService
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    if !importService.parseErrors.isEmpty || importService.duplicateCount > 0 {
                        warningsSection
                    }
                    if !importService.parsedPhrases.isEmpty {
                        previewSection
                    }
                }
                .padding()
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        importService.reset()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importService.confirmImport(into: phraseManager)
                        dismiss()
                    }
                    .disabled(importService.parsedPhrases.isEmpty)
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.themeIndigo)

            Text("\(importService.parsedPhrases.count) Phrase\(importService.parsedPhrases.count == 1 ? "" : "s") Ready")
                .font(.rounded(.title3, weight: .semibold))
                .foregroundStyle(.themeText)

            Text("These phrases will be added to your library.")
                .font(.rounded(.subheadline))
                .foregroundStyle(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .themeCard(cornerRadius: 14)
    }

    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(.themeVermillion)

            if importService.duplicateCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(.themeVermillion)
                    Text("\(importService.duplicateCount) duplicate\(importService.duplicateCount == 1 ? "" : "s") will be skipped")
                        .font(.rounded(.subheadline))
                        .foregroundStyle(.themeText)
                }
            }

            ForEach(importService.parseErrors.prefix(3), id: \.self) { error in
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(.themeVermillion)
                    Text(error)
                        .font(.rounded(.caption))
                        .foregroundStyle(.themeTextSecondary)
                }
            }

            if importService.parseErrors.count > 3 {
                Text("... and \(importService.parseErrors.count - 3) more error\(importService.parseErrors.count - 3 == 1 ? "" : "s")")
                    .font(.rounded(.caption))
                    .foregroundStyle(.themeTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.themeVermillion.opacity(0.08))
        )
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(.themeTextSecondary)

            ForEach(importService.parsedPhrases.prefix(5)) { phrase in
                phraseRow(phrase)
            }

            if importService.parsedPhrases.count > 5 {
                Text("... and \(importService.parsedPhrases.count - 5) more")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.themeTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }

    private func phraseRow(_ phrase: Phrase) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(phrase.english)
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(.themeText)

            Text(phrase.japanese)
                .font(.japanese(size: 15))
                .foregroundStyle(.themeIndigo)

            if !phrase.romaji.isEmpty {
                Text(phrase.romaji)
                    .font(.romaji(size: 13))
                    .foregroundStyle(.themeTextSecondary)
            }

            HStack(spacing: 8) {
                Text(phrase.category)
                    .font(.rounded(.caption))
                    .foregroundStyle(.themeSakura)

                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= phrase.difficulty ? Color.themeIndigo : Color.themeIndigo.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .themeCard(cornerRadius: 10, shadowRadius: 4, shadowY: 2)
    }
}
