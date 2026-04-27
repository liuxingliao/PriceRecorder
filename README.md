# 商品价格记录 - iOS应用

## 项目简介

这是一个用于记录和比较不同商家商品价格的iOS应用，支持豆包智能录入、数据导入导出、数据备份等功能。

## 技术栈

- **语言**: Swift 5.0+
- **UI框架**: SwiftUI
- **数据持久化**: SwiftData
- **最低系统版本**: iOS 17.0+
- **图表**: SwiftCharts

## 项目结构

```
PriceRecorder/
├── PriceRecorder.xcodeproj/          # Xcode项目文件
├── README.md                          # 本说明文档
├── 需求文档.md                        # 详细需求文档
├── 测试文档.md                        # 测试文档
├── 设计文档.md                        # 设计文档
├── 编译和运行指南.md                # 编译指南
├── 代码文档.md                        # 代码文档
└── PriceRecorder/
    ├── PriceRecorderApp.swift         # 主应用入口
    ├── Info.plist                     # 应用配置
    ├── Models/                        # 数据模型
    │   ├── ProductRecord.swift
    │   ├── Merchant.swift
    │   ├── MerchantCategory.swift
    │   ├── Receipt.swift
    │   ├── APIConfig.swift
    │   ├── AIMessage.swift            # AI对话消息模型
    │   ├── LLMConfig.swift            # 大模型配置模型
    │   └── LLMDebugLog.swift          # 大模型调试日志模型
    ├── Views/                         # 页面视图
    │   ├── Home/
    │   │   ├── HomeView.swift        # 首页
    │   │   └── ProductDetailView.swift
    │   ├── Search/
    │   │   ├── SearchView.swift      # 搜索页
    │   │   └── AIChatView.swift      # AI咨询对话页
    │   ├── Settings/
    │   │   ├── SettingsView.swift
    │   │   ├── MerchantManagementView.swift
    │   │   ├── DataManagementView.swift
    │   │   ├── StatisticsView.swift
    │   │   ├── APIConfigView.swift
    │   │   ├── LLMConfigView.swift   # 大模型配置页
    │   │   └── DebugConfigView.swift # 调试配置页
    │   ├── ProductEntry/
    │   │   ├── ProductEntryView.swift
    │   │   └── DoubaoEntryView.swift
    │   ├── PriceComparison/
    │   │   └── PriceComparisonView.swift
    │   └── Components/
    │       ├── CommonComponents.swift
    │       ├── LocationPicker.swift   # 地图位置选择器
    │       └── PhotoViewer.swift      # 照片查看器
    └── Services/                      # 服务层
        ├── OCRService.swift
        ├── CSVService.swift
        ├── CloudSyncService.swift
        ├── LLMService.swift           # 大模型API调用服务
        └── BackupService.swift        # 数据备份服务
```

## 功能特性

### 核心功能
- ✅ 首页 - 显示最近10条录入商品
- ✅ 商品录入 - 支持手动输入和豆包智能录入
- ✅ 豆包录入 - 通过豆包获取JSON数据，一键解析录入
- ✅ 搜索页面 - 商品/商家模式切换，多种排序方式
- ✅ 比价功能 - 选择商品和商家，显示历史价格趋势图
- ✅ 商家管理 - 商家增删改查，分类管理
- ✅ 数据导入导出 - CSV格式，全部字段，支持商家去重
- ✅ 数据备份 - 完整备份功能，支持备份选项
- ✅ 数据统计 - 商品数、商家数、总支出等
- ✅ 暗黑模式 - 完整支持

### v1.2 版本优化
- ⚡ 搜索性能优化 - 修复N+1查询问题，大幅提升大数据量搜索性能
- 🛡️ 输入验证 - 完整的商品录入验证，防止无效数据
- 📸 OCR优化 - 图片压缩，Async/Await支持，内存占用优化

### v1.3 功能增强
- 🔍 比价搜索 - 价格对比页面支持商品名称搜索
- 🗺️ 地图选择 - 商家地址支持地图选择器
- 🗑️ 商家删除 - 商家管理支持删除，有商品时提示保护
- ☁️ iCloud配置 - iCloud备份UI隐藏，移至调试配置中
- 🔢 商家数量配置 - 价格对比最大商家数量可配置（默认5）
- 🏷️ 品牌显示 - 搜索结果显示商品品牌信息
- 📊 数量精度 - 首页和搜索页数量显示4位小数
- 🖼️ 照片查看 - 商品详情支持照片放大查看和删除
- 🗑️ 商品删除 - 搜索结果支持删除，编辑页底部添加删除按钮
- 📸 照片质量 - 照片从尺寸裁剪改为质量压缩，支持10%-100%质量调节
- 📈 数据统计 - 增加照片数量和数据占用空间统计
- 📱 图表交互 - 比价图表支持左右滑动查看更多数据，点击/长按显示详细价格和购买时间
- 📊 图表时间范围 - 图表支持日/周/月/年时间范围切换
- 📊 统计增强 - 数据统计页面显示所有商家列表，点击商家弹窗显示消费额、商品数、分类统计
- 💾 数据备份 - 完整的数据备份功能，包括照片备份和恢复
- 📋 备份选项 - 支持选择备份内容：全部备份/仅备份数据/仅备份照片
- 🤖 AI咨询 - 搜索页面添加AI咨询入口，支持与大模型对话查询数据分析
- ⚙️ 大模型配置 - 支持豆包、OpenAI、Claude、阿里云、百度等多种大模型配置
- 🧪 接口测试 - 大模型配置页面支持一键测试API连接
- 🔧 调试配置 - 添加调试配置页面，支持查看大模型API调用日志
- 🔤 输入限制 - 所有输入字段添加合理的字符长度限制

## 如何使用

### 在Xcode中打开项目

1. 打开 `PriceRecorder.xcodeproj`
2. 在项目设置中配置：
   - Development Team（开发团队）
   - Bundle Identifier（建议修改为唯一标识）
3. 选择模拟器或连接iPhone设备（iOS 17+）
4. 点击运行按钮（⌘R）

### 豆包录入使用说明

1. 在商品录入页面选择"豆包录入"
2. 点击"打开豆包"按钮，在豆包中复制商品JSON数据
3. 将JSON数据粘贴到编辑框
4. 点击"解析商品"按钮
5. 确认商品列表，选择商家和购买时间
6. 点击保存完成录入

### 配置豆包链接

在"设置" → "豆包配置"中可以配置自定义的豆包链接。

### 数据备份使用说明

1. 在"设置" → "数据管理"中选择"创建备份"
2. 选择备份内容：
   - 全部备份：备份所有数据和照片
   - 仅备份数据：只备份商品、商家等数据（不含照片）
   - 仅备份照片：只备份照片数据
3. 备份文件保存到文件App中
4. 恢复时选择备份文件，可选择恢复内容

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

### Q: 豆包录入的JSON格式是什么？
A: JSON格式示例：
```json
[
  {
    "name": "商品名称",
    "quantity": 1.0,
    "unit": "个",
    "totalPrice": 10.0,
    "spec": "规格（可选）"
  }
]
```

### Q: 如何修改Bundle Identifier？
A: 在项目设置 → Targets → PriceRecorder → General → Bundle Identifier中修改。

### Q: CSV导入时商家重复怎么办？
A: 已修复此问题，导入时会自动去重，同一商家只会创建一条记录。

## 开发者信息

- 开发工具: Xcode 15.0+
- Swift版本: 5.0+
- 最低支持: iOS 17.0

## 许可证

本项目仅供学习和参考使用。
