# PriceRecorder Code Wiki

## 1. Project Overview

PriceRecorder is an iOS application designed for recording and comparing product prices from different merchants. It supports OCR receipt scanning, data import/export, iCloud backup, and price trend analysis.

### Key Features
- ✅ Product recording (manual input and OCR receipt scanning)
- ✅ Price comparison with historical trends
- ✅ Merchant and brand management
- ✅ Data import/export (CSV format)
- ✅ iCloud backup (manual and automatic)
- ✅ Statistics and data insights
- ✅ Dark mode support

### Technology Stack
- **Language**: Swift 5.0+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Minimum iOS Version**: 17.0+
- **OCR**: iOS Vision framework
- **Charts**: SwiftCharts

## 2. Architecture

The project follows a clean architecture with a clear separation of concerns:

```
PriceRecorder/
├── Models/          # Data models using SwiftData
├── Views/           # SwiftUI views
│   ├── Home/        # Home screen
│   ├── Search/      # Search functionality
│   ├── Settings/    # Settings and management screens
│   ├── ProductEntry/ # Product input screens
│   ├── PriceComparison/ # Price comparison screens
│   └── Components/  # Reusable UI components
└── Services/        # Service layer
    ├── OCRService.swift     # OCR text recognition
    ├── CSVService.swift     # CSV import/export
    └── CloudSyncService.swift # iCloud sync
```

### Architecture Principles
- **Data-Driven**: Uses SwiftData for reactive data management
- **Modular**: Clear separation between models, views, and services
- **Reactive**: Leverages SwiftUI's declarative syntax and Combine for state management
- **Service-Oriented**: Encapsulates complex functionality in dedicated service classes

## 3. Data Models

### ProductRecord
The core model representing a product purchase record.

| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Product name |
| brand | String? | Product brand |
| quantity | Double | Quantity purchased |
| unit | String | Unit of measurement |
| spec | String? | Product specification |
| totalPrice | Double | Total price |
| unitPrice | Double | Price per unit |
| merchantID | UUID | Associated merchant ID |
| purchaseDate | Date | Date of purchase |
| receiptPhoto | Data? | Receipt image data |
| notes | String? | Additional notes |
| createTime | Date | Record creation time |
| updateTime | Date | Last update time |

### Merchant
Represents a store or merchant where products are purchased.

| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Merchant name |
| categoryID | UUID? | Associated category ID |
| address | String? | Merchant address |
| phone | String? | Merchant phone number |
| notes | String? | Additional notes |
| createTime | Date | Record creation time |
| updateTime | Date | Last update time |

### MerchantCategory
Represents a category for classifying merchants.

| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Category name |
| createTime | Date | Record creation time |

### Brand
Represents a product brand.

| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Brand name |
| createTime | Date | Record creation time |

### Receipt
Represents a purchase receipt.

| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier |
| merchantID | UUID | Associated merchant ID |
| purchaseDate | Date | Date of purchase |
| photo | Data? | Receipt image data |
| notes | String? | Additional notes |
| createTime | Date | Record creation time |

## 4. Services

### OCRService
Handles text recognition from receipt images using the iOS Vision framework.

#### Key Functions
- `recognizeText(from:completion:)`: Recognizes text from an image
- `parseReceiptItems(from:)`: Parses OCR results into product items
- `parseLine(_:)`: Parses individual lines from OCR results
- `parseQuantity(_:)`: Extracts quantity information from product names

### CSVService
Handles importing and exporting data in CSV format.

#### Key Functions
- `exportCSV(data:)`: Exports product data to CSV format
- `parseCSV(_:)`: Parses CSV data into product records
- `escapeCSVField(_:)`: Escapes special characters in CSV fields
- `parseCSVLine(_:)`: Parses individual lines from CSV data

### CloudSyncService
Handles iCloud synchronization for data backup and restore.

#### Key Functions
- `backupToCloud(modelContext:completion:)`: Backs up data to iCloud
- `restoreFromCloud(completion:)`: Restores data from iCloud
- `triggerAutoBackupIfNeeded(modelContext:)`: Automatically backs up data if enabled
- `saveAutoBackupSetting(_:)`: Saves auto-backup setting

## 5. Views

### HomeView
Main screen showing recently recorded products and providing access to product entry.

#### Key Components
- `ProductRow`: Displays individual product records in the list
- Navigation to `ProductEntryView` and `ProductDetailView`

### SearchView
Provides search functionality for products and merchants with various sorting options.

### SettingsView
Main settings screen with access to various management features.

### ProductEntryView
Interface for manually entering product information or scanning receipts via OCR.

