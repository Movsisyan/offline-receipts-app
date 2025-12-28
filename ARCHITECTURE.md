# 🏗 Architecture

This document describes the architecture and design patterns used in the Offline Receipts Store iOS application.

## Overview

The app follows a **modular architecture** with clear separation between:
- **Models** - SwiftData entities and data structures
- **Views** - SwiftUI user interface components
- **Services** - Business logic and external integrations

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
│  │ Receipts │ │  Detail  │ │   Add    │ │   Folder     │   │
│  │   List   │ │   View   │ │  Receipt │ │  Management  │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘   │
│       │            │            │               │           │
└───────┼────────────┼────────────┼───────────────┼───────────┘
        │            │            │               │
┌───────▼────────────▼────────────▼───────────────▼───────────┐
│                         Services                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌────────────────┐ │
│  │ ImageStorage    │ │ TextRecognition │ │ ReceiptParsing │ │
│  │    Service      │ │     Service     │ │    Service     │ │
│  └────────┬────────┘ └────────┬────────┘ └───────┬────────┘ │
│           │                   │                   │          │
└───────────┼───────────────────┼───────────────────┼──────────┘
            │                   │                   │
┌───────────▼───────────────────▼───────────────────▼──────────┐
│                      Foundation Layer                         │
│  ┌─────────────┐  ┌─────────────────┐  ┌──────────────────┐  │
│  │  Documents  │  │    VisionKit    │  │ Apple Foundation │  │
│  │  Directory  │  │      (OCR)      │  │   Models (LLM)   │  │
│  └─────────────┘  └─────────────────┘  └──────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Layer

### SwiftData Models

The app uses **SwiftData** for persistence with automatic schema management.

#### Receipt

```swift
@Model
final class Receipt {
    var id: UUID
    var storeName: String?
    var storeAddress: String?
    var storePhone: String?
    var date: Date?
    var total: Double?
    var subtotal: Double?
    var tax: Double?
    var tips: Double?
    var paymentMethodRaw: String
    var cardLastFourDigits: String?
    var categoryRaw: String
    var transactionNumber: String?
    var imageFilenames: String        // Comma-separated for multi-page
    var rawText: String?
    var notes: String?
    var createdAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ReceiptItem.receipt)
    var items: [ReceiptItem]
    
    @Relationship
    var folder: Folder?
}
```

#### ReceiptItem

```swift
@Model
final class ReceiptItem {
    var id: UUID
    var name: String
    var quantity: Double?
    var unitPrice: Double?
    var totalPrice: Double?
    var receipt: Receipt?
}
```

#### Folder

```swift
@Model
final class Folder {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int
    var createdAt: Date
    
    @Relationship(inverse: \Receipt.folder)
    var receipts: [Receipt]
}
```

### Data Flow

```
User Action → View → ModelContext → SwiftData Store → Disk
                ↑                              │
                └──────── Query ───────────────┘
```

---

## Services

### ImageStorageService

**Actor-based** service for thread-safe image operations.

```swift
actor ImageStorageService {
    static let shared = ImageStorageService()
    
    // Core operations
    func saveImage(_ image: UIImage, withName name: String) async throws -> String
    func loadImage(filename: String) async -> UIImage?
    func createThumbnail(for filename: String, size: CGSize) async throws -> UIImage
    func deleteImage(filename: String) async throws
}
```

**Storage Location:** `Documents/ReceiptImages/`

**Features:**
- Automatic JPEG compression (0.8 quality)
- Disk-based thumbnail caching
- Unique filename generation

### TextRecognitionService

Performs on-device OCR using **VisionKit**.

```swift
class TextRecognitionService {
    func recognizeText(in image: UIImage) async throws -> String
}
```

**Implementation:**
- Uses `VNRecognizeTextRequest` with `.accurate` recognition level
- Processes entire image for best coverage
- Returns concatenated text blocks

### ReceiptParsingService

Parses OCR text into structured data using **Apple Foundation Models**.

```swift
class ReceiptParsingService {
    func parseReceipt(text: String) async throws -> ParsedReceiptData
}
```

**Parsing Strategy:**
1. Check if Foundation LLM is available
2. If available: Use `@Generable` structured output
3. If unavailable: Fall back to regex-based parsing

#### ParsedReceiptData

```swift
@Generable
struct ParsedReceiptData {
    var storeName: String?
    var storeAddress: String?
    var storePhone: String?
    var date: String?
    var items: [ParsedItem]
    var subtotal: Double?
    var tax: Double?
    var tips: Double?
    var total: Double?
    var paymentMethod: String?
    var cardLastFourDigits: String?
    var transactionNumber: String?
    var suggestedCategory: String?
}
```

