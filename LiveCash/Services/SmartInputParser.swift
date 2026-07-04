import Foundation

enum SmartInputResult {
    case transaction(Transaction, message: String)
    case bulkImport([Transaction], message: String)
    case assistant(AssistantResponse)
    case unrecognized
}

struct ParsedTransactionDraft {
    var amount: Double
    var type: TransactionType
    var merchant: String
    var category: FinanceCategory
    var date: Date
}

@MainActor
final class SmartInputParser {
    static let shared = SmartInputParser()

    private let amountPattern = #"(?:\+|-)?\s*(\d{1,6}(?:[.,]\d{1,2})?)\s*(?:€|eur|euro)?"#
    private let datePattern = #"\b(\d{1,2})[./](\d{1,2})[./](\d{2,4})\b"#

    func process(_ input: String) -> SmartInputResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unrecognized }

        if trimmed.contains("\n") || trimmed.count > 80 {
            let bulk = parseBulk(trimmed)
            if !bulk.isEmpty {
                return .bulkImport(bulk, message: "\(bulk.count) Transaktionen erkannt")
            }
        }

        if isLikelyQuery(trimmed) {
            return .assistant(AssistantResponse(mode: .suggestions(intent: .overview, headline: "", actions: [])))
        }

        if let draft = parseSingle(trimmed) {
            let tx = Transaction(
                amount: draft.amount,
                type: draft.type,
                category: draft.category,
                merchant: draft.merchant,
                date: draft.date,
                rawInput: trimmed
            )
            let sign = draft.type == .income ? "+" : "-"
            let msg = String(format: "Hinzugefügt: %@ %@%.2f€ (%@)", draft.merchant, sign, draft.amount, draft.category.rawValue)
            return .transaction(tx, message: msg)
        }

        if containsAmount(trimmed) == false, FinanceAssistant.shared.matchIntent(trimmed) != nil {
            return .assistant(AssistantResponse(mode: .suggestions(intent: .overview, headline: "", actions: [])))
        }

        return .unrecognized
    }

    func isLikelyQuery(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("?") { return true }
        let starters = ["wie ", "was ", "wo ", "wann ", "warum ", "welche", "zeig ", "liste ", "hilf"]
        if starters.contains(where: { lower.hasPrefix($0) }) { return true }
        if FinanceAssistant.shared.matchIntent(text) != nil, !looksLikeTransaction(text) { return true }
        return false
    }

    private func looksLikeTransaction(_ text: String) -> Bool {
        containsAmount(text) && !text.lowercased().hasPrefix("wie ")
    }

    private func containsAmount(_ text: String) -> Bool {
        extractAmount(from: text) != nil
    }

    func parseSingle(_ text: String) -> ParsedTransactionDraft? {
        guard let amount = extractAmount(from: text) else { return nil }
        if isLikelyQuery(text) { return nil }

        let isIncome = text.contains("+") ||
            text.lowercased().contains("gehalt") ||
            text.lowercased().contains("lohn") ||
            text.lowercased().contains("einkommen") ||
            text.lowercased().contains("salary")

        let type: TransactionType = isIncome ? .income : .expense
        let merchant = extractMerchant(from: text, amount: amount)
        let category = type == .income ? .income : FinanceCategory.detect(from: text + " " + merchant)
        let date = extractDate(from: text) ?? Date()

        return ParsedTransactionDraft(
            amount: amount,
            type: type,
            merchant: merchant,
            category: category,
            date: date
        )
    }

    func parseBulk(_ text: String) -> [Transaction] {
        let lines = text.components(separatedBy: .newlines)
        return lines.compactMap { line -> Transaction? in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { return nil }
            guard let draft = parseSingle(t) else { return nil }
            return Transaction(
                amount: draft.amount,
                type: draft.type,
                category: draft.category,
                merchant: draft.merchant,
                date: draft.date,
                rawInput: t
            )
        }
    }

    func parseOCRText(_ text: String) -> ParsedTransactionDraft? {
        let upper = text.uppercased()
        let merchant: String
        if let firstLine = text.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            merchant = firstLine.trimmingCharacters(in: .whitespaces).prefix(40).description
        } else {
            merchant = "Beleg"
        }

        var amount = extractAmount(from: text)
        if amount == nil {
            if let totalRange = upper.range(of: "TOTAL") ?? upper.range(of: "SUMME") {
                let after = String(upper[totalRange.upperBound...])
                amount = extractAmount(from: after)
            }
        }
        guard let finalAmount = amount else { return nil }

        let category = FinanceCategory.detect(from: text)
        let date = extractDate(from: text) ?? Date()

        return ParsedTransactionDraft(
            amount: finalAmount,
            type: .expense,
            merchant: merchant,
            category: category,
            date: date
        )
    }

    private func extractAmount(from text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let amountRange = Range(match.range(at: 1), in: text) else { return nil }
        let raw = text[amountRange].replacingOccurrences(of: ",", with: ".")
        return Double(raw)
    }

    private func extractMerchant(from text: String, amount: Double) -> String {
        var cleaned = text
        let amountStr = String(format: "%.2f", amount).replacingOccurrences(of: ".", with: "[.,]")
        if let regex = try? NSRegularExpression(pattern: #"[+\-]?\s*\#(amountStr)\s*(?:€|eur)?"#, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
        }
        cleaned = cleaned.replacingOccurrences(of: "€", with: "")
        cleaned = cleaned.replacingOccurrences(of: "+", with: "")
        let words = cleaned
            .components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && !$0.allSatisfy(\.isNumber) }

        if words.isEmpty { return "Unbekannt" }
        return words.prefix(4).joined(separator: " ").capitalized
    }

    private func extractDate(from text: String) -> Date? {
        guard let regex = try? NSRegularExpression(pattern: datePattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let dR = Range(match.range(at: 1), in: text),
              let mR = Range(match.range(at: 2), in: text),
              let yR = Range(match.range(at: 3), in: text) else { return nil }

        guard let day = Int(text[dR]), let month = Int(text[mR]) else { return nil }
        var year = Int(text[yR]) ?? 0
        if year < 100 { year += 2000 }

        var comps = DateComponents()
        comps.day = day
        comps.month = month
        comps.year = year
        return Calendar.current.date(from: comps)
    }
}
