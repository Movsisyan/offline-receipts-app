# 📱 Offline Receipts Store

A fully offline iOS app for capturing, organizing, and managing receipts using on-device OCR and Apple's Foundation LLM for intelligent text extraction.

![iOS 26.1+](https://img.shields.io/badge/iOS-26.1+-blue.svg)
![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-green.svg)
![SwiftData](https://img.shields.io/badge/SwiftData-Persistence-purple.svg)

## ✨ Features

### 📷 Receipt Capture
- **Camera capture** - Take photos of receipts directly
- **Photo library** - Import existing receipt images
- **Single page mode** - Quick capture with immediate processing
- **Multi-page mode** - Add multiple pages for long receipts, then process together

### 🤖 Intelligent Parsing
- **On-device OCR** - VisionKit text recognition, no internet required
- **Apple Foundation LLM** - Structured data extraction using `@Generable` protocol
- **Fallback parser** - Regex-based parsing when LLM is unavailable
- **Comprehensive extraction**:
  - Store name, address, phone
  - Transaction date and receipt number
  - Subtotal, tax, tips, and total
  - Payment method and card last 4 digits
  - Item list with quantities and prices
  - Suggested category

### 📁 Folder Organization
- **Create custom folders** - Work, Vacation, Personal, etc.
- **Customizable appearance** - 11 colors and 16 icons to choose from
- **Quick filtering** - Tap folder tabs to filter receipts
- **Unfiled view** - Find receipts not yet organized
- **Move receipts** - Long press or edit to assign folders

### 🔍 Search & Browse
- **Full-text search** - Search store names and OCR text
- **Grid gallery** - Visual thumbnail view of all receipts
- **Multi-page indicator** - Badge shows page count
- **Folder badges** - See folder assignment at a glance

### 📄 Receipt Details
- **Image gallery** - Swipe through multi-page receipts
- **Pinch to zoom** - Full-screen image viewing
- **Parsed data display** - Organized sections for all extracted info
- **Raw OCR text** - View original extracted text
- **Edit all fields** - Modify any parsed information
- **Notes** - Add personal annotations

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Text Recognition | VisionKit (`VNRecognizeTextRequest`) |
| AI Parsing | Apple Foundation Models (`@Generable`) |
| Image Capture | UIImagePickerController |
| Architecture | MVVM-like with Services |

## 📋 Requirements

- **iOS 26.1+** (required for Foundation Models)
- **Apple Silicon** (A17 Pro / M-series chips for on-device LLM)
- **Camera permission** (for capturing receipts)
- **Photo library permission** (for importing images)

> ⚠️ The Apple Foundation LLM features require iOS 26 and Apple Silicon. On older devices, the app falls back to regex-based parsing.

## 🚀 Getting Started

### Prerequisites
- Xcode 16+ with iOS 26 SDK
- Physical iOS device with A17 Pro or M-series chip (for full LLM features)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Movsisyan/offline-receipts-app.git
   cd offline-receipts-app
   ```

2. Open in Xcode:
   ```bash
   open Receipts-Store.xcodeproj
   ```

3. Select your development team in project settings

4. Build and run on your device (⌘R)

## 📂 Project Structure

```
Receipts-Store/
├── Models/
│   ├── Receipt.swift          # Main receipt model with multi-page support
│   ├── ReceiptItem.swift      # Line item model
│   ├── ParsedReceiptData.swift # @Generable LLM output structure
│   └── Folder.swift           # Folder organization model
├── Views/
│   ├── ContentView.swift      # App entry point
│   ├── ReceiptsListView.swift # Main gallery with folder tabs
│   ├── ReceiptDetailView.swift # Receipt detail with image gallery
│   ├── AddReceiptView.swift   # Capture flow (single/multi-page)
│   ├── EditReceiptView.swift  # Edit all receipt fields
│   ├── CameraCaptureView.swift # Camera/photo picker wrappers
│   └── FolderManagementView.swift # Folder CRUD operations
├── Services/
│   ├── ImageStorageService.swift    # Image save/load/thumbnail
│   ├── TextRecognitionService.swift # VisionKit OCR
│   └── ReceiptParsingService.swift  # LLM + fallback parsing
└── Receipts_StoreApp.swift    # App entry with SwiftData config
```

## 🔐 Privacy

This app is **100% offline**:
- All OCR processing happens on-device using VisionKit
- AI text parsing uses Apple's on-device Foundation Models
- Receipt images are stored locally in the app's documents directory
- No data is sent to any server
- No analytics or tracking

## 📱 Screenshots

*Coming soon*

## 🗺 Roadmap

- [ ] Export receipts to PDF/CSV
- [ ] iCloud sync across devices
- [ ] Expense reports and summaries
- [ ] Receipt scanning tips/guidance overlay
- [ ] Widgets for quick capture
- [ ] Siri shortcuts integration

## 📄 License

This project is available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

Built with ❤️ using SwiftUI and Apple's on-device AI
