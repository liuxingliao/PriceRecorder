//
//  LLMService.swift
//  PriceRecorder
//
//  大模型 API 调用服务
//

import Foundation
import SwiftUI
import SwiftData

/// 大模型API调用错误
enum LLMServiceError: LocalizedError {
    case invalidConfig
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case decodingError
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidConfig:
            return "大模型配置无效，请检查配置"
        case .invalidURL:
            return "无效的API地址"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的API响应"
        case .apiError(let message):
            return "API错误: \(message)"
        case .decodingError:
            return "响应解析错误"
        case .cancelled:
            return "请求已取消"
        }
    }
}

/// 聊天消息
struct ChatMessage: Codable {
    let role: String
    let content: String

    enum Role: String {
        case user
        case assistant
        case system
    }

    init(role: Role, content: String) {
        self.role = role.rawValue
        self.content = content
    }
}

/// API请求体
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int?
    let stream: Bool?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case max_tokens
        case stream
    }
}

/// API响应体
struct ChatCompletionResponse: Codable {
    let id: String?
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let index: Int
        let message: ChatMessage
        let finish_reason: String?
    }

    struct Usage: Codable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }
}

/// 豆包API响应格式
struct DoubaoChatResponse: Codable {
    let id: String?
    let choices: [DoubaoChoice]
    let usage: ChatCompletionResponse.Usage?

    struct DoubaoChoice: Codable {
        let index: Int
        let message: ChatMessage
        let finish_reason: String?
    }
}

