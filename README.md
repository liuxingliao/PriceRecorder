# 商品价格记录 - iOS应用

## 项目简介

这是一个用于记录和比较不同商家商品价格的iOS应用，支持OCR小票识别、数据导入导出、iCloud备份等功能。

## 技术栈

- **语言**: Swift 5.0+
- **UI框架**: SwiftUI
- **数据持久化**: SwiftData
- **最低系统版本**: iOS 17.0+
- **OCR**: iOS Vision框架
- **图表**: SwiftCharts

## 项目结构

```
PriceRecorder/
├── PriceRecorder.xcodeproj/          # Xcode项目文件
├── README.md                          # 本说明文档
├── 需求文档.md                        # 详细需求文档
├── 测试文档.md                        # 测试文档
└── PriceRecorder/
    ├── PriceRecorderApp.swift         # 主应用入口
    ├── Info.plist                     # 应用配置
    ├── Models/                        # 数据模型
    │   ├── ProductRecord.swift
    │   ├── Merchant.swift
    │   ├── MerchantCategory.swift
    │   ├── Brand.swift
    │   └── Receipt.swift
    ├── Views/                         # 页面视图
    │   ├── Home/
    │   │   ├── HomeView.swift        # 首页
    │   │   └── ProductDetailView.swift
    │   ├── Search/
    │   │   └── SearchView.swift      # 搜索页
    │   ├── Settings/
    │   │   ├── SettingsView.swift
    │   │   ├── MerchantManagementView.swift
    │   │   ├── BrandManagementView.swift
    │   │   ├── DataManagementView.swift
    │   │   └── StatisticsView.swift
    │   ├── ProductEntry/
    │   │   └── ProductEntryView.swift
    │   ├── PriceComparison/
    │   │   └── PriceComparisonView.swift
    │   └── Components/
    │       └── CommonComponents.swift
    └── Services/                      # 服务层
        ├── OCRService.swift
        ├── CSVService.swift
        └── CloudSyncService.swift

PriceRecorderTests/                    # 单元测试
└── PriceRecorderTests.swift

PriceRecorderUITests/                   # UI测试
└── PriceRecorderUITests.swift
```

## 功能特性

### 核心功能
- ✅ 首页 - 显示最近10条录入商品
- ✅ 商品录入 - 支持手动输入和拍照OCR识别
- ✅ 搜索页面 - 商品/商家模式切换，多种排序方式
- ✅ 比价功能 - 选择商品和商家，显示历史价格趋势图
- ✅ 商家管理 - 商家增删改查，分类管理
- ✅ 品牌管理 - 品牌列表管理
- ✅ 数据导入导出 - CSV格式，全部字段
- ✅ iCloud备份 - 手动+自动备份
- ✅ 数据统计 - 商品数、商家数、总支出等
- ✅ 暗黑模式 - 完整支持

## 如何使用

### 在Xcode中打开项目

1. 打开 `PriceRecorder.xcodeproj`
2. 在项目设置中配置：
   - Development Team（开发团队）
   - Bundle Identifier（建议修改为唯一标识）
3. 选择模拟器或连接iPhone设备（iOS 17+）
4. 点击运行按钮（⌘R）

### 配置权限

项目需要以下权限，已在Info.plist中配置：
- 相机访问权限（拍照）
- 相册访问权限（选择图片）

## 添加测试Target（可选）

如果需要添加单元测试和UI测试，请在Xcode中手动添加：

### 添加单元测试Target

1. 打开项目，选择项目导航器
2. 点击项目名称，选择 "Targets"
3. 点击 "+" 按钮添加新Target
4. 选择 "iOS Unit Testing Bundle"
5. 产品名称：PriceRecorderTests
6. 点击 "Finish"
7. 将 `PriceRecorderTests/PriceRecorderTests.swift` 文件添加到这个Target中

### 添加UI测试Target

1. 同样点击 "+" 按钮添加新Target
2. 选择 "iOS UI Testing Bundle"
3. 产品名称：PriceRecorderUITests
4. 点击 "Finish"
5. 将 `PriceRecorderUITests/PriceRecorderUITests.swift` 文件添加到这个Target中

## 运行测试

### 在Xcode中运行
- 使用快捷键 `⌘U` 运行所有测试
- 或选择 Product → Test

### 运行特定测试
- 在测试导航器中点击特定测试旁边的播放按钮

### 命令行运行
```bash
# 运行所有测试
xcodebuild test -scheme PriceRecorder -destination 'platform=iOS Simulator,name=iPhone 15'

# 只运行单元测试
xcodebuild test -scheme PriceRecorder -only-testing:PriceRecorderTests

# 只运行UI测试
xcodebuild test -scheme PriceRecorder -only-testing:PriceRecorderUITests
```

## 编译测试

### Debug编译
```bash
xcodebuild -scheme PriceRecorder -configuration Debug build
```

### Release编译
```bash
xcodebuild -scheme PriceRecorder -configuration Release build
```

### 清理并编译
```bash
xcodebuild clean build -scheme PriceRecorder
```

## 测试文档

详细的测试用例和测试流程请参考 `测试文档.md`。

## 需求文档

详细的需求说明请参考 `需求文档.md`。

## 常见问题

### Q: 编译报错说找不到SwiftData？
A: 确保部署目标设置为iOS 17.0或更高版本。

### Q: OCR识别不工作？
A: Vision框架需要在真机上才能获得最佳效果，模拟器上也可以工作但性能较差。

### Q: 如何修改Bundle Identifier？
A: 在项目设置 → Targets → PriceRecorder → General → Bundle Identifier中修改。

## 开发者信息

- 开发工具: Xcode 15.0+
- Swift版本: 5.0+
- 最低支持: iOS 17.0

## 许可证

本项目仅供学习和参考使用。
