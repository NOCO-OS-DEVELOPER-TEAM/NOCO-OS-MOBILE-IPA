import SwiftUI

enum AppCategory: String, CaseIterable, Codable, Identifiable {
    case social
    case video
    case chat
    case games
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .social: return "Social"
        case .video: return "Video"
        case .chat: return "Chat"
        case .games: return "Spiele"
        case .other: return "Sonstige"
        }
    }

    var icon: String {
        switch self {
        case .social: return "person.2.fill"
        case .video: return "play.tv.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .games: return "gamecontroller.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

struct ProtectedApp: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let category: AppCategory
    let keywords: [String]
    var isEnabled: Bool
    var isCustom: Bool

    var accent: Color {
        switch category {
        case .social: return NOCOTheme.coral
        case .video: return NOCOTheme.lavender
        case .chat: return NOCOTheme.mint
        case .games: return Color.orange
        case .other: return NOCOTheme.teal
        }
    }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if name.lowercased().contains(q) { return true }
        return keywords.contains { $0.lowercased().contains(q) }
    }

    static let catalog: [ProtectedApp] = [
        .init(id: "instagram", name: "Instagram", symbol: "camera.fill", category: .social, keywords: ["insta", "meta"], isEnabled: true, isCustom: false),
        .init(id: "tiktok", name: "TikTok", symbol: "music.note", category: .social, keywords: ["video", "bytedance"], isEnabled: false, isCustom: false),
        .init(id: "snapchat", name: "Snapchat", symbol: "bolt.fill", category: .social, keywords: ["snap"], isEnabled: false, isCustom: false),
        .init(id: "twitter", name: "X", symbol: "at", category: .social, keywords: ["twitter"], isEnabled: false, isCustom: false),
        .init(id: "facebook", name: "Facebook", symbol: "person.2.fill", category: .social, keywords: ["meta", "fb"], isEnabled: false, isCustom: false),
        .init(id: "threads", name: "Threads", symbol: "text.bubble.fill", category: .social, keywords: ["meta"], isEnabled: false, isCustom: false),
        .init(id: "pinterest", name: "Pinterest", symbol: "pin.fill", category: .social, keywords: [], isEnabled: false, isCustom: false),
        .init(id: "youtube", name: "YouTube", symbol: "play.rectangle.fill", category: .video, keywords: ["google", "yt"], isEnabled: false, isCustom: false),
        .init(id: "netflix", name: "Netflix", symbol: "tv.fill", category: .video, keywords: ["stream"], isEnabled: false, isCustom: false),
        .init(id: "twitch", name: "Twitch", symbol: "dot.radiowaves.left.and.right", category: .video, keywords: ["stream"], isEnabled: false, isCustom: false),
        .init(id: "whatsapp", name: "WhatsApp", symbol: "message.fill", category: .chat, keywords: ["wa", "meta"], isEnabled: false, isCustom: false),
        .init(id: "telegram", name: "Telegram", symbol: "paperplane.fill", category: .chat, keywords: ["tg"], isEnabled: false, isCustom: false),
        .init(id: "discord", name: "Discord", symbol: "headphones", category: .chat, keywords: [], isEnabled: false, isCustom: false),
        .init(id: "messenger", name: "Messenger", symbol: "bubble.left.fill", category: .chat, keywords: ["meta"], isEnabled: false, isCustom: false),
        .init(id: "signal", name: "Signal", symbol: "lock.shield.fill", category: .chat, keywords: [], isEnabled: false, isCustom: false),
        .init(id: "reddit", name: "Reddit", symbol: "globe", category: .social, keywords: [], isEnabled: false, isCustom: false),
        .init(id: "safari", name: "Safari", symbol: "safari.fill", category: .other, keywords: ["browser", "web"], isEnabled: false, isCustom: false),
        .init(id: "chrome", name: "Chrome", symbol: "globe.americas.fill", category: .other, keywords: ["browser", "google"], isEnabled: false, isCustom: false),
        .init(id: "roblox", name: "Roblox", symbol: "cube.fill", category: .games, keywords: ["game"], isEnabled: false, isCustom: false),
        .init(id: "minecraft", name: "Minecraft", symbol: "square.grid.3x3.fill", category: .games, keywords: ["game"], isEnabled: false, isCustom: false),
        .init(id: "clash", name: "Clash of Clans", symbol: "shield.fill", category: .games, keywords: ["supercell"], isEnabled: false, isCustom: false),
        .init(id: "spotify", name: "Spotify", symbol: "waveform", category: .other, keywords: ["music"], isEnabled: false, isCustom: false),
        .init(id: "be_real", name: "BeReal", symbol: "camera.aperture", category: .social, keywords: [], isEnabled: false, isCustom: false),
    ]
}

enum AppSelectionPreset: String, CaseIterable, Identifiable {
    case recommended
    case social
    case chat
    case games
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recommended: return "Empfohlen"
        case .social: return "Social"
        case .chat: return "Chat"
        case .games: return "Spiele"
        case .none: return "Alle aus"
        }
    }

    var icon: String {
        switch self {
        case .recommended: return "star.fill"
        case .social: return "person.2.fill"
        case .chat: return "bubble.left.fill"
        case .games: return "gamecontroller.fill"
        case .none: return "xmark.circle"
        }
    }

    var appIDs: Set<String> {
        switch self {
        case .recommended:
            return ["instagram", "tiktok", "youtube", "snapchat", "whatsapp"]
        case .social:
            return Set(ProtectedApp.catalog.filter { $0.category == .social }.map(\.id))
        case .chat:
            return Set(ProtectedApp.catalog.filter { $0.category == .chat }.map(\.id))
        case .games:
            return Set(ProtectedApp.catalog.filter { $0.category == .games }.map(\.id))
        case .none:
            return []
        }
    }
}
