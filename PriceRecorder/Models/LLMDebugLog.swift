//
//  LLMDebugLog.swift
//  PriceRecorder
//
//  大模型调试日志模型
//

import Foundation

struct LLMDebugLog: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let request: String
    let response: String?
    let error: String?
    let duration: TimeInterval
}