---

## View Layer

### View Hierarchy

```
Receipts_StoreApp
└── ContentView
    └── ReceiptsListView
        ├── HermesReceiptCard (grid items)
        ├── HermesTab (folder filter tabs)
        ├── AddReceiptView (sheet)
        │   ├── CameraCaptureView
        │   ├── PhotoLibraryPicker
        │   └── FolderPickerView
        ├── ReceiptDetailView (navigation destination)
        │   ├── FullScreenImageView
        │   └── EditReceiptView (sheet)
        └── FolderListView (sheet)
            ├── CreateFolderView
            └── EditFolderView
```

### State Management

| Scope | Mechanism | Example |
|-------|-----------|---------|
| Local | `@State` | `showAddReceipt`, `searchText` |
| Binding | `@Binding` | `selectedFolder` in picker |
| Observable | `@Bindable` | `receipt` in edit view |
| Environment | `@Environment` | `modelContext`, `dismiss` |
| Query | `@Query` | `receipts`, `folders` |

---

## Multi-Page Receipt Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Capture    │───▶│   Add More  │───▶│   Process   │
│  Page 1     │    │   Pages     │    │  All Pages  │
└─────────────┘    └─────────────┘    └──────┬──────┘
                                             │
                   ┌─────────────────────────┼────────────────────┐
                   │                         ▼                    │
                   │    ┌───────────────────────────────────┐    │
                   │    │          For Each Page:           │    │
                   │    │  1. Save image to disk            │    │
                   │    │  2. Run OCR (VisionKit)           │    │
                   │    └───────────────────────────────────┘    │
                   │                         │                    │
                   │                         ▼                    │
                   │    ┌───────────────────────────────────┐    │
                   │    │      Combine All OCR Text         │    │
                   │    └───────────────────────────────────┘    │
                   │                         │                    │
                   │                         ▼                    │
                   │    ┌───────────────────────────────────┐    │
                   │    │   Parse Combined Text (LLM)       │    │
                   │    └───────────────────────────────────┘    │
                   │                         │                    │
                   └─────────────────────────┼────────────────────┘
                                             ▼
                                    ┌─────────────┐
                                    │    Save     │
                                    │   Receipt   │
                                    └─────────────┘
```

**Storage:** Multiple filenames stored as comma-separated string:
```swift
imageFilenames = "receipt_001.jpg,receipt_002.jpg,receipt_003.jpg"
```

---

## Folder System

### Virtual Folder Design

Folders are "virtual" - they don't physically contain files. Instead:
- `Receipt.folder` is an optional relationship
- Filtering happens at query/view level
- Deleting a folder can optionally preserve receipts

### Folder States

| Filter | `selectedFolder` | `showUnfiledOnly` |
|--------|-----------------|-------------------|
| All Receipts | `nil` | `false` |
| Unfiled | `nil` | `true` |
| Specific Folder | `folder` | `false` |

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Text Recognition | VisionKit (`VNRecognizeTextRequest`) |
| AI Parsing | Apple Foundation Models (`@Generable`) |
| Image Capture | UIImagePickerController (via UIViewControllerRepresentable) |
| Concurrency | Swift Concurrency (async/await, actors) |

---

## Error Handling

### Service Errors

```swift
enum ImageStorageError: Error {
    case invalidImage
    case saveFailed
    case loadFailed
    case deleteFailed
}

enum TextRecognitionError: Error {
    case noTextFound
    case recognitionFailed
}

enum ParsingError: Error {
    case modelNotAvailable
    case parsingFailed
}
```

### Recovery Strategy

1. **Image failures**: Show error alert, allow retry
2. **OCR failures**: Proceed with empty text, allow manual entry
3. **LLM failures**: Fall back to regex parser
4. **Schema migration**: Auto-reset database (development only)

---

## Performance Considerations

### Image Handling
- Thumbnails generated on-demand and cached
- Full images loaded only when viewing detail
- JPEG compression reduces storage

### Memory Management
- `LazyVGrid` for efficient scrolling
- Images loaded asynchronously
- Thumbnails sized appropriately (200x200)

### Database
- `@Query` with sorting for efficient reads
- Cascade delete rules for cleanup
- Index on `createdAt` for chronological queries

---

## Future Architecture Considerations

1. **iCloud Sync**: Add CloudKit container for cross-device sync
2. **Export Service**: PDF/CSV generation service
3. **Analytics Service**: Expense tracking and reporting
4. **Widget Extension**: Quick capture from home screen
5. **Siri Intents**: Voice-activated receipt capture
