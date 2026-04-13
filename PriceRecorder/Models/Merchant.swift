//
//  Merchant.swift
//  PriceRecorder
//
//  商家模型
//

import Foundation
import SwiftData

@Model
final class Merchant {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryID: UUID?
    var address: String?
    var phone: String?
    var notes: String?
    var createTime: Date
    var updateTime: Date

    init(
        id: UUID = UUID(),
        name: String,
        categoryID: UUID? = nil,
        address: String? = nil,
        phone: String? = nil,
        notes: String? = nil,
        createTime: Date = Date(),
        updateTime: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.categoryID = categoryID
        self.address = address
        self.phone = phone
        self.notes = notes
        self.createTime = createTime
        self.updateTime = updateTime
    }
}
