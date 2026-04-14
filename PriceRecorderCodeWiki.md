# PriceRecorder 代码维基

## 1. 项目概述

PriceRecorder 是一款 iOS 应用程序，用于记录和比较不同商家的商品价格。它支持 OCR 小票识别、数据导入导出、iCloud 备份以及价格趋势分析。

### 主要功能
- ✅ 商品录入（手动输入和 OCR 小票识别）
- ✅ 价格比较与历史趋势
- ✅ 商家和品牌管理
- ✅ 数据导入导出（CSV 格式）
- ✅ iCloud 备份（手动和自动）
- ✅ 统计和数据洞察
- ✅ 暗黑模式支持

### 技术栈
- **编程语言**: Swift 5.0+
- **UI 框架**: SwiftUI
- **数据持久化**: SwiftData
- **最低 iOS 版本**: 17.0+
- **OCR**: iOS Vision 框架
- **图表**: SwiftCharts

## 2. 架构

项目采用清晰的架构，关注点分离明确：

```
PriceRecorder/
├── Models/          # 使用 SwiftData 的数据模型
├── Views/           # SwiftUI 视图
│   ├── Home/        # 首页
│   ├── Search/      # 搜索功能
│   ├── Settings/    # 设置和管理页面
│   ├── ProductEntry/ # 商品录入页面
│   ├── PriceComparison/ # 价格比较页面
│   └── Components/  # 可重用 UI 组件
└── Services/        # 服务层
    ├── OCRService.swift     # OCR 文字识别
    ├── CSVService.swift     # CSV 导入导出
    └── CloudSyncService.swift # iCloud 同步
```

### 架构原则
- **数据驱动**: 使用 SwiftData 进行响应式数据管理
- **模块化**: 模型、视图和服务之间清晰分离
- **响应式**: 利用 SwiftUI 的声明式语法和 Combine 进行状态管理
- **服务导向**: 将复杂功能封装在专用服务类中

## 3. 数据模型

### ProductRecord
表示商品购买记录的核心模型。

| 属性 | 类型 | 描述 |
|------|------|------|
| id | UUID | 唯一标识符 |
| name | String | 商品名称 |
| brand | String? | 商品品牌 |
| quantity | Double | 购买数量 |
| unit | String | 计量单位 |
| spec | String? | 商品规格 |
| totalPrice | Double | 总价 |
| unitPrice | Double | 单价 |
| merchantID | UUID | 关联的商家 ID |
| purchaseDate | Date | 购买日期 |
| receiptPhoto | Data? | 小票图片数据 |
| notes | String? | 附加备注 |
| createTime | Date | 记录创建时间 |
| updateTime | Date | 最后更新时间 |

### Merchant
表示购买商品的商店或商家。

| 属性 | 类型 | 描述 |
|------|------|------|
| id | UUID | 唯一标识符 |
| name | String | 商家名称 |
| categoryID | UUID? | 关联的分类 ID |
| address | String? | 商家地址 |
| phone | String? | 商家电话号码 |
| notes | String? | 附加备注 |
| createTime | Date | 记录创建时间 |
| updateTime | Date | 最后更新时间 |

### MerchantCategory
表示用于分类商家的类别。

| 属性 | 类型 | 描述 |
|------|------|------|
| id | UUID | 唯一标识符 |
| name | String | 分类名称 |
| createTime | Date | 记录创建时间 |

### Brand
表示商品品牌。

| 属性 | 类型 | 描述 |
|------|------|------|
| id | UUID | 唯一标识符 |
| name | String | 品牌名称 |
| createTime | Date | 记录创建时间 |

### Receipt
表示购买小票。

| 属性 | 类型 | 描述 |
|------|------|------|
| id | UUID | 唯一标识符 |
| merchantID | UUID | 关联的商家 ID |
| purchaseDate | Date | 购买日期 |
| photo | Data? | 小票图片数据 |
| notes | String? | 附加备注 |
| createTime | Date | 记录创建时间 |

## 4. 服务

### OCRService
使用 iOS Vision 框架处理小票图片的文字识别。

#### 核心函数
- `recognizeText(from:completion:)`: 从图片中识别文字
- `parseReceiptItems(from:)`: 将 OCR 结果解析为商品项
- `parseLine(_:)`: 从 OCR 结果中解析单独的行
- `parseQuantity(_:)`: 从商品名称中提取数量信息

### CSVService
处理 CSV 格式的数据导入和导出。

#### 核心函数
- `exportCSV(data:)`: 将商品数据导出为 CSV 格式
- `parseCSV(_:)`: 将 CSV 数据解析为商品记录
- `escapeCSVField(_:)`: 转义 CSV 字段中的特殊字符
- `parseCSVLine(_:)`: 从 CSV 数据中解析单独的行

### CloudSyncService
处理 iCloud 同步，用于数据备份和恢复。

#### 核心函数
- `backupToCloud(modelContext:completion:)`: 将数据备份到 iCloud
- `restoreFromCloud(completion:)`: 从 iCloud 恢复数据
- `triggerAutoBackupIfNeeded(modelContext:)`: 如启用则自动备份数据
- `saveAutoBackupSetting(_:)`: 保存自动备份设置

