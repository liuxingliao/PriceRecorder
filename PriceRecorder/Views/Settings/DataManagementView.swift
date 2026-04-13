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

    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportFileURL: URL?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var importResult: (successCount: Int, totalCount: Int)?

    var body: some View {
        List {
            Section("导出数据") {
                Button(action: {
                    exportCSV()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(.blue)
                        Text("导出 CSV")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
            }

            Section("导入数据") {
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
        }
        .navigationTitle("数据导入导出")
        .fileExporter(
            isPresented: $isExporting,
            document: CSVDocument(content: exportFileContent ?? ""),
            contentType: .commaSeparatedText,
            defaultFilename: "PriceRecorder_\(Date().formatted(.iso8601)).csv"
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
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

    private func exportCSV() {
        guard let content = exportFileContent, !content.isEmpty else {
            alertTitle = "导出失败"
            alertMessage = "没有数据可导出"
            showingAlert = true
            return
        }

        exportFileURL = createTemporaryFile(content: content)
        isExporting = true
    }

    private func createTemporaryFile(content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "PriceRecorder_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        isExporting = false
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

            for data in csvData {
                let category: MerchantCategory?
                if let categoryName = data.merchantCategory {
                    category = categories.first { $0.name == categoryName } ?? {
                        let newCategory = MerchantCategory(name: categoryName)
                        modelContext.insert(newCategory)
                        return newCategory
                    }()
                } else {
                    category = nil
                }

                let merchant: Merchant
                if let existing = merchants.first(where: { $0.name == data.merchantName }) {
                    merchant = existing
                } else {
                    merchant = Merchant(
                        name: data.merchantName,
                        categoryID: category?.id
                    )
                    modelContext.insert(merchant)
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

#Preview {
    NavigationStack {
        DataManagementView()
    }
    .modelContainer(for: [ProductRecord.self, Merchant.self, MerchantCategory.self], inMemory: true)
}
