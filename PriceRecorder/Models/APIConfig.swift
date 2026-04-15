//
//  APIConfig.swift
//  PriceRecorder
//
//  豆包配置模型
//

import Foundation
import SwiftData

@Model
final class APIConfig {
    @Attribute(.unique) var id: UUID
    var doubaoLink: String
    var createTime: Date
    var updateTime: Date

    init(
        id: UUID = UUID(),
        doubaoLink: String = "https://www.doubao.com/building/code/XZXSDHHKVjq1inNb?auto_play_bgm=1",
        createTime: Date = Date(),
        updateTime: Date = Date()
    ) {
        self.id = id
        self.doubaoLink = doubaoLink
        self.createTime = createTime
        self.updateTime = updateTime
    }
}
