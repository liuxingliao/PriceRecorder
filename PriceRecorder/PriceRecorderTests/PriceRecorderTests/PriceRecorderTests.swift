//
//  PriceRecorderTests.swift
//  PriceRecorderTests
//
//  单元测试 - 数据模型和服务层测试
//

import XCTest
import SwiftData
@testable import PriceRecorder

final class PriceRecorderTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            ProductRecord.self,
            Merchant.self,
            MerchantCategory.self,
            Brand.self,
            Receipt.self
        ])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - ProductRecord 模型测试

    func testProductRecordCreation() throws {
        let merchantId = UUID()
        let product = ProductRecord(
            name: "测试商品",
            brand: "测试品牌",
            quantity: 2,
            unit: "个",
            spec: "500g",
            totalPrice: 20.0,
            merchantID: merchantId,
            purchaseDate: Date()
        )

        XCTAssertEqual(product.name, "测试商品")
        XCTAssertEqual(product.brand, "测试品牌")
        XCTAssertEqual(product.quantity, 2)
        XCTAssertEqual(product.unit, "个")
        XCTAssertEqual(product.spec, "500g")
        XCTAssertEqual(product.totalPrice, 20.0)
        XCTAssertEqual(product.unitPrice, 10.0)
        XCTAssertEqual(product.merchantID, merchantId)
    }

    func testProductRecordUnitPriceCalculation() throws {
        let merchantId = UUID()

        let product1 = ProductRecord(
            name: "商品1",
            quantity: 5,
            unit: "个",
            totalPrice: 50.0,
            merchantID: merchantId
        )
        XCTAssertEqual(product1.unitPrice, 10.0, accuracy: 0.001)

        let product2 = ProductRecord(
            name: "商品2",
            quantity: 0,
            unit: "个",
            totalPrice: 100.0,
            merchantID: merchantId
        )
        XCTAssertEqual(product2.unitPrice, 0, "数量为0时单价应为0")
    }

    func testProductRecordPersistance() throws {
        let merchantId = UUID()
        let product = ProductRecord(
            name: "持久化测试商品",
            quantity: 1,
            unit: "瓶",
            totalPrice: 15.5,
            merchantID: merchantId
        )

        context.insert(product)
        try context.save()

        let fetchDescriptor = FetchDescriptor<ProductRecord>(
            predicate: #Predicate { $0.name == "持久化测试商品" }
        )
        let results = try context.fetch(fetchDescriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.totalPrice, 15.5)
    }

    // MARK: - Merchant 模型测试

    func testMerchantCreation() throws {
        let categoryId = UUID()
        let merchant = Merchant(
            name: "测试超市",
            categoryID: categoryId,
            address: "测试地址123号",
            phone: "13800138000",
            notes: "测试备注"
        )

        XCTAssertEqual(merchant.name, "测试超市")
        XCTAssertEqual(merchant.categoryID, categoryId)
        XCTAssertEqual(merchant.address, "测试地址123号")
        XCTAssertEqual(merchant.phone, "13800138000")
        XCTAssertEqual(merchant.notes, "测试备注")
    }

    func testMerchantCategory() throws {
        let category = MerchantCategory(name: "生鲜超市")
        let merchant = Merchant(
            name: "测试商家",
            categoryID: category.id
        )

        context.insert(category)
        context.insert(merchant)
        try context.save()

        let fetchMerchant = try context.fetch(FetchDescriptor<Merchant>()).first
        XCTAssertEqual(fetchMerchant?.categoryID, category.id)
    }

    // MARK: - Brand 模型测试

    func testBrandCreation() throws {
        let brand = Brand(name: "可口可乐")
        XCTAssertEqual(brand.name, "可口可乐")
    }

    func testBrandPersistance() throws {
        let brand = Brand(name: "百事可乐")
        context.insert(brand)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Brand>())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "百事可乐")
    }

    // MARK: - Receipt 模型测试

    func testReceiptCreation() throws {
        let merchantId = UUID()
        let testData = "test photo data".data(using: .utf8)

        let receipt = Receipt(
            merchantID: merchantId,
            purchaseDate: Date(),
            photo: testData,
            notes: "测试小票备注"
        )

        XCTAssertEqual(receipt.merchantID, merchantId)
        XCTAssertNotNil(receipt.photo)
        XCTAssertEqual(receipt.notes, "测试小票备注")
    }

    // MARK: - CSVService 测试

    func testCSVExport() throws {
        let service = CSVService.shared

        let testDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let data = CSVExportData(
            productName: "测试商品",
            brand: "测试品牌",
            quantity: 2,
            unit: "个",
            spec: "大包装",
            totalPrice: 25.5,
            unitPrice: 12.75,
            merchantName: "测试商家",
            merchantCategory: "超市",
            purchaseDate: testDate,
            notes: "测试备注",
            createTime: testDate,
            updateTime: testDate
        )

        let csv = try service.exportCSV(data: [data])

        XCTAssertTrue(csv.contains("商品名称"))
        XCTAssertTrue(csv.contains("测试商品"))
        XCTAssertTrue(csv.contains("测试品牌"))
        XCTAssertTrue(csv.contains("测试商家"))
    }

    func testCSVParse() throws {
        let service = CSVService.shared

        let testCSV = """
        商品名称,品牌,数量,单位,规格,总价,单价,商家名称,商家分类,购买时间,备注,创建时间,更新时间
        苹果,红富士,5,斤,一级,25.0,5.0,生鲜超市,水果,2024-01-15 10:30:00,新鲜,2024-01-15 10:30:00,2024-01-15 10:30:00
        牛奶,蒙牛,2,盒,250ml,12.0,6.0,便利店,食品,2024-01-16 14:20:00,,2024-01-16 14:20:00,2024-01-16 14:20:00
        """

        let results = try service.parseCSV(testCSV)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].productName, "苹果")
        XCTAssertEqual(results[0].quantity, 5)
        XCTAssertEqual(results[0].totalPrice, 25.0)
        XCTAssertEqual(results[1].productName, "牛奶")
        XCTAssertEqual(results[1].brand, "蒙牛")
    }

    func testCSVEscape() throws {
        let service = CSVService.shared

        let data = CSVExportData(
            productName: "商品,包含,逗号",
            brand: nil,
            quantity: 1,
            unit: "个",
            spec: nil,
            totalPrice: 10.0,
            unitPrice: 10.0,
            merchantName: "商家\"包含\"引号",
            merchantCategory: nil,
            purchaseDate: Date(),
            notes: nil,
            createTime: Date(),
            updateTime: Date()
        )

        let csv = try service.exportCSV(data: [data])
        XCTAssertTrue(csv.contains("\"商品,包含,逗号\""))
        XCTAssertTrue(csv.contains("\"商家\"\"包含\"\"引号\""))
    }

    // MARK: - OCRService 测试

    func testOCRServiceInitialization() throws {
        let service = OCRService.shared
        XCTAssertNotNil(service)
    }

    func testPendingProductCreation() throws {
        let product = PendingProduct(
            name: "待定商品",
            quantity: 3,
            unit: "瓶",
            totalPrice: 30.0
        )

        XCTAssertEqual(product.name, "待定商品")
        XCTAssertEqual(product.quantity, 3)
        XCTAssertEqual(product.unit, "瓶")
        XCTAssertEqual(product.totalPrice, 30.0)
    }

    // MARK: - CloudSyncService 测试

    func testCloudSyncServiceInitialization() throws {
        let service = CloudSyncService.shared
        XCTAssertNotNil(service)
    }

    func testCloudSyncAutoBackupSetting() throws {
        let service = CloudSyncService.shared

        service.saveAutoBackupSetting(true)
        XCTAssertTrue(service.autoBackupEnabled)

        service.saveAutoBackupSetting(false)
        XCTAssertFalse(service.autoBackupEnabled)
    }

    // MARK: - 边界条件测试

    func testEmptyProductName() throws {
        let merchantId = UUID()
        let product = ProductRecord(
            name: "",
            quantity: 1,
            unit: "个",
            totalPrice: 10.0,
            merchantID: merchantId
        )
        XCTAssertEqual(product.name, "")
    }

    func testNegativePrice() throws {
        let merchantId = UUID()
        let product = ProductRecord(
            name: "测试",
            quantity: 1,
            unit: "个",
            totalPrice: -5.0,
            merchantID: merchantId
        )
        XCTAssertEqual(product.totalPrice, -5.0)
    }

    func testVeryLargeQuantity() throws {
        let merchantId = UUID()
        let product = ProductRecord(
            name: "大宗商品",
            quantity: 999999.999,
            unit: "吨",
            totalPrice: 999999999.99,
            merchantID: merchantId
        )
        XCTAssertEqual(product.quantity, 999999.999, accuracy: 0.001)
    }

    // MARK: - 数据关系测试

    func testProductMerchantRelationship() throws {
        let category = MerchantCategory(name: "测试分类")
        let merchant = Merchant(name: "测试商家", categoryID: category.id)
        let product = ProductRecord(
            name: "关联商品",
            quantity: 1,
            unit: "个",
            totalPrice: 100.0,
            merchantID: merchant.id
        )

        context.insert(category)
        context.insert(merchant)
        context.insert(product)
        try context.save()

        let products = try context.fetch(FetchDescriptor<ProductRecord>())
        let merchants = try context.fetch(FetchDescriptor<Merchant>())

        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(merchants.count, 1)
        XCTAssertEqual(products.first?.merchantID, merchants.first?.id)
    }

    // MARK: - 删除测试

    func testDeleteProduct() throws {
        let merchantId = UUID()
        let product = ProductRecord(
            name: "待删除商品",
            quantity: 1,
            unit: "个",
            totalPrice: 10.0,
            merchantID: merchantId
        )

        context.insert(product)
        try context.save()

        var products = try context.fetch(FetchDescriptor<ProductRecord>())
        XCTAssertEqual(products.count, 1)

        context.delete(product)
        try context.save()

        products = try context.fetch(FetchDescriptor<ProductRecord>())
        XCTAssertEqual(products.count, 0)
    }
}
