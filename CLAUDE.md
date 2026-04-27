# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PriceRecorder** is a SwiftUI-based iOS application for recording and comparing product prices across merchants. Key features:
- Record product purchases with detailed information
- Doubao smart entry for batch import via JSON
- Merchant management with categorization
- Price comparison with interactive charts (SwiftCharts)
- CSV import/export
- Full data backup with photos (JSON format)
- AI consultation with configurable LLM providers
- iOS 17.0+, SwiftData, Xcode 15.0+

## How to Build and Run

### Prerequisites
- macOS with Xcode 15.0+
- iOS 17.0+ simulator or device
- Apple Developer account (for signing)

### Building in Xcode
1. Open `PriceRecorder.xcodeproj`
2. Configure signing team and bundle identifier
3. Select iOS 17.0+ deployment target
4. Build: `⌘B`
5. Run: `⌘R`

### Command Line
```bash
# Debug build
xcodebuild -scheme PriceRecorder -configuration Debug build

# Release build
xcodebuild -scheme PriceRecorder -configuration Release build

# Clean and build
xcodebuild clean build -scheme PriceRecorder
```

## Architecture

### Pattern: MVVM with SwiftData
- **Models**: SwiftData `@Model` classes (ProductRecord, Merchant, MerchantCategory, Receipt, APIConfig, LLMConfig, AIMessage, LLMDebugLog)
- **Views**: SwiftUI views organized by feature
- **Services**: Business logic (CSVService, CloudSyncService, OCRService, BackupService, LLMService)

### Key Architectural Decisions
- Manual UUID relationships instead of SwiftData `@Relationship` for migration flexibility
- Merchant caching to avoid N+1 query issues
- Limited fetching (recent 10/100 records) for performance

## Project Structure

```
PriceRecorder/
├── PriceRecorder.xcodeproj/          # Xcode project
├── PriceRecorder/
│   ├── PriceRecorderApp.swift         # App entry point
│   ├── Models/                        # SwiftData models
│   │   ├── ProductRecord.swift
│   │   ├── Merchant.swift
│   │   ├── MerchantCategory.swift
│   │   ├── Receipt.swift
│   │   ├── APIConfig.swift
│   │   ├── LLMConfig.swift            # v1.3: LLM provider config
│   │   ├── AIMessage.swift            # v1.3: AI chat messages
│   │   └── LLMDebugLog.swift         # v1.3: LLM debug logs
│   ├── Views/                         # SwiftUI views by feature
│   │   ├── Home/                      # Home screen
│   │   ├── Search/                    # Search & comparison
│   │   │   ├── SearchView.swift
│   │   │   └── AIChatView.swift      # v1.3: AI consultation chat
│   │   ├── ProductEntry/              # Manual & Doubao entry
│   │   ├── PriceComparison/           # Price comparison charts
│   │   │   └── PriceComparisonView.swift # v1.3: Interactive chart with time range
│   │   ├── Settings/                  # Settings, merchant management
│   │   │   ├── SettingsView.swift
│   │   │   ├── LLMConfigView.swift   # v1.3: LLM config
│   │   │   ├── DebugConfigView.swift # v1.3: Debug config
│   │   │   ├── DataManagementView.swift # v1.3: Backup/restore options
│   │   │   └── StatisticsView.swift  # v1.3: Enhanced stats
│   │   └── Components/                # Reusable components
│   └── Services/                      # Business logic services
│       ├── CSVService.swift
│       ├── CloudSyncService.swift
│       ├── OCRService.swift
│       ├── BackupService.swift       # v1.3: Backup/restore service
│       └── LLMService.swift          # v1.3: LLM API service
├── README.md                          # Main docs
├── 需求文档.md                        # Requirements (Chinese)
├── 设计文档.md                        # Architecture docs (Chinese)
├── 测试文档.md                        # Test docs (Chinese)
├── 编译和运行指南.md                  # Build guide (Chinese)
└── 代码文档.md                        # Code docs (Chinese)
```

## Key Files

| File | Purpose |
|------|---------|
| `PriceRecorderApp.swift` | App entry, SwiftData container setup |
| `Models/ProductRecord.swift` | Core product record model |
| `Models/Merchant.swift` | Merchant model |
| `Models/LLMConfig.swift` | v1.3: LLM provider configuration |
| `Views/Home/HomeView.swift` | Main home screen |
| `Views/Search/SearchView.swift` | Search and comparison (performance optimized) |
| `Views/Search/AIChatView.swift` | v1.3: AI consultation chat interface |
| `Views/ProductEntry/ProductEntryView.swift` | Manual product entry with validation |
| `Views/ProductEntry/DoubaoEntryView.swift` | Doubao smart batch entry |
| `Views/PriceComparison/PriceComparisonView.swift` | v1.3: Interactive price comparison charts |
| `Views/Settings/LLMConfigView.swift` | v1.3: LLM configuration UI |
| `Views/Settings/DataManagementView.swift` | v1.3: Data management with backup/restore |
| `Views/Settings/StatisticsView.swift` | v1.3: Enhanced statistics with merchant details |
| `Services/CSVService.swift` | CSV import/export with deduplication |
| `Services/OCRService.swift` | OCR functionality (v1.2 optimized) |
| `Services/BackupService.swift` | v1.3: Backup/restore with options |
| `Services/LLMService.swift` | v1.3: LLM API integration |

## Important Notes

### Performance Optimizations (v1.2)
- SearchView has merchant caching to prevent N+1 queries
- OCRService uses async/await with image compression
- CSV import uses local merchant cache for deduplication

### v1.3 Enhancements
- **Interactive Charts**: PriceComparisonView supports horizontal scrolling, tap/long press for details, and time range selection (day/week/month/year)
- **Backup System**: BackupService supports full/ data-only/ photos-only backups with JSON format, Base64 encoded photos
- **LLM Integration**: LLMService supports multiple providers (Doubao, OpenAI, Claude, etc.) with config UI and API testing
- **AI Consultation**: AIChatView in Search page for natural language queries about your purchase data
- **Enhanced Statistics**: StatisticsView shows all merchants, with detail popups showing spending, product counts, and category breakdowns
- **Input Validation**: All text fields have sensible length limits with real-time feedback
- **Photo Quality**: Configurable photo compression quality

### Data Model Relationships
- Manual UUID references (not SwiftData `@Relationship`)
- Merchants are cached in dictionaries for lookups
- UnitPrice is automatically calculated: `totalPrice / quantity`

### Documentation
- All documentation is in Chinese
- Keep documents in sync with code changes: README, 需求文档.md, 设计文档.md, 测试文档.md, 编译和运行指南.md, 代码文档.md

### Version History
- **v1.3 (Current)**: AI consultation, backup/restore, interactive charts, enhanced statistics, input limits, LLM config
- **v1.2**: Performance optimizations, input validation, OCR improvements
- **v1.1**: Refactored Doubao entry, fixed CSV merchant duplication
- **v1.0**: Initial release
