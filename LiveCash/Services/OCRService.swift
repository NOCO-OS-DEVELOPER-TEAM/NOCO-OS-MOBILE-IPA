import Foundation
import Vision
import UIKit

enum OCRServiceError: Error {
    case noText
    case imageFailed
}

final class OCRService {
    static let shared = OCRService()

    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw OCRServiceError.imageFailed }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let text = lines.joined(separator: "\n")
                if text.isEmpty {
                    continuation.resume(throwing: OCRServiceError.noText)
                } else {
                    continuation.resume(returning: text)
                }
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
