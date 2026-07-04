import SwiftUI
import PhotosUI

struct ReceiptScanView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var ocrText = ""
    @State private var draft: ParsedTransactionDraft?
    @State private var documentKind: OCRDocumentKind = .receipt
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var savedCount = 0
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if savedCount > 0 {
                        Text("\(savedCount) Dokument(e) gespeichert")
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(LiveCashTheme.accent)
                    }

                    imagePreview

                    HStack(spacing: 12) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Kamera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LiveCashTheme.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Galerie", systemImage: "photo")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LiveCashTheme.cardBackground)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
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
                }
                .padding(20)
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { await loadImage(from: item) }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(source: .camera) { image in
                    Task { await processImage(image) }
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
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
                    Text("Belege, Kontostände oder Dokumente fotografieren")
                        .font(LiveCashTheme.bodyFont)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Text("Mehrere Fotos nacheinander möglich")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    private func confirmCard(_ draft: ParsedTransactionDraft) -> some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(documentKind == .balance ? "Kontostand erkannt" : "Beleg erkannt")
                        .font(LiveCashTheme.headlineFont)
                    Spacer()
                    Text(documentKind == .balance ? "Konto" : "Beleg")
                        .font(LiveCashTheme.captionFont)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LiveCashTheme.accentSoft)
                        .foregroundStyle(LiveCashTheme.accent)
                        .clipShape(Capsule())
                }

                row("Händler", draft.merchant)
                row("Betrag", String(format: "%.2f€", draft.amount))
                row("Kategorie", draft.category.rawValue)
                row("Datum", draft.date.formatted(date: .abbreviated, time: .omitted))

                Button { saveDraft(draft) } label: {
                    Text("Bestätigen & speichern")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LiveCashTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    resetForNextScan()
                } label: {
                    Text("Verwerfen")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
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

    private func saveDraft(_ draft: ParsedTransactionDraft) {
        let tx = Transaction(
            amount: draft.amount,
            type: draft.type,
            category: draft.category,
            merchant: draft.merchant,
            date: draft.date,
            ocrText: ocrText
        )
        store.addTransaction(tx)
        savedCount += 1
        store.lastFeedback = documentKind == .balance
            ? "Kontostand gespeichert: \(draft.merchant)"
            : "Beleg gespeichert: \(draft.merchant)"
        resetForNextScan()
        showCamera = true
    }

    private func resetForNextScan() {
        previewImage = nil
        draft = nil
        ocrText = ""
        errorMessage = nil
        pickerItem = nil
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Bild konnte nicht geladen werden."
                return
            }
            await processImage(image)
        } catch {
            errorMessage = "Bild konnte nicht geladen werden."
        }
    }

    private func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        draft = nil
        previewImage = image

        do {
            let text = try await OCRService.shared.recognizeText(from: image)
            ocrText = text
            documentKind = SmartInputParser.shared.detectDocumentKind(text)

            if documentKind == .balance {
                draft = SmartInputParser.shared.parseBalanceText(text)
            } else {
                draft = SmartInputParser.shared.parseOCRText(text)
            }

            if draft == nil {
                errorMessage = documentKind == .balance
                    ? "Kein Kontostand erkannt."
                    : "Kein Betrag gefunden — bitte manuell eingeben."
            }
        } catch {
            errorMessage = "OCR fehlgeschlagen."
        }
        isProcessing = false
    }
}
