//
//  ImageStorageService.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import Foundation
import UIKit
import SwiftUI

/// Service for saving and loading receipt images to/from the app's documents directory
actor ImageStorageService {
    static let shared = ImageStorageService()
    
    private let fileManager = FileManager.default
    private let receiptsDirectory = "ReceiptImages"
    
    private init() {
        createReceiptsDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private var receiptsDirectoryURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent(receiptsDirectory)
    }
    
    private func createReceiptsDirectoryIfNeeded() {
        let url = receiptsDirectoryURL
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Save Image
    
    /// Saves an image and returns the filename
    func saveImage(_ image: UIImage, quality: CGFloat = 0.8) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = receiptsDirectoryURL.appendingPathComponent(filename)
        
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw ImageStorageError.compressionFailed
        }
        
        try data.write(to: fileURL, options: .atomic)
        return filename
    }
    
    // MARK: - Load Image
    
    /// Loads an image by filename
    func loadImage(filename: String) throws -> UIImage {
        let fileURL = receiptsDirectoryURL.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw ImageStorageError.fileNotFound
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            throw ImageStorageError.loadFailed
        }
        
        return image
    }
    
    /// Returns the full URL for a filename
    func imageURL(for filename: String) -> URL {
        receiptsDirectoryURL.appendingPathComponent(filename)
    }
    
    // MARK: - Delete Image
    
    /// Deletes an image by filename
    func deleteImage(filename: String) throws {
        let fileURL = receiptsDirectoryURL.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return // Already deleted, no error
        }
        
        try fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Thumbnail Generation
    
    /// Creates a thumbnail of the specified size
    func createThumbnail(for filename: String, size: CGSize) throws -> UIImage {
        let image = try loadImage(filename: filename)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Errors

enum ImageStorageError: LocalizedError {
    case compressionFailed
    case fileNotFound
    case loadFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .fileNotFound:
            return "Image file not found"
        case .loadFailed:
            return "Failed to load image"
        case .saveFailed:
            return "Failed to save image"
        }
    }
}

// MARK: - SwiftUI Image Loading

extension ImageStorageService {
    /// Loads an image asynchronously for SwiftUI
    nonisolated func loadImageAsync(filename: String) async -> UIImage? {
        try? await loadImage(filename: filename)
    }
}
