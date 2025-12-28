//
//  ReceiptParsingService.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import Foundation
import FoundationModels

/// Service for parsing receipt text using Apple's on-device Foundation LLM
actor ReceiptParsingService {
    static let shared = ReceiptParsingService()
    
    private init() {}
    
    // MARK: - Model Availability
    
    /// Checks if the on-device language model is available
    var isModelAvailable: Bool {
        get async {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return true
            case .unavailable:
                return false
            @unknown default:
                return false
            }
        }
    }
    
    // MARK: - Receipt Parsing
    
    /// Parses receipt text into structured data using the on-device LLM
    /// - Parameter text: The raw OCR text from the receipt
    /// - Returns: Parsed receipt data
    func parseReceipt(from text: String) async throws -> ParsedReceiptData {
        // Check model availability
        guard await isModelAvailable else {
            throw ReceiptParsingError.modelUnavailable
        }
        
        // Create a session for the parsing
        let session = LanguageModelSession()
        
        // Craft the prompt for receipt parsing
        let prompt = """
        Parse the following receipt text and extract structured information.
        
        Receipt text:
        \(text)
        
        Extract the store name, transaction date, total amount, and list of purchased items with their prices.
        """
        
        do {
            let response = try await session.respond(
                to: prompt,
                generating: ParsedReceiptData.self
            )
            
            return response.content
        } catch {
            throw ReceiptParsingError.parsingFailed(error)
        }
    }
    
    /// Creates a Receipt model from parsed data
    func createReceipt(
        from parsedData: ParsedReceiptData,
        imageFileName: String,
        rawText: String
    ) -> Receipt {
        let receipt = Receipt(
            imageFileName: imageFileName,
            rawText: rawText,
            storeName: parsedData.storeName,
            transactionDate: parsedData.parsedDate,
            total: parsedData.totalAsDecimal,
            items: parsedData.createReceiptItems()
        )
        
        return receipt
    }
}

// MARK: - Simple Fallback Parser

extension ReceiptParsingService {
    /// Simple regex-based fallback parser when LLM is unavailable
    func parseReceiptWithFallback(from text: String) -> ParsedReceiptData {
        var storeName: String?
        var total: Double?
        var dateString: String?
        
        let lines = text.components(separatedBy: .newlines)
        
        // Try to find store name (usually first non-empty line)
        if let firstLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            storeName = firstLine.trimmingCharacters(in: .whitespaces)
        }
        
        // Try to find total amount
        let totalPatterns = [
            "(?i)total[:\\s]+\\$?([0-9]+\\.?[0-9]*)",
            "(?i)grand total[:\\s]+\\$?([0-9]+\\.?[0-9]*)",
            "(?i)amount[:\\s]+\\$?([0-9]+\\.?[0-9]*)"
        ]
        
        for pattern in totalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                total = Double(text[range])
                break
            }
        }
        
        // Try to find date
        let datePatterns = [
            "(\\d{1,2}/\\d{1,2}/\\d{2,4})",
            "(\\d{4}-\\d{2}-\\d{2})",
            "([A-Za-z]{3}\\s+\\d{1,2},?\\s+\\d{4})"
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                dateString = String(text[range])
                break
            }
        }
        
        return ParsedReceiptData(
            storeName: storeName,
            dateString: dateString,
            total: total,
            currency: "USD",
            items: nil
        )
    }
}

// MARK: - Errors

enum ReceiptParsingError: LocalizedError {
    case modelUnavailable
    case parsingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "On-device language model is not available on this device"
        case .parsingFailed(let error):
            return "Failed to parse receipt: \(error.localizedDescription)"
        }
    }
}
