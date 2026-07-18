import Foundation

enum OCRDocumentKind {
    case receipt
    case balance
    case bankStatement
    case general
}

enum SmartInputResult {
    case transaction(Transaction, message: String)
    case bulkImport([Transaction], message: String)
    case assistant(AssistantResponse)
    case unrecognized
}

struct ParsedTransactionDraft: Equatable {
    var amount: Double
    var type: TransactionType
    var merchant: String
    var category: FinanceCategory
    var date: Date

    /// Absolute Kontostand from OCR — must not be committed as an expense transaction.
    var isBalanceSnapshot: Bool {
        merchant.hasPrefix("Kontostand")
    }
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
        let starters = ["wie ", "was ", "wo ", "wann ", "warum ", "welche", "zeig ", "liste ", "hilf", "kann "]
        if starters.contains(where: { lower.hasPrefix($0) }) { return true }
        let decisionWords = ["leisten", "urlaub leisten", "wochenbudget", "finanzbericht", "was passiert wenn", "was wäre wenn"]
        if decisionWords.contains(where: { lower.contains($0) }) { return true }
        if FinanceAssistant.shared.matchIntent(text) != nil, !looksLikeTransactionPrivate(text) { return true }
        return false
    }

    func looksLikeTransaction(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("leisten") || lower.hasPrefix("kann ") || lower.contains("darf ich") { return false }
        if containsAmount(text) && !lower.hasPrefix("wie ") && !lower.hasPrefix("wo ") { return true }
        // Product names alone (e.g. "Sprite") are expense candidates when paired with amount elsewhere
        return isKnownProductName(lower)
    }

    func isKnownProductName(_ lower: String) -> Bool {
        let products = [
            "sprite", "cola", "fanta", "wasser", "kaffee", "coffee", "pizza", "döner", "doener",
            "burger", "snack", "chips", "eis", "bier", "saft", "red bull", "monster"
        ]
        let trimmed = lower.trimmingCharacters(in: .whitespacesAndNewlines)
        return products.contains(where: { trimmed == $0 || trimmed.hasPrefix($0 + " ") || trimmed.contains(" " + $0) })
    }

    func detectDocumentKind(_ text: String) -> OCRDocumentKind {
        let lower = text.lowercased()
        let lines = lower.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let lineCount = lines.count

        let balanceSignals = ["kontostand", "saldo", "kontoguthaben", "verfügbarer betrag", "verfuegbarer betrag", "aktueller stand"]
        let balanceHits = balanceSignals.filter { lower.contains($0) }.count
        if balanceHits >= 1 && !lower.contains("beleg") && !lower.contains("rechnung") {
            return .balance
        }

        let bankSignals = ["kontoauszug", "umsätze", "umsaetze", "iban", "bic", "valuta", "buchungstag", "wertstellung", "seite 1 von", "auszug per"]
        let bankHits = bankSignals.filter { lower.contains($0) }.count
        if bankHits >= 2 || (bankHits >= 1 && lineCount >= 8) {
            return .bankStatement
        }

        let receiptSignals = ["beleg", "summe", "total", "gesamt", "rechnung", "mwst", "ust", "kassenbon", "bon-nr", "tse", "visa", "mastercard", "barzahlung", "rückgeld"]
        let receiptHits = receiptSignals.filter { lower.contains($0) }.count
        if receiptHits >= 1 && lineCount <= 40 {
            return .receipt
        }

        // PDF screenshot heuristics: many short lines, page markers, no receipt keywords
        if lineCount >= 25 && (lower.contains("seite") || lower.contains("page")) {
            return bankHits >= 1 ? .bankStatement : .general
        }

        if receiptHits >= 1 { return .receipt }
        return .general
    }

    /// Parses an absolute account balance from OCR text.
    /// IMPORTANT: Balance snapshots must NOT be saved as `.expense` — see `isBalanceSnapshot` and ReceiptScanView.
    func parseBalanceText(_ text: String) -> ParsedTransactionDraft? {
        guard let amount = extractPreferredTotal(from: text) ?? extractAmount(from: text) else { return nil }
        return ParsedTransactionDraft(
            amount: amount,
            type: .expense, // display-only; ReceiptScanView must not commit as expense
            merchant: "Kontostand (Snapshot)",
            category: .other,
            date: extractDate(from: text) ?? Date()
        )
    }

    private func looksLikeTransactionPrivate(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("leisten") || lower.hasPrefix("kann ") || lower.contains("darf ich") { return false }
        return containsAmount(text) && !lower.hasPrefix("wie ")
    }

    func containsAmount(_ text: String) -> Bool {
        extractAmount(from: text) != nil
    }

    func hasExplicitType(in text: String) -> Bool {
        let lower = text.lowercased()
        if text.contains("+") { return true }
        if text.contains("-"), containsAmount(text) { return true }
        return ["gehalt", "lohn", "einkommen", "salary"].contains(where: { lower.contains($0) })
    }

    func applyPreferredType(_ type: TransactionType, to draft: inout ParsedTransactionDraft, text: String) {
        guard !hasExplicitType(in: text) else { return }
        draft.type = type
        if type == .income {
            draft.category = .income
        } else if draft.category == .income {
            draft.category = FinanceCategory.detect(from: text + " " + draft.merchant)
        }
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
        guard let finalAmount = extractPreferredTotal(from: text) ?? extractAmount(from: text) else { return nil }

        let merchant = extractOCRMerchant(from: text, amount: finalAmount)
        let category = FinanceCategory.detect(from: text + " " + merchant)
        let date = extractDate(from: text) ?? Date()

        return ParsedTransactionDraft(
            amount: finalAmount,
            type: .expense,
            merchant: merchant,
            category: category,
            date: date
        )
    }

    /// Prefers TOTAL / SUMME / GESAMT / ENDSUMME lines over incidental amounts on receipts.
    private func extractPreferredTotal(from text: String) -> Double? {
        let lines = text.components(separatedBy: .newlines)
        let totalKeywords = ["gesamtbetrag", "endsumme", "summe", "total", "gesamt", "zu zahlen", "betrag"]
        var candidates: [(priority: Int, amount: Double)] = []

        for line in lines {
            let lower = line.lowercased()
            guard let amount = extractAmount(from: line) else { continue }
            var priority = 0
            for (idx, kw) in totalKeywords.enumerated() where lower.contains(kw) {
                priority = max(priority, 100 - idx * 5)
            }
            if lower.contains("mwst") || lower.contains("ust") || lower.contains("netto") {
                priority = max(priority, 10)
            }
            if priority > 0 {
                candidates.append((priority, amount))
            }
        }

        if let best = candidates.max(by: { $0.priority == $1.priority ? $0.amount < $1.amount : $0.priority < $1.priority }) {
            return best.amount
        }

        // Fallback: largest plausible amount on the receipt (exclude tiny tax lines)
        let allAmounts = extractAllAmounts(from: text).filter { $0 >= 0.50 && $0 <= 50_000 }
        return allAmounts.max()
    }

    private func extractAllAmounts(from text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        return matches.compactMap { match -> Double? in
            guard let amountRange = Range(match.range(at: 1), in: text) else { return nil }
            let raw = text[amountRange].replacingOccurrences(of: ",", with: ".")
            return Double(raw)
        }
    }

    private func extractOCRMerchant(from text: String, amount: Double) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let skipPatterns = ["summe", "total", "gesamt", "mwst", "ust", "kasse", "bon", "tse", "visa", "mastercard", "ec-karte", "bar", "rückgeld", "datum", "uhrzeit"]
        let contentLines = lines.filter { line in
            let lower = line.lowercased()
            guard extractAmount(from: line) == nil || line.count > 12 else { return false }
            return !skipPatterns.contains(where: { lower.contains($0) })
        }

        if let candidate = contentLines.first(where: { $0.count >= 3 && !$0.allSatisfy(\.isNumber) }) {
            let known = extractMerchant(from: candidate, amount: amount)
            if known != "Unbekannt" { return known }
            if candidate.count >= 3 { return String(candidate.prefix(40)) }
        }

        return extractMerchant(from: text, amount: amount)
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
        let lower = text.lowercased()
        let known: [(String, String)] = [
            ("rewe", "REWE"), ("lidl", "Lidl"), ("aldi", "Aldi"), ("edeka", "Edeka"),
            ("penny", "Penny"), ("netto", "Netto"), ("dm ", "dm"), ("rossmann", "Rossmann"),
            ("amazon", "Amazon"), ("paypal", "PayPal"), ("spotify", "Spotify"),
            ("netflix", "Netflix"), ("apple", "Apple"), ("mcdonald", "McDonald's"),
            ("burger king", "Burger King"), ("starbucks", "Starbucks"), ("shell", "Shell"),
            ("aral", "Aral"), ("ikea", "IKEA"), ("media markt", "MediaMarkt"), ("saturn", "Saturn"),
            ("sprite", "Sprite"), ("coca cola", "Coca-Cola"), ("cola", "Cola"), ("fanta", "Fanta"),
            ("red bull", "Red Bull"), ("monster", "Monster")
        ]
        for (needle, name) in known where lower.contains(needle) {
            return name
        }

        var cleaned = text
        let amountStr = String(format: "%.2f", amount).replacingOccurrences(of: ".", with: "[.,]")
        if let regex = try? NSRegularExpression(pattern: #"[+\-]?\s*\#(amountStr)\s*(?:€|eur)?"#, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
        }
        cleaned = cleaned.replacingOccurrences(of: "€", with: "")
        cleaned = cleaned.replacingOccurrences(of: "+", with: "")
        let words = cleaned
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && !$0.allSatisfy(\.isNumber) && $0.count > 1 }

        if words.isEmpty { return "Unbekannt" }
        return words.prefix(3).joined(separator: " ").capitalized
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
