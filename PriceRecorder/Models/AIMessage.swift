//
//  AIMessage.swift
//  PriceRecorder
//
//  AI对话消息模型
//

import Foundation
import SwiftData

/// 消息角色枚举
enum AIMessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

/// AI对话消息模型
@Model
final class AIMessage {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var role: String
    var content: String
    var tokenCount: Int?
    var createTime: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        role: String = AIMessageRole.user.rawValue,
        content: String,
        tokenCount: Int? = nil,
        createTime: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.role = role
        self.content = content
        self.tokenCount = tokenCount
        self.createTime = createTime
    }
    
    /// 获取当前消息的角色枚举值
    var messageRole: AIMessageRole {
        AIMessageRole(rawValue: role) ?? .user
    }
}

/// AI对话会话模型（用于管理多会话）
@Model
final class AISession {
    @Attribute(.unique) var id: UUID
    var title: String
    var lastMessageTime: Date
    var createTime: Date

    init(
        id: UUID = UUID(),
        title: String = "新对话",
        lastMessageTime: Date = Date(),
        createTime: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.lastMessageTime = lastMessageTime
        self.createTime = createTime
    }
    
    /// 更新最后消息时间
    func updateLastMessageTime() {
        lastMessageTime = Date()
    }
}
