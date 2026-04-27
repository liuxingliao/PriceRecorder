//
//  DataManagementView.swift
//  PriceRecorder
//
//  数据导入导出页
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [ProductRecord]
    @Query private var merchants: [Merchant]
    @Query private var categories: [MerchantCategory]

    @State private var isExportingCSV = false
    @State private var isExportingBackup = false
    @State private var isImporting = false
    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var exportFileURL: URL?
    @State private var backupFileURL: URL?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var importResult: (successCount: Int, totalCount: Int)?
    @State private var restoreResult: (successCount: Int, totalCount: Int)?

    // 备份/恢复选项
    @State private var showingBackupOptions = false
    @State private var showingRestoreOptions = false
    @State private var selectedBackupOption: BackupOption = .all
    @State private var selectedRestoreOption: BackupOption = .all
    @State private var pendingRestoreURL: URL?
    @State private var backupInfo: (option: BackupOption, hasPhotos: Bool, productCount: Int)?

    var body: some View {
        List {
            Section("数据备份") {
                Button(action: {
                    showingBackupOptions = true
                }) {
                    HStack {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.purple)
                        Text("创建备份...")
                        Spacer()
                        if isBackingUp {
                            ProgressView()
                        }
                    }
                }
                .disabled(isBackingUp)

                Button(action: {
                    isRestoring = true
                }) {
                    HStack {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .foregroundColor(.orange)
                        Text("从备份恢复...")
                    }
                }
                .disabled(isRestoring)
            }

            Section("CSV 导入导出") {
                Button(action: {
                    exportCSV()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(.blue)
                        Text("导出 CSV")
                        Spacer()
                        if isExportingCSV {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExportingCSV)

                Button(action: {
                    isImporting = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundColor(.green)
                        Text("导入 CSV")
                    }
                }
            }

            if let result = importResult {
                Section("导入结果") {
                    HStack {
                        Text("成功导入")
                        Spacer()
                        Text("\(result.successCount)/\(result.totalCount) 条")
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let result = restoreResult {
                Section("恢复结果") {
                    HStack {
                        Text("成功恢复")
                        Spacer()
                        Text("\(result.successCount)/\(result.totalCount) 条")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("数据管理")
        .background {
            Color.clear
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.commaSeparatedText, .text],
                    allowsMultipleSelection: false
                ) { result in
                    handleImportResult(result)
                }
        }
        .background {
            Color.clear
                .fileImporter(
                    isPresented: $isRestoring,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { result in
                    handleRestoreFileSelection(result)
                }
        }
        .fileExporter(
            isPresented: $isExportingCSV,
            document: CSVDocument(content: exportFileContent ?? ""),
            contentType: .commaSeparatedText,
            defaultFilename: "PriceRecorder_\(formatDateForFilename(Date())).csv"
        ) { result in
            handleExportResult(result)
        }
        .fileExporter(
            isPresented: $isExportingBackup,
            document: BackupDocument(fileURL: backupFileURL),
            contentType: .json,
            defaultFilename: backupFilename(for: selectedBackupOption)
        ) { result in
            handleBackupExportResult(result)
        }
        .confirmationDialog("选择备份内容", isPresented: $showingBackupOptions, titleVisibility: .visible) {
            ForEach(BackupOption.allCases) { option in
                Button(option.rawValue) {
                    selectedBackupOption = option
                    Task { await createBackup(option: option) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请选择要备份的内容：\n\n• 全部备份：数据+照片（文件最大）\n• 仅备份数据：商品/商家信息（文件小）\n• 仅备份照片：只备份照片数据")
        }
        .sheet(isPresented: $showingRestoreOptions) {
            RestoreOptionsSheet(
                backupInfo: backupInfo ?? (.all, false, 0),
                selectedOption: $selectedRestoreOption,
                onConfirm: {
                    if let url = pendingRestoreURL {
                        Task { await performRestore(url: url, option: selectedRestoreOption) }
                    }
                }
            )
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var exportFileContent: String? {
        guard !products.isEmpty else { return nil }

        let exportData = products.map { product in
            let merchant = merchants.first { $0.id == product.merchantID }
            let category = merchant.flatMap { m in
                categories.first { $0.id == m.categoryID }
            }
            return CSVExportData(
                productName: product.name,
                brand: product.brand,
                quantity: product.quantity,
                unit: product.unit,
                spec: product.spec,
                totalPrice: product.totalPrice,
                unitPrice: product.unitPrice,
                merchantName: merchant?.name ?? "未知",
                merchantCategory: category?.name,
                purchaseDate: product.purchaseDate,
                notes: product.notes,
                createTime: product.createTime,
                updateTime: product.updateTime
            )
        }

        return try? CSVService.shared.exportCSV(data: exportData)
    }

    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }

    private func backupFilename(for option: BackupOption) -> String {
        let dateStr = formatDateForFilename(Date())
        switch option {
        case .all: return "PriceRecorder_Backup_\(dateStr).json"
        case .dataOnly: return "PriceRecorder_Backup_data_\(dateStr).json"
        case .photosOnly: return "PriceRecorder_Backup_photos_\(dateStr).json"
        }
    }

    private func exportCSV() {
        guard let content = exportFileContent, !content.isEmpty else {
            alertTitle = "导出失败"
            alertMessage = "没有数据可导出"
            showingAlert = true
            return
        }

        exportFileURL = createTemporaryFile(content: content)
        isExportingCSV = true
    }

    private func handleBackupExportResult(_ result: Result<URL, Error>) {
        isBackingUp = false
        switch result {
        case .success:
            alertTitle = "备份成功"
            let optionText = selectedBackupOption == .all ? "" : " (\(selectedBackupOption.rawValue))"
            alertMessage = "数据已成功备份\(optionText)"
        case .failure(let error):
            alertTitle = "备份失败"
            alertMessage = error.localizedDescription
        }
        showingAlert = true
    }

    private func createTemporaryFile(content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "PriceRecorder_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        isExportingCSV = false
        switch result {
        case .success:
            alertTitle = "导出成功"
            alertMessage = "数据已成功导出"
        case .failure(let error):
            alertTitle = "导出失败"
            alertMessage = error.localizedDescription
        }
        showingAlert = true
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                importCSV(from: url)
            }
        case .failure(let error):
            alertTitle = "导入失败"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func handleRestoreFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                pendingRestoreURL = url
                do {
                    backupInfo = try BackupService.shared.inspectBackup(url: url)
                    showingRestoreOptions = true
                } catch {
                    alertTitle = "读取备份失败"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        case .failure(let error):
            alertTitle = "选择备份失败"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func createBackup(option: BackupOption) async {
        isBackingUp = true

        do {
            let backupURL = try await BackupService.shared.createBackup(
                products: products,
                merchants: merchants,
                categories: categories,
                option: option
            )

            backupFileURL = backupURL
            isExportingBackup = true
        } catch {
            isBackingUp = false
            alertTitle = "备份失败"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func performRestore(url: URL, option: BackupOption) async {
        isRestoring = true
        showingRestoreOptions = false

        guard url.startAccessingSecurityScopedResource() else {
            alertTitle = "恢复失败"
            alertMessage = "无法访问文件"
            showingAlert = true
            isRestoring = false
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let result = try await BackupService.shared.restoreBackup(
                from: url,
                modelContext: modelContext,
                option: option
            )
            restoreResult = result
            alertTitle = "恢复完成"
            let optionText = option == .all ? "" : " (\(option.rawValue))"
            alertMessage = "成功恢复\(optionText) \(result.successCount)/\(result.totalCount) 条数据"
        } catch {
            alertTitle = "恢复失败"
            alertMessage = error.localizedDescription
        }

        isRestoring = false
        showingAlert = true
    }

    private func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            alertTitle = "导入失败"
            alertMessage = "无法访问文件"
            showingAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let csvData = try CSVService.shared.parseCSV(content)

            var successCount = 0
            var merchantCache: [String: Merchant] = [:]
            var categoryCache: [String: MerchantCategory] = [:]

            for merchant in merchants {
                merchantCache[merchant.name] = merchant
            }
            for category in categories {
                categoryCache[category.name] = category
            }

            for data in csvData {
                let category: MerchantCategory?
                if let categoryName = data.merchantCategory {
                    if let existing = categoryCache[categoryName] {
                        category = existing
                    } else {
                        let newCategory = MerchantCategory(name: categoryName)
                        modelContext.insert(newCategory)
                        categoryCache[categoryName] = newCategory
                        category = newCategory
                    }
                } else {
                    category = nil
                }

                let merchant: Merchant
                if let existing = merchantCache[data.merchantName] {
                    merchant = existing
                } else {
                    merchant = Merchant(
                        name: data.merchantName,
                        categoryID: category?.id
                    )
                    modelContext.insert(merchant)
                    merchantCache[data.merchantName] = merchant
                }

                let product = ProductRecord(
                    name: data.productName,
                    brand: data.brand,
                    quantity: data.quantity,
                    unit: data.unit,
                    spec: data.spec,
                    totalPrice: data.totalPrice,
                    merchantID: merchant.id,
                    purchaseDate: data.purchaseDate,
                    notes: data.notes,
                    createTime: data.createTime,
                    updateTime: data.updateTime
                )
                modelContext.insert(product)
                successCount += 1
            }

            importResult = (successCount, csvData.count)
            alertTitle = "导入完成"
            alertMessage = "成功导入 \(successCount)/\(csvData.count) 条数据"
        } catch {
            alertTitle = "导入失败"
            alertMessage = error.localizedDescription
        }
        showingAlert = true
    }
}

// 恢复选项表单
struct RestoreOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let backupInfo: (option: BackupOption, hasPhotos: Bool, productCount: Int)
    @Binding var selectedOption: BackupOption
    let onConfirm: () -> Void

    var availableOptions: [BackupOption] {
        if backupInfo.option == .dataOnly {
            return [.dataOnly]
        } else if backupInfo.option == .photosOnly {
            return [.photosOnly]
        } else {
            if backupInfo.hasPhotos {
                return [.all, .dataOnly, .photosOnly]
            } else {
                return [.all, .dataOnly]
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("备份信息") {
                    LabeledContent("备份类型", value: backupInfo.option.rawValue)
                    LabeledContent("商品数量", value: "\(backupInfo.productCount)")
                    LabeledContent("包含照片", value: backupInfo.hasPhotos ? "是" : "否")
                }

                Section("选择恢复内容") {
                    Picker("恢复选项", selection: $selectedOption) {
                        ForEach(availableOptions, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)

                    ForEach(availableOptions, id: \.self) { option in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button("开始恢复") {
                        dismiss()
                        onConfirm()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("恢复选项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !availableOptions.contains(selectedOption) {
                    selectedOption = availableOptions.first ?? .all
                }
            }
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .text] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }

    var content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            content = string
        } else {
            content = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content.data(using: .utf8)!)
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .text] }
    static var writableContentTypes: [UTType] { [.json] }

    var content: String

    init(fileURL: URL?) {
        if let url = fileURL, let data = try? Data(contentsOf: url), let string = String(data: data, encoding: .utf8) {
            content = string
        } else {
            content = ""
        }
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            content = string
        } else {
            content = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content.data(using: .utf8)!)
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
    }
    .modelContainer(for: [ProductRecord.self, Merchant.self, MerchantCategory.self], inMemory: true)
}
