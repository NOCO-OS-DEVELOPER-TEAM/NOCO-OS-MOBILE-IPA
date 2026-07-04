import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

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
    @State private var showFileImporter = false

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

                    Button {
                        showFileImporter = true
                    } label: {
                        Label("Datei (PDF, Text)", systemImage: "doc.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LiveCashTheme.cardBackground)
                            .foregroundStyle(.primary)
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
            .onAppear {
                if let image = store.pendingScanImage {
                    store.pendingScanImage = nil
                    Task { await processImage(image) }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(source: .camera) { image in
                    Task { await processImage(image) }
                }
                .ignoresSafeArea()
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .plainText, .commaSeparatedText, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task { await processFile(url) }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
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
        store.saveDraft(draft, rawInput: ocrText.isEmpty ? nil : ocrText)
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

    private func processFile(_ url: URL) async {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        isProcessing = true
        errorMessage = nil

        let ext = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic", "webp"].contains(ext),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            await processImage(image)
            return
        }

        guard let text = DocumentImportService.extractText(from: url) else {
            errorMessage = "Datei konnte nicht gelesen werden."
            isProcessing = false
            return
        }
        ocrText = text
        documentKind = SmartInputParser.shared.detectDocumentKind(text)
        if documentKind == .balance {
            draft = SmartInputParser.shared.parseBalanceText(text)
        } else if let single = SmartInputParser.shared.parseSingle(text) {
            draft = single
        } else {
            let drafts = DocumentImportService.parseTransactions(from: text)
            draft = drafts.first
        }
        if draft == nil {
            errorMessage = "Kein Betrag in der Datei erkannt."
        }
        isProcessing = false
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
