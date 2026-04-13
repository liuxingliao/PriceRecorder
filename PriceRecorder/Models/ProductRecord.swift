//
//  ProductRecord.swift
//  PriceRecorder
//
//  商品记录模型
//

import Foundation
import SwiftData

@Model
final class ProductRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var quantity: Double
    var unit: String
    var spec: String?
    var totalPrice: Double
    var unitPrice: Double
    var merchantID: UUID
    var purchaseDate: Date
    var receiptPhoto: Data?
    var notes: String?
    var createTime: Date
    var updateTime: Date

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
        self.id = id
        self.name = name
        self.brand = brand
        self.quantity = quantity
        self.unit = unit
        self.spec = spec
        self.totalPrice = totalPrice
        self.unitPrice = quantity > 0 ? totalPrice / quantity : 0
        self.merchantID = merchantID
        self.purchaseDate = purchaseDate
        self.receiptPhoto = receiptPhoto
        self.notes = notes
        self.createTime = createTime
        self.updateTime = updateTime
    }
}