@MainActor
class LLMService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var debugLogs: [LLMDebugLog] = []
    @AppStorage("isLLMDebugEnabled") private var isDebugEnabled = false

    static let shared = LLMService()

    private init() {}

    /// 发送聊天消息
    /// - Parameters:
    ///   - messages: 消息列表
    ///   - config: LLM配置
    /// - Returns: AI回复内容
    func sendChat(messages: [ChatMessage], config: LLMConfig) async throws -> String {
        isProcessing = true
        errorMessage = nil
        let startTime = Date()

        defer {
            isProcessing = false
        }

        // 验证配置
        guard !config.apiKey.isEmpty, !config.endpoint.isEmpty, !config.model.isEmpty else {
            throw LLMServiceError.invalidConfig
        }

        let provider = config.llmProvider

        // 构建请求
        let request = ChatCompletionRequest(
            model: config.model,
            messages: messages,
            temperature: config.temperature,
            max_tokens: config.maxTokens,
            stream: false
        )

        // 构建URL
        let endpointURL: URL
        switch provider {
        case .doubao:
            guard let url = URL(string: "\(config.endpoint)/chat/completions") else {
                throw LLMServiceError.invalidURL
            }
            endpointURL = url
        case .openai, .custom:
            guard let url = URL(string: "\(config.endpoint)/chat/completions") else {
                throw LLMServiceError.invalidURL
            }
            endpointURL = url
        case .anthropic:
            guard let url = URL(string: "\(config.endpoint)/v1/messages") else {
                throw LLMServiceError.invalidURL
            }
            endpointURL = url
        case .aliyun:
            guard let url = URL(string: "\(config.endpoint)/services/aigc/text-generation/generation") else {
                throw LLMServiceError.invalidURL
            }
            endpointURL = url
        case .baidu:
            guard let url = URL(string: "\(config.endpoint)/chat/completions") else {
                throw LLMServiceError.invalidURL
            }
            endpointURL = url
        }

        // 构建URLRequest
        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 设置认证头
        switch provider {
        case .doubao, .openai, .custom:
            urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        case .anthropic:
            urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
            urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        case .aliyun:
            urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        case .baidu:
            // 百度使用API Key在URL或请求体中
            break
        }

        // 添加自定义请求头
        if let additionalHeaders = provider.defaultHeaders {
            for (key, value) in additionalHeaders {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        // 编码请求体
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let requestBody: Data

        switch provider {
        case .anthropic:
            // Anthropic使用不同的请求格式
            struct AnthropicRequest: Codable {
                let model: String
                let messages: [ChatMessage]
                let max_tokens: Int
                let temperature: Double?
            }
            let anthropicRequest = AnthropicRequest(
                model: config.model,
                messages: messages,
                max_tokens: config.maxTokens,
                temperature: config.temperature
            )
            requestBody = try encoder.encode(anthropicRequest)
        case .aliyun:
            // 阿里云使用不同的请求格式
            struct AliyunRequest: Codable {
                let model: String
                let input: Input
                let parameters: Parameters?

                struct Input: Codable {
                    let messages: [ChatMessage]
                }

                struct Parameters: Codable {
                    let temperature: Double?
                    let max_tokens: Int?
                }
            }
            let aliyunRequest = AliyunRequest(
                model: config.model,
                input: .init(messages: messages),
                parameters: .init(temperature: config.temperature, max_tokens: config.maxTokens)
            )
            requestBody = try encoder.encode(aliyunRequest)
        default:
            requestBody = try encoder.encode(request)
        }

        urlRequest.httpBody = requestBody

        // 记录调试日志
        let requestLog = String(data: requestBody, encoding: .utf8) ?? "无法解析请求体"

        // 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            let duration = Date().timeIntervalSince(startTime)

            // 记录响应
            let responseLog = String(data: data, encoding: .utf8) ?? "无法解析响应"

            // 检查响应状态
            guard let httpResponse = response as? HTTPURLResponse else {
                if isDebugEnabled {
                    let log = LLMDebugLog(
                        timestamp: Date(),
                        request: requestLog,
                        response: responseLog,
                        error: "无效的响应类型",
                        duration: duration
                    )
                    addDebugLog(log)
                }
                throw LLMServiceError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = "HTTP错误: \(httpResponse.statusCode)"
                if isDebugEnabled {
                    let log = LLMDebugLog(
                        timestamp: Date(),
                        request: requestLog,
                        response: responseLog,
                        error: errorMessage,
                        duration: duration
                    )
                    addDebugLog(log)
                }
                throw LLMServiceError.apiError(errorMessage)
            }

            // 解析响应
            let decoder = JSONDecoder()
            var responseContent: String = ""

            switch provider {
            case .anthropic:
                struct AnthropicResponse: Codable {
                    let content: [ContentBlock]
                    let usage: Usage?

                    struct ContentBlock: Codable {
                        let type: String
                        let text: String?
                    }

                    struct Usage: Codable {
                        let input_tokens: Int?
                        let output_tokens: Int?
                    }
                }

                let anthropicResponse = try decoder.decode(AnthropicResponse.self, from: data)
                responseContent = anthropicResponse.content.compactMap { $0.text }.joined(separator: "\n")

            case .aliyun:
                struct AliyunResponse: Codable {
                    let output: Output
                    let usage: Usage?

                    struct Output: Codable {
                        let text: String?
                        let finish_reason: String?
                    }

                    struct Usage: Codable {
                        let input_tokens: Int?
                        let output_tokens: Int?
                        let total_tokens: Int?
                    }
                }

                let aliyunResponse = try decoder.decode(AliyunResponse.self, from: data)
                responseContent = aliyunResponse.output.text ?? ""

            case .doubao:
                let doubaoResponse = try decoder.decode(DoubaoChatResponse.self, from: data)
                guard let firstChoice = doubaoResponse.choices.first else {
                    throw LLMServiceError.invalidResponse
                }
                responseContent = firstChoice.message.content

            default:
                let completionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
                guard let firstChoice = completionResponse.choices.first else {
                    throw LLMServiceError.invalidResponse
                }
                responseContent = firstChoice.message.content
            }

            // 记录调试日志
            if isDebugEnabled {
                let log = LLMDebugLog(
                    timestamp: Date(),
                    request: requestLog,
                    response: responseLog,
                    error: nil,
                    duration: duration
                )
                addDebugLog(log)
            }

            return responseContent

        } catch let error as LLMServiceError {
            throw error
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            if isDebugEnabled {
                let log = LLMDebugLog(
                    timestamp: Date(),
                    request: requestLog,
                    response: nil,
                    error: error.localizedDescription,
                    duration: duration
                )
                addDebugLog(log)
            }
            throw LLMServiceError.networkError(error)
        }
    }

    /// 添加调试日志
    private func addDebugLog(_ log: LLMDebugLog) {
        debugLogs.insert(log, at: 0)
        // 只保留最近100条
        if debugLogs.count > 100 {
            debugLogs = Array(debugLogs.prefix(100))
        }
    }

    /// 清空调试日志
    func clearDebugLogs() {
        debugLogs.removeAll()
    }
}