## 5. 视图

### HomeView
主屏幕，显示最近录入的商品并提供商品录入入口。

#### 核心组件
- `ProductRow`: 在列表中显示单独的商品记录
- 导航到 `ProductEntryView` 和 `ProductDetailView`

### SearchView
为商品和商家提供搜索功能，并支持多种排序方式。

### SettingsView
主设置屏幕，可访问各种管理功能。

### ProductEntryView
用于手动输入商品信息或通过 OCR 扫描小票的界面。

### PriceComparisonView
显示所选商品在不同商家的价格趋势。

### 设置子视图
- `MerchantManagementView`: 用于管理商家信息
- `BrandManagementView`: 用于管理品牌信息
- `DataManagementView`: 用于导入/导出数据和管理备份
- `StatisticsView`: 用于查看数据统计和洞察

## 6. 核心类和函数

### PriceRecorderApp
主应用程序入口点，设置 SwiftData 容器并定义标签结构。

```swift
@main
struct PriceRecorderApp: App {
    let container: ModelContainer
    
    init() {
        // 使用所有模型初始化 SwiftData 容器
    }
    
    var body: some Scene {
        // 定义带有首页、搜索和设置标签的主标签视图
    }
}
```

### MainTabView
定义应用程序的主标签结构。

### OCRService.shared
OCR 服务的单例实例，用于从小票图片中识别文字。

### CSVService.shared
CSV 服务的单例实例，用于数据导入/导出。

### CloudSyncService.shared
云同步服务的单例实例，用于 iCloud 备份和恢复。

### ProductRecord 初始化器
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
    // 使用给定参数初始化商品记录
    // 自动计算单价
}
```

## 7. 依赖关系

### 数据流
```
Views → Services → Models
```

### 关键关系
- `ProductRecord` 通过 `merchantID` 引用 `Merchant`
- `Merchant` 通过 `categoryID` 引用 `MerchantCategory`
- `Receipt` 通过 `merchantID` 引用 `Merchant`
- 视图使用 SwiftData 查询访问和显示模型数据
- 服务与模型交互，执行 OCR 解析、CSV 导入/导出和云同步等操作

### 服务依赖
- `OCRService` 依赖于 iOS Vision 框架
- `CloudSyncService` 依赖于 CloudKit 框架
- 所有服务都是单例，通过其 `shared` 属性访问

## 8. 设置和运行说明

### 要求
- Xcode 15.0+
- Swift 5.0+
- iOS 17.0+
- Apple 开发者账户（用于在真实设备上测试）

### 配置
1. 在 Xcode 中打开 `PriceRecorder.xcodeproj`
2. 在项目设置中配置：
   - 开发团队
   - Bundle Identifier（建议使用唯一标识符）
3. 确保最低部署目标设置为 iOS 17.0+

### 权限
应用程序需要以下权限（已在 Info.plist 中配置）：
- 相机访问权限（用于 OCR 扫描）
- 相册访问权限（用于选择小票图片）

### 运行应用程序
1. 选择模拟器或连接 iPhone 设备（iOS 17+）
2. 点击运行按钮（⌘R）或使用 Product → Run

### 测试
- 使用 ⌘U 运行所有测试
- 测试位于 `PriceRecorderTests` 和 `PriceRecorderUITests` 目录中

### 常见问题
- **找不到 SwiftData**: 确保部署目标设置为 iOS 17.0+
- **OCR 不工作**: Vision 框架在真实设备上效果最佳；在模拟器上性能可能受限
- **iCloud 同步问题**: 确保设备已登录 iCloud 并具有网络连接

## 9. 额外资源

### 项目文档
- [需求文档.md](file:///workspace/需求文档.md) - 详细需求
- [设计文档.md](file:///workspace/设计文档.md) - 设计文档
- [测试文档.md](file:///workspace/测试文档.md) - 测试文档
- [编译和运行指南.md](file:///workspace/编译和运行指南.md) - 构建和运行指南

### 关键文件
- [PriceRecorderApp.swift](file:///workspace/PriceRecorder/PriceRecorderApp.swift) - 主应用程序入口
- [ProductRecord.swift](file:///workspace/PriceRecorder/Models/ProductRecord.swift) - 核心数据模型
- [OCRService.swift](file:///workspace/PriceRecorder/Services/OCRService.swift) - OCR 功能
- [HomeView.swift](file:///workspace/PriceRecorder/Views/Home/HomeView.swift) - 主首页

## 10. 结论

PriceRecorder 是一款全面的 iOS 应用程序，用于跟踪和比较商品价格。其模块化架构、清晰的关注点分离以及现代 Swift 技术的使用使其成为一个结构良好的项目。该应用程序提供了一个用户友好的界面，用于记录购买、分析价格趋势和管理商家信息，同时提供 OCR 小票扫描和云备份等便捷功能。

代码库组织良好，具有清晰的模型、视图和服务层次结构，使其易于理解和扩展。通过遵循提供的设置说明，开发人员可以快速运行应用程序并开始探索其功能或为其开发做出贡献。