### PriceComparisonView
Displays price trends for selected products across different merchants.

### Settings Subviews
- `MerchantManagementView`: For managing merchant information
- `BrandManagementView`: For managing brand information
- `DataManagementView`: For importing/exporting data and managing backups
- `StatisticsView`: For viewing data statistics and insights

## 6. Key Classes and Functions

### PriceRecorderApp
The main application entry point that sets up the SwiftData container and defines the tab structure.

```swift
@main
struct PriceRecorderApp: App {
    let container: ModelContainer
    
    init() {
        // Initialize SwiftData container with all models
    }
    
    var body: some Scene {
        // Define main tab view with Home, Search, and Settings tabs
    }
}
```

### MainTabView
Defines the main tab structure of the application.

### OCRService.shared
Singleton instance of the OCR service for text recognition from receipt images.

### CSVService.shared
Singleton instance of the CSV service for data import/export.

### CloudSyncService.shared
Singleton instance of the cloud sync service for iCloud backup and restore.

### ProductRecord Initializer
```swift
init(
    id: UUID = UUID(),
    name: String,
    brand: String? = nil,
    quantity: Double,
    unit: String,
    spec: String? = nil,
    totalPrice: Double,
    merchantID: UUID,
    purchaseDate: Date = Date(),
    receiptPhoto: Data? = nil,
    notes: String? = nil,
    createTime: Date = Date(),
    updateTime: Date = Date()
) {
    // Initializes a product record with the given parameters
    // Automatically calculates unit price
}
```

## 7. Dependency Relationships

### Data Flow
```
Views → Services → Models
```

### Key Relationships
- `ProductRecord` references `Merchant` via `merchantID`
- `Merchant` references `MerchantCategory` via `categoryID`
- `Receipt` references `Merchant` via `merchantID`
- Views use SwiftData queries to access and display model data
- Services interact with models to perform operations like OCR parsing, CSV import/export, and cloud sync

### Service Dependencies
- `OCRService` depends on iOS Vision framework
- `CloudSyncService` depends on CloudKit framework
- All services are singletons accessed via their `shared` property

## 8. Setup and Running Instructions

### Requirements
- Xcode 15.0+
- Swift 5.0+
- iOS 17.0+
- Apple Developer account (for testing on real devices)

### Configuration
1. Open `PriceRecorder.xcodeproj` in Xcode
2. In project settings, configure:
   - Development Team
   - Bundle Identifier (recommended to use a unique identifier)
3. Ensure the minimum deployment target is set to iOS 17.0+

### Permissions
The app requires the following permissions (already configured in Info.plist):
- Camera access (for OCR scanning)
- Photo library access (for selecting receipt images)

### Running the App
1. Select a simulator or connect an iPhone device (iOS 17+)
2. Click the run button (⌘R) or use Product → Run

### Testing
- Use ⌘U to run all tests
- Tests are located in `PriceRecorderTests` and `PriceRecorderUITests` directories

### Common Issues
- **SwiftData not found**: Ensure deployment target is set to iOS 17.0+
- **OCR not working**: Vision framework works best on real devices; performance may be limited on simulators
- **iCloud sync issues**: Ensure device is signed in to iCloud and has internet connectivity

## 9. Additional Resources

### Project Documentation
- [需求文档.md](file:///workspace/需求文档.md) - Detailed requirements
- [设计文档.md](file:///workspace/设计文档.md) - Design documentation
- [测试文档.md](file:///workspace/测试文档.md) - Test documentation
- [编译和运行指南.md](file:///workspace/编译和运行指南.md) - Build and run guide

### Key Files
- [PriceRecorderApp.swift](file:///workspace/PriceRecorder/PriceRecorderApp.swift) - Main application entry
- [ProductRecord.swift](file:///workspace/PriceRecorder/Models/ProductRecord.swift) - Core data model
- [OCRService.swift](file:///workspace/PriceRecorder/Services/OCRService.swift) - OCR functionality
- [HomeView.swift](file:///workspace/PriceRecorder/Views/Home/HomeView.swift) - Main home screen

## 10. Conclusion

PriceRecorder is a comprehensive iOS application for tracking and comparing product prices. Its modular architecture, clear separation of concerns, and use of modern Swift technologies make it a well-structured project. The app provides a user-friendly interface for recording purchases, analyzing price trends, and managing merchant information, all while offering convenient features like OCR receipt scanning and cloud backup.

The codebase is well-organized, with a clear hierarchy of models, views, and services, making it easy to understand and extend. By following the provided setup instructions, developers can quickly get the app running and begin exploring its features or contributing to its development.