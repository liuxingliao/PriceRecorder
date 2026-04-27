//
//  DebugConfigView.swift
//  PriceRecorder
//
//  调试配置页
//

import SwiftUI
import SwiftData

struct DebugConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var llmService = LLMService.shared

    @AppStorage("maxMerchantCountForComparison") private var maxMerchantCountForComparison = 5
    @AppStorage("photoQualityPercent") private var photoQualityPercent = 80
    @AppStorage("isLLMDebugEnabled") private var isLLMDebugEnabled = false

    @State private var showLogDetail: LLMDebugLog?
    @State private var showClearLogsAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("比价配置") {
                    HStack {
                        Text("最多选择商家数量")
                        Spacer()
                        Stepper("\(maxMerchantCountForComparison)", value: $maxMerchantCountForComparison, in: 1...10)
                    }
                }

                Section("照片质量") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("照片质量")
                            Spacer()
                            Text("\(photoQualityPercent)%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(photoQualityPercent) },
                            set: { photoQualityPercent = Int($0) }
                        ), in: 10...100, step: 5)
                    }
                }

                Section("大模型调试") {
                    Toggle("启用大模型调试", isOn: $isLLMDebugEnabled)
                        .onChange(of: isLLMDebugEnabled) { _, _ in
                            if isLLMDebugEnabled {
                                // 刷新日志
                            }
                        }
                }

                if isLLMDebugEnabled && !llmService.debugLogs.isEmpty {
                    Section("调试日志（最近\(llmService.debugLogs.count)条）") {
                        ForEach(llmService.debugLogs.prefix(20)) { log in
                            Button {
                                showLogDetail = log
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(formatDate(log.timestamp))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(String(format: "%.2fs", log.duration))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(log.error == nil ? "成功" : "失败")
                                        .font(.caption)
                                        .foregroundColor(log.error == nil ? .green : .red)
                                }
                            }
                        }

                        Button(role: .destructive) {
                            showClearLogsAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("清空日志")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("调试配置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $showLogDetail) { log in
                DebugLogDetailView(log: log)
            }
            .alert("确认清空", isPresented: $showClearLogsAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    llmService.clearDebugLogs()
                }
            } message: {
                Text("确定要清空所有调试日志吗？")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct DebugLogDetailView: View {
    let log: LLMDebugLog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 基本信息
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("时间")
                                .font(.headline)
                            Spacer()
                            Text(log.timestamp.formatted())
                        }
                        HStack {
                            Text("耗时")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f秒", log.duration))
                        }
                        if let error = log.error {
                            HStack(alignment: .top) {
                                Text("错误")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Spacer()
                                Text(error)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // 请求信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("请求")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(log.request)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                    // 响应信息
                    if let response = log.response {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("响应")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: true) {
                                Text(response)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("调试详情")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DebugConfigView()
}
