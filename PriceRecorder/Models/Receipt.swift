//
//  Receipt.swift
//  PriceRecorder
//
//  小票模型
//

import Foundation
import SwiftData

@Model
final class Receipt {
    @Attribute(.unique) var id: UUID
    var merchantID: UUID
    var purchaseDate: Date
    var photo: Data?
    var notes: String?
    var createTime: Date

    init(
        id: UUID = UUID(),
        merchantID: UUID,
        purchaseDate: Date = Date(),
        photo: Data? = nil,
        notes: String? = nil,
        createTime: Date = Date()
    ) {
        self.id = id
        self.merchantID = merchantID
        self.purchaseDate = purchaseDate
        self.photo = photo
        self.notes = notes
        self.createTime = createTime
    }
}
