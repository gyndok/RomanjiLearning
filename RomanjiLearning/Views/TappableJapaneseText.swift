import SwiftUI
import UIKit

struct TappableJapaneseText: View {
    @Environment(DictionaryService.self) private var dictionaryService
    @Environment(AudioService.self) private var audioService

    let text: String
    let fontSize: CGFloat
    let contextPhrase: String

    @State private var selectedToken: WordToken?
    @State private var showingSystemDictionary = false
    @State private var systemDictionaryWord = ""

    init(text: String, fontSize: CGFloat = 32, contextPhrase: String = "") {
        self.text = text
        self.fontSize = fontSize
        self.contextPhrase = contextPhrase.isEmpty ? text : contextPhrase
    }

    var body: some View {
        let tokens = dictionaryService.tokenize(phrase: text)

        WrappingHStack(alignment: .center, spacing: 2) {
            ForEach(tokens) { token in
                tokenView(token)
            }
        }
        .sheet(item: $selectedToken) { token in
            WordDetailSheet(
                token: token,
                contextPhrase: contextPhrase,
                onSystemLookup: {
                    systemDictionaryWord = token.text
                    selectedToken = nil
                    showingSystemDictionary = true
                },
                onSuggestAddition: {
                    dictionaryService.saveMissedWord(token.text, context: contextPhrase)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSystemDictionary) {
            SystemDictionaryView(term: systemDictionaryWord)
        }
    }

    @ViewBuilder
    private func tokenView(_ token: WordToken) -> some View {
        let isPunctuation = ["。", "、", "？", "！", "「", "」", "『", "』", "（", "）", "・", "〜", "…", " ", "　"].contains(token.text)

        if isPunctuation {
            Text(token.text)
                .font(.japanese(size: fontSize))
                .foregroundStyle(.themeText)
        } else {
            Button {
                selectedToken = token
            } label: {
                Text(token.text)
                    .font(.japanese(size: fontSize))
                    .foregroundStyle(token.isFound ? .themeText : .themeVermillion)
                    .underline(token.isFound, color: .themeSakura.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
    }
}

struct WordDetailSheet: View {
    @Environment(AudioService.self) private var audioService
    @Environment(\.dismiss) private var dismiss

    let token: WordToken
    let contextPhrase: String
    let onSystemLookup: () -> Void
    let onSuggestAddition: () -> Void

    @State private var showSuggestedAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(token.text)
                        .font(.japanese(size: 48))
                        .foregroundStyle(.themeText)
                        .padding(.top, 20)

                    if token.isFound, let reading = token.reading {
                        Text(reading)
                            .font(.romaji(size: 20))
                            .foregroundStyle(.themeTextSecondary)
                    }

                    if token.isFound, let meaning = token.meaning {
                        Text(meaning)
                            .font(.rounded(.title3, weight: .medium))
                            .foregroundStyle(.themeText)
                            .multilineTextAlignment(.center)
                    }

                    if token.isFound, let pos = token.partOfSpeech {
                        Text(pos.capitalized)
                            .font(.smallCapsCategory)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.themeIndigo.opacity(0.1))
                            .foregroundStyle(.themeIndigo)
                            .clipShape(Capsule())
                    }

                    if !token.isFound {
                        VStack(spacing: 12) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 36))
                                .foregroundStyle(.themeTextSecondary)

                            Text("Word not in dictionary")
                                .font(.rounded(.subheadline))
                                .foregroundStyle(.themeTextSecondary)
                        }
                        .padding(.vertical, 10)
                    }

                    Divider()
                        .background(Color.themeSakura.opacity(0.3))
                        .padding(.horizontal, 40)

                    VStack(spacing: 12) {
                        Button {
                            audioService.speak(token.text)
                        } label: {
                            Label("Listen", systemImage: "speaker.wave.2.fill")
                                .font(.rounded(.subheadline, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.themeSakura.opacity(0.15))
                                .foregroundStyle(.themeSakura)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.scale)

                        if !token.isFound || UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: token.text) {
                            Button {
                                onSystemLookup()
                            } label: {
                                Label("Look Up in Dictionary", systemImage: "book.closed")
                                    .font(.rounded(.subheadline, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.themeIndigo.opacity(0.15))
                                    .foregroundStyle(.themeIndigo)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.scale)
                        }

                        if !token.isFound {
                            Button {
                                onSuggestAddition()
                                showSuggestedAlert = true
                            } label: {
                                Label("Suggest Addition", systemImage: "plus.circle")
                                    .font(.rounded(.subheadline, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.themeMatcha.opacity(0.15))
                                    .foregroundStyle(.themeMatcha)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.scale)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Word Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.themeSakura)
                }
            }
            .alert("Suggestion Saved", isPresented: $showSuggestedAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("This word has been saved for future dictionary updates.")
            }
        }
    }
}

struct SystemDictionaryView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}

struct WrappingHStack: Layout {
    var alignment: VerticalAlignment = .center
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity

        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        totalHeight = currentY + lineHeight

        return (CGSize(width: maxX, height: totalHeight), positions)
    }
}
