//
//  TextRecognitionService.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import Foundation
import Vision
import UIKit

/// Service for extracting text from receipt images using VisionKit
actor TextRecognitionService {
    static let shared = TextRecognitionService()
    
    private init() {}
    
    // MARK: - Text Recognition
    
    /// Recognizes text in the provided image
    /// - Parameter image: The UIImage to extract text from
    /// - Returns: Extracted text as a single string
    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw TextRecognitionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: TextRecognitionError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Extract text from each observation
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            
            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TextRecognitionError.recognitionFailed(error))
            }
        }
    }
    
    /// Recognizes text with bounding boxes for each recognized text block
    func recognizeTextWithBounds(in image: UIImage) async throws -> [RecognizedTextBlock] {
        guard let cgImage = image.cgImage else {
            throw TextRecognitionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: TextRecognitionError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let blocks = observations.compactMap { observation -> RecognizedTextBlock? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return RecognizedTextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                
                continuation.resume(returning: blocks)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TextRecognitionError.recognitionFailed(error))
            }
        }
    }
}

// MARK: - Supporting Types

struct RecognizedTextBlock: Identifiable {
    let id = UUID()
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

// MARK: - Errors

enum TextRecognitionError: LocalizedError {
    case invalidImage
    case recognitionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided for text recognition"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        }
    }
}
