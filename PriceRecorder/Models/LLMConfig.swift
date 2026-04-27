//
//  LLMConfig.swift
//  PriceRecorder
//
//  大模型配置模型
//

import Foundation
import SwiftData

/// 大模型类型枚举
enum LLMProvider: String, Codable, CaseIterable {
    case doubao = "豆包"
    case openai = "OpenAI"
    case anthropic = "Anthropic Claude"
    case aliyun = "阿里云通义千问"
    case baidu = "百度文心一言"
    case custom = "自定义"

    var defaultEndpoint: String {
        switch self {
        case .doubao:
            return "https://ark.cn-beijing.volces.com/api/v3"
        case .openai:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com"
        case .aliyun:
            return "https://dashscope.aliyuncs.com/api/v1"
        case .baidu:
            return "https://qianfan.baidubce.com/v2"
        case .custom:
            return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .doubao:
            return "ep-20240604163754-5l2wj"
        case .openai:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-haiku-20240307"
        case .aliyun:
            return "qwen-turbo"
        case .baidu:
            return "ernie-4.0-8k"
        case .custom:
            return ""
        }
    }

    var defaultHeaders: [String: String]? {
        switch self {
        case .doubao:
            return ["Content-Type": "application/json"]
        default:
            return nil
        }
    }
}

@Model
final class LLMConfig {
    @Attribute(.unique) var id: UUID
    var provider: String
    var apiKey: String
    var endpoint: String
    var model: String
    var isEnabled: Bool
    var temperature: Double
    var maxTokens: Int
    var createTime: Date
    var updateTime: Date

    init(
        id: UUID = UUID(),
        provider: String = LLMProvider.openai.rawValue,
        apiKey: String = "",
        endpoint: String = LLMProvider.openai.defaultEndpoint,
        model: String = LLMProvider.openai.defaultModel,
        isEnabled: Bool = false,
        temperature: Double = 0.7,
        maxTokens: Int = 2000,
        createTime: Date = Date(),
        updateTime: Date = Date()
    ) {
        self.id = id
        self.provider = provider
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
        self.isEnabled = isEnabled
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.createTime = createTime
        self.updateTime = updateTime
    }
    
    /// 获取当前配置的LLMProvider枚举值
    var llmProvider: LLMProvider {
        LLMProvider(rawValue: provider) ?? .openai
    }
    
    /// 更新配置时的时间戳
    func touch() {
        updateTime = Date()
    }
}
