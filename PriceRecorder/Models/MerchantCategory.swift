//
//  MerchantCategory.swift
//  PriceRecorder
//
//  商家分类模型
//

import Foundation
import SwiftData

@Model
final class MerchantCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var createTime: Date
    var updateTime: Date

    init(
        id: UUID = UUID(),
        name: String,
        createTime: Date = Date(),
        updateTime: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createTime = createTime
        self.updateTime = updateTime
    }
}
