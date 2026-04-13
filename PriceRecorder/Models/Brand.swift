//
//  Brand.swift
//  PriceRecorder
//
//  品牌模型
//

import Foundation
import SwiftData

@Model
final class Brand {
    @Attribute(.unique) var id: UUID
    var name: String
    var createTime: Date

    init(
        id: UUID = UUID(),
        name: String,
        createTime: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createTime = createTime
    }
}
