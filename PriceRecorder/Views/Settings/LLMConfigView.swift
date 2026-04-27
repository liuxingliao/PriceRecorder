//
//  LLMConfigView.swift
//  PriceRecorder
//
//  大语言模型配置界面
//

import SwiftUI
import SwiftData

struct LLMConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var configs: [LLMConfig]

    @State private var showingAddConfig = false
    @State private var editingConfig: LLMConfig?

    var body: some View {
        List {
            ForEach(configs) { config in
                ConfigRow(config: config)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingConfig = config
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteConfig(config)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("AI模型配置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddConfig = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddConfig) {
            ConfigEditView(config: nil)
        }
        .sheet(item: $editingConfig) { config in
            ConfigEditView(config: config)
        }
        .onAppear {
            // 如果没有配置，创建默认配置
            if configs.isEmpty {
                createDefaultConfigs()
            }
        }
    }

    private func createDefaultConfigs() {
        for provider in LLMProvider.allCases {
            let config = LLMConfig(
                provider: provider.rawValue,
                endpoint: provider.defaultEndpoint,
                model: provider.defaultModel
            )
            modelContext.insert(config)
        }
        try? modelContext.save()
    }

    private func deleteConfig(_ config: LLMConfig) {
        modelContext.delete(config)
        try? modelContext.save()
    }
}

struct ConfigRow: View {
    @Environment(\.modelContext) private var modelContext
    let config: LLMConfig

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(config.llmProvider.rawValue)
                        .font(.headline)
                    if config.isEnabled {
                        Text("已启用")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                Text(config.model)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: toggleEnabled) {
                Image(systemName: config.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(config.isEnabled ? .green : .secondary)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
    }

    private func toggleEnabled() {
        // 切换启用状态
        let newState = !config.isEnabled

        // 如果要启用这个配置，先禁用其他所有配置
        if newState {
            let descriptor = FetchDescriptor<LLMConfig>()
            if let allConfigs = try? modelContext.fetch(descriptor) {
                for c in allConfigs {
                    c.isEnabled = false
                }
            }
        }

        config.isEnabled = newState
        config.touch()
        try? modelContext.save()
    }
}

struct ConfigEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let config: LLMConfig?

    @State private var provider: LLMProvider = .openai
    @State private var apiKey: String = ""
    @State private var endpoint: String = ""
    @State private var model: String = ""
    @State private var isEnabled: Bool = false
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 2000

    @State private var isTesting = false
    @State private var testResult: String?
    @State private var showTestResult = false

    var body: some View {
        Form {
            Section("基本设置") {
                Picker("提供商", selection: $provider) {
                    ForEach(LLMProvider.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .onChange(of: provider) { _, newValue in
                    endpoint = newValue.defaultEndpoint
                    model = newValue.defaultModel
                }

                SecureField("API Key", text: $apiKey)
                TextField("Endpoint", text: $endpoint)
                TextField("Model", text: $model)
            }

            Section("高级设置") {
                Toggle("启用配置", isOn: $isEnabled)

                VStack(alignment: .leading) {
                    HStack {
                        Text("温度: \(String(format: "%.2f", temperature))")
                        Spacer()
                    }
                    Slider(value: $temperature, in: 0...2, step: 0.1)
                }

                HStack {
                    Text("最大Token数")
                    Spacer()
                    TextField("", value: $maxTokens, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .frame(width: 120)
                }
            }

            Section("测试连接") {
                Button(action: testConnection) {
                    HStack {
                        Text("测试接口")
                        Spacer()
                        if isTesting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isTesting || apiKey.isEmpty || endpoint.isEmpty || model.isEmpty)

                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.contains("成功") ? .green : .red)
                }
            }

            Section {
                Button(action: {
                    saveConfig()
                    dismiss()
                }) {
                    HStack {
                        Spacer()
                        Text("保存配置")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(apiKey.isEmpty || endpoint.isEmpty || model.isEmpty)
            }
        }
        .navigationTitle(config == nil ? "添加配置" : "编辑配置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveConfig()
                    dismiss()
                }
                .disabled(apiKey.isEmpty || endpoint.isEmpty || model.isEmpty)
            }
        }
        .onAppear {
            if let config = config {
                provider = config.llmProvider
                apiKey = config.apiKey
                endpoint = config.endpoint
                model = config.model
                isEnabled = config.isEnabled
                temperature = config.temperature
                maxTokens = config.maxTokens
            }
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        let testConfig = LLMConfig(
            provider: provider.rawValue,
            apiKey: apiKey,
            endpoint: endpoint,
            model: model,
            isEnabled: false,
            temperature: 0.7,
            maxTokens: 100
        )

        Task {
            do {
                let response = try await LLMService.shared.sendChat(
                    messages: [ChatMessage(role: .user, content: "你好，请回复'测试成功'")],
                    config: testConfig
                )

                await MainActor.run {
                    if response.contains("测试成功") || !response.isEmpty {
                        testResult = "✅ 测试成功！接口工作正常"
                    } else {
                        testResult = "⚠️ 接口返回但内容异常"
                    }
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ 测试失败: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }

    private func saveConfig() {
        if let existing = config {
            // 直接更新现有配置
            existing.provider = provider.rawValue
            existing.apiKey = apiKey
            existing.endpoint = endpoint
            existing.model = model
            existing.isEnabled = isEnabled
            existing.temperature = temperature
            existing.maxTokens = maxTokens
            existing.touch()

            // 如果启用了这个配置，禁用其他配置
            if isEnabled {
                let descriptor = FetchDescriptor<LLMConfig>()
                if let allConfigs = try? modelContext.fetch(descriptor) {
                    for c in allConfigs {
                        if c.id != existing.id {
                            c.isEnabled = false
                        }
                    }
                }
            }
        } else {
            // 创建新配置
            let newConfig = LLMConfig(
                provider: provider.rawValue,
                apiKey: apiKey,
                endpoint: endpoint,
                model: model,
                isEnabled: isEnabled,
                temperature: temperature,
                maxTokens: maxTokens
            )
            modelContext.insert(newConfig)

            // 如果启用了这个配置，禁用其他配置
            if isEnabled {
                let descriptor = FetchDescriptor<LLMConfig>()
                if let allConfigs = try? modelContext.fetch(descriptor) {
                    for c in allConfigs {
                        if c.id != newConfig.id {
                            c.isEnabled = false
                        }
                    }
                }
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("保存配置失败: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        LLMConfigView()
    }
    .modelContainer(for: LLMConfig.self, inMemory: true)
}
