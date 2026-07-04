import Foundation

enum AssistantMode: String, CaseIterable, Identifiable {
    case input = "Eingabe"
    case question = "Frage"
    case suggestion = "Vorschläge"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .input: return "text.cursor"
        case .question: return "questionmark.circle"
        case .suggestion: return "sparkles"
        }
    }
}
