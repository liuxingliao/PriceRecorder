//
//  BackupService.swift
//  PriceRecorder
//
//  数据备份服务 - 支持JSON备份含照片
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// 备份选项
enum BackupOption: String, Codable, CaseIterable, Identifiable {
    case all = "全部备份"
    case dataOnly = "仅备份数据"
    case photosOnly = "仅备份照片"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .all: return "备份所有数据和照片"
        case .dataOnly: return "备份商品、商家等数据（不含照片）"
        case .photosOnly: return "仅备份照片数据"
        }
    }
}

struct BackupData: Codable {
    let version: String
    let exportDate: Date
    let backupOption: BackupOption
    let products: [BackupProduct]
    let merchants: [BackupMerchant]
    let categories: [BackupCategory]
}

struct BackupProduct: Codable {
    let id: UUID
    let name: String
    let brand: String?
    let quantity: Double
    let unit: String
    let spec: String?
    let totalPrice: Double
    let unitPrice: Double
    let merchantID: UUID
    let purchaseDate: Date
    let notes: String?
    let createTime: Date
    let updateTime: Date
    let photoData: String? // Base64编码的照片数据，仅当备份照片时存在
    let hasPhoto: Bool // 标记是否有照片（用于仅恢复数据时判断）
}

struct BackupMerchant: Codable {
    let id: UUID
    let name: String
    let categoryID: UUID?
    let createTime: Date
    let updateTime: Date
}

struct BackupCategory: Codable {
    let id: UUID
    let name: String
    let createTime: Date
    let updateTime: Date
}

class BackupService {
    static let shared = BackupService()

    private let fileManager = FileManager.default
    private let currentVersion = "2.0" // 选项版

    private init() {}

    // 创建备份 - 返回临时文件URL
    func createBackup(
        products: [ProductRecord],
        merchants: [Merchant],
        categories: [MerchantCategory],
        option: BackupOption = .all
    ) async throws -> URL {
        let backupData = try await createBackupData(
            products: products,
            merchants: merchants,
            categories: categories,
            option: option
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(backupData)

        let tempDir = fileManager.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"

        let suffix: String
        switch option {
        case .all: suffix = ""
        case .dataOnly: suffix = "_data"
        case .photosOnly: suffix = "_photos"
        }

        let backupURL = tempDir.appendingPathComponent("PriceRecorder_Backup\(suffix)_\(dateFormatter.string(from: Date())).json")
        try jsonData.write(to: backupURL)

        return backupURL
    }

    // 从备份恢复
    func restoreBackup(
        from url: URL,
        modelContext: ModelContext,
        option: BackupOption = .all
    ) async throws -> (successCount: Int, totalCount: Int) {
        let jsonData = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: jsonData)

        // 恢复分类和商家（总是需要的基础数据）
        var categoryIDMap: [UUID: UUID] = [:] // oldID -> newID
        for category in backupData.categories {
            let newCategory = MerchantCategory(
                id: category.id,
                name: category.name,
                createTime: category.createTime,
                updateTime: category.updateTime
            )
            modelContext.insert(newCategory)
            categoryIDMap[category.id] = category.id
        }

        var merchantIDMap: [UUID: UUID] = [:] // oldID -> newID
        for merchant in backupData.merchants {
            let newMerchant = Merchant(
                id: merchant.id,
                name: merchant.name,
                categoryID: merchant.categoryID.flatMap { categoryIDMap[$0] },
                createTime: merchant.createTime,
                updateTime: merchant.updateTime
            )
            modelContext.insert(newMerchant)
            merchantIDMap[merchant.id] = merchant.id
        }

        // 根据选项恢复商品
        var successCount = 0
        let totalCount = backupData.products.count

        for product in backupData.products {
            try Task.checkCancellation()

            guard let merchantID = merchantIDMap[product.merchantID] else {
                continue
            }

            // 根据恢复选项决定是否恢复照片
            var photoData: Data?
            switch option {
            case .all:
                if let photoBase64 = product.photoData, !photoBase64.isEmpty {
                    photoData = Data(base64Encoded: photoBase64)
                }
            case .dataOnly:
                photoData = nil // 不恢复照片
            case .photosOnly:
                // 仅恢复有照片的商品的照片
                if let photoBase64 = product.photoData, !photoBase64.isEmpty {
                    photoData = Data(base64Encoded: photoBase64)
                } else if product.hasPhoto {
                    // 如果标记有照片但没有数据，可能是从数据仅备份恢复的，保留nil
                    photoData = nil
                }
            }

            let newProduct = ProductRecord(
                id: product.id,
                name: product.name,
                brand: product.brand,
                quantity: product.quantity,
                unit: product.unit,
                spec: product.spec,
                totalPrice: product.totalPrice,
                merchantID: merchantID,
                purchaseDate: product.purchaseDate,
                receiptPhoto: photoData,
                notes: product.notes,
                createTime: product.createTime,
                updateTime: product.updateTime
            )
            modelContext.insert(newProduct)
            successCount += 1

            // 每50条保存一次
            if successCount % 50 == 0 {
                try modelContext.save()
            }
        }

        try modelContext.save()

        return (successCount, totalCount)
    }

    // 检查备份文件包含的内容
    func inspectBackup(url: URL) throws -> (option: BackupOption, hasPhotos: Bool, productCount: Int) {
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: jsonData)

        let hasPhotos = backupData.products.contains { $0.photoData != nil }
        return (backupData.backupOption, hasPhotos, backupData.products.count)
    }

    // 创建备份数据结构
    private func createBackupData(
        products: [ProductRecord],
        merchants: [Merchant],
        categories: [MerchantCategory],
        option: BackupOption
    ) async throws -> BackupData {
        var backupProducts: [BackupProduct] = []
        backupProducts.reserveCapacity(products.count)

        let batchSize = 20
        for i in stride(from: 0, to: products.count, by: batchSize) {
            try Task.checkCancellation()

            let batch = products[i..<min(i+batchSize, products.count)]
            for product in batch {
                var photoBase64: String?
                let hasPhoto = product.receiptPhoto != nil

                // 根据备份选项决定是否包含照片
                if option != .dataOnly, let photoData = product.receiptPhoto {
                    photoBase64 = photoData.base64EncodedString(options: [])
                }

                backupProducts.append(BackupProduct(
                    id: product.id,
                    name: product.name,
                    brand: product.brand,
                    quantity: product.quantity,
                    unit: product.unit,
                    spec: product.spec,
                    totalPrice: product.totalPrice,
                    unitPrice: product.unitPrice,
                    merchantID: product.merchantID,
                    purchaseDate: product.purchaseDate,
                    notes: product.notes,
                    createTime: product.createTime,
                    updateTime: product.updateTime,
                    photoData: photoBase64,
                    hasPhoto: hasPhoto
                ))
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        let backupMerchants = merchants.map { merchant in
            BackupMerchant(
                id: merchant.id,
                name: merchant.name,
                categoryID: merchant.categoryID,
                createTime: merchant.createTime,
                updateTime: merchant.updateTime
            )
        }

        let backupCategories = categories.map { category in
            BackupCategory(
                id: category.id,
                name: category.name,
                createTime: category.createTime,
                updateTime: category.updateTime
            )
        }

        return BackupData(
            version: currentVersion,
            exportDate: Date(),
            backupOption: option,
            products: backupProducts,
            merchants: backupMerchants,
            categories: backupCategories
        )
    }
}
