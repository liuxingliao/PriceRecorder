//
//  APIConfigView.swift
//  PriceRecorder
//
//  豆包链接配置页面
//

import SwiftUI
import SwiftData

struct APIConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var config: APIConfig

    var body: some View {
        Form {
            Section("豆包链接配置") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("豆包链接")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("https://www.doubao.com/building/code/...", text: $config.doubaoLink)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }
            }

            Section("说明") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("如何获取豆包链接")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("1. 打开豆包应用或网站\n2. 创建或打开一个对话\n3. 复制浏览器地址栏中的链接")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("豆包配置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    config.updateTime = Date()
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        APIConfigView(config: APIConfig())
    }
    .modelContainer(for: APIConfig.self, inMemory: true)
}
