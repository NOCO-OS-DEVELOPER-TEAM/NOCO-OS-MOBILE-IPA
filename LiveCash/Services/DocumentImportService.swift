import Foundation
import PDFKit
import UniformTypeIdentifiers

enum DocumentImportService {
    static func extractText(from url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        if ext == "pdf" {
            return extractPDFText(url: url)
        }
        if ["txt", "csv", "text"].contains(ext) {
            return try? String(contentsOf: url, encoding: .utf8)
        }
        return nil
    }

    static func parseTransactions(from text: String) -> [ParsedTransactionDraft] {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if lines.count > 1 {
            let bulk = SmartInputParser.shared.parseBulk(text)
            if !bulk.isEmpty { return bulk.map { draft in
                var d = draft
                SmartInputParser.shared.applyPreferredType(.expense, to: &d, text: "")
                return d
            }}
        }
        if let single = SmartInputParser.shared.parseSingle(text) {
            var d = single
            SmartInputParser.shared.applyPreferredType(.expense, to: &d, text: text)
            return [d]
        }
        return []
    }

    private static func extractPDFText(url: URL) -> String? {
        guard let doc = PDFDocument(url: url) else { return nil }
        var parts: [String] = []
        for i in 0..<doc.pageCount {
            parts.append(doc.page(at: i)?.string ?? "")
        }
        let combined = parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return combined.isEmpty ? nil : combined
    }
}
