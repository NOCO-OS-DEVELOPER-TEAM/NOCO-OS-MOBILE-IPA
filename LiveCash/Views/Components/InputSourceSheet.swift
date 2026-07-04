import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

enum InputSourceOption: String, Identifiable {
    case camera
    case gallery
    case document

    var id: String { rawValue }

    var title: String {
        switch self {
        case .camera: return "Kamera"
        case .gallery: return "Galerie"
        case .document: return "Datei / PDF"
        }
    }

    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .gallery: return "photo.fill"
        case .document: return "doc.fill"
        }
    }
}

struct InputSourceSheet: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @Binding var showReceiptScan: Bool
    var onOpenCamera: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showDocumentPicker = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Beleg oder Dokument hinzufügen")
                    .font(LiveCashTheme.headlineFont)
                    .frame(maxWidth: .infinity, alignment: .leading)

                sourceButton(.camera) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onOpenCamera()
                    }
                }

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    sourceRow(.gallery)
                }
                .buttonStyle(.plain)

                Button {
                    showDocumentPicker = true
                } label: {
                    sourceRow(.document)
                }
                .buttonStyle(.plain)

                if isProcessing {
                    ProgressView("Wird verarbeitet…")
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.expense)
                }

                Spacer()
            }
            .padding(20)
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { await handleGalleryItem(item) }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.pdf, .plainText, .commaSeparatedText, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    processDocumentURL(url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sourceButton(_ option: InputSourceOption, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            sourceRow(option)
        }
        .buttonStyle(.plain)
    }

    private func sourceRow(_ option: InputSourceOption) -> some View {
        HStack(spacing: 14) {
            Image(systemName: option.icon)
                .font(.title3)
                .foregroundStyle(LiveCashTheme.accent)
                .frame(width: 36)
            Text(option.title)
                .font(LiveCashTheme.bodyFont)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @MainActor
    private func handleGalleryItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            errorMessage = "Bild konnte nicht geladen werden."
            return
        }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showReceiptScan = true
        }
        // ReceiptScanView handles OCR when opened with image - pass via store flag
        store.pendingScanImage = image
    }

    private func processDocumentURL(_ url: URL) {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        if let text = DocumentImportService.extractText(from: url) {
            let drafts = DocumentImportService.parseTransactions(from: text)
            if drafts.isEmpty {
                errorMessage = "Keine Buchungen im Dokument erkannt."
                return
            }
            for draft in drafts {
                store.saveDraft(draft, rawInput: text)
            }
            store.lastFeedback = "\(drafts.count) Buchung(en) aus Dokument"
            dismiss()
            return
        }

        if url.pathExtension.lowercased() == "pdf" {
            errorMessage = "PDF ohne erkennbaren Text."
        } else {
            errorMessage = "Datei konnte nicht verarbeitet werden."
        }
    }
}
