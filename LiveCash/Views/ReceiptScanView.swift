import SwiftUI
import PhotosUI

struct ReceiptScanView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var ocrText = ""
    @State private var draft: ParsedTransactionDraft?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        LiveCashCard {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.largeTitle)
                                    .foregroundStyle(LiveCashTheme.accent)
                                Text("Beleg fotografieren oder aus der Galerie wählen")
                                    .font(LiveCashTheme.bodyFont)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    }

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Bild auswählen", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LiveCashTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if isProcessing {
                        ProgressView("Text wird erkannt…")
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(LiveCashTheme.expense)
                    }

                    if let draft {
                        confirmCard(draft)
                    }

                    if !ocrText.isEmpty {
                        LiveCashCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Erkannter Text")
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                                Text(ocrText)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Beleg scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { await loadImage(from: item) }
            }
        }
    }

    private func confirmCard(_ draft: ParsedTransactionDraft) -> some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Erkannt")
                    .font(LiveCashTheme.headlineFont)
                row("Händler", draft.merchant)
                row("Betrag", String(format: "%.2f€", draft.amount))
                row("Kategorie", draft.category.rawValue)
                row("Datum", draft.date.formatted(date: .abbreviated, time: .omitted))

                Button {
                    let tx = Transaction(
                        amount: draft.amount,
                        type: draft.type,
                        category: draft.category,
                        merchant: draft.merchant,
                        date: draft.date,
                        ocrText: ocrText
                    )
                    store.addTransaction(tx)
                    store.lastFeedback = "Beleg gespeichert: \(draft.merchant)"
                    dismiss()
                } label: {
                    Text("Bestätigen & speichern")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LiveCashTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(LiveCashTheme.bodyFont)
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        isProcessing = true
        errorMessage = nil
        draft = nil
        ocrText = ""

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Bild konnte nicht geladen werden."
                isProcessing = false
                return
            }
            previewImage = image
            let text = try await OCRService.shared.recognizeText(from: image)
            ocrText = text
            draft = SmartInputParser.shared.parseOCRText(text)
            if draft == nil {
                errorMessage = "Kein Betrag im Beleg gefunden."
            }
        } catch {
            errorMessage = "OCR fehlgeschlagen. Bitte manuell eingeben."
        }
        isProcessing = false
    }
}
