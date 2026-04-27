//
//  AIChatView.swift
//  PriceRecorder
//
//  AI咨询对话界面
//

import SwiftUI
import SwiftData

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var messages: [AIMessage]
    @Query private var configs: [LLMConfig]
    @Query private var sessions: [AISession]

    @State private var inputText = ""
    @State private var selectedSession: AISession?
    @State private var showingConfig = false
    @State private var showingSessionList = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false

    @StateObject private var llmService = LLMService.shared

    private var activeConfig: LLMConfig? {
        configs.first { $0.isEnabled } ?? configs.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                ScrollViewReader { proxy in
                    List {
                        ForEach(messages.filter { $0.sessionID == selectedSession?.id }) { message in
                            MessageRow(message: message)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .id(message.id)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // 输入区域
                Divider()
                HStack(spacing: 12) {
                    Button(action: { showingSessionList = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        inputText += "/商品咨询："
                    }) {
                        Text("/商品咨询")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }

                    TextField("输入你的问题...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)

                    Button(action: sendMessage) {
                        if isProcessing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                }
                .padding()
            }
            .navigationTitle("AI咨询")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingConfig = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingConfig) {
                NavigationStack {
                    LLMConfigView()
                }
            }
            .sheet(isPresented: $showingSessionList) {
                NavigationStack {
                    SessionListView(selectedSession: $selectedSession)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "未知错误")
            }
            .onAppear {
                initializeSession()
            }
        }
    }

    private func initializeSession() {
        // 如果没有会话，创建一个新的
        let descriptor = FetchDescriptor<AISession>()
        if let existingSession = try? modelContext.fetch(descriptor).first {
            selectedSession = existingSession
        } else {
            let newSession = AISession()
            modelContext.insert(newSession)
            selectedSession = newSession
            try? modelContext.save()
        }
    }

    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, let session = selectedSession else { return }

        inputText = ""
        isProcessing = true

        // 添加用户消息
        let userMessage = AIMessage(
            sessionID: session.id,
            role: AIMessageRole.user.rawValue,
            content: trimmedText
        )
        modelContext.insert(userMessage)
        try? modelContext.save()

        Task {
            let response = await generateResponse(for: trimmedText, session: session)

            await MainActor.run {
                let aiMessage = AIMessage(
                    sessionID: session.id,
                    role: AIMessageRole.assistant.rawValue,
                    content: response
                )
                modelContext.insert(aiMessage)

                session.updateLastMessageTime()
                try? modelContext.save()
                isProcessing = false
            }
        }
    }

    @Query private var products: [ProductRecord]
    @Query private var merchantsQuery: [Merchant]

    private func generateResponse(for userInput: String, session: AISession) async -> String {
        guard let config = activeConfig else {
            return fallbackResponse(for: userInput)
        }

        var systemPrompt = """
        你是一个专业的价格记录助手。你的任务是帮助用户分析消费数据、比较价格趋势、推荐购买建议等。

        你的特点：
        - 专业但友好
        - 回答简洁明了
        - 基于数据给出建议
        - 如果数据不足，诚实告知

        用户可以使用"/商品咨询："前缀来请求基于其数据的分析。
        """

        var userMessage = userInput

        // 如果包含商品咨询前缀，添加商品数据
        if userInput.lowercased().contains("/商品咨询：") {
            // 构建商品数据摘要
            var productSummary = "当前用户的商品数据：\n"
            let productGroups = Dictionary(grouping: products) { $0.name }
            for (name, records) in productGroups.prefix(20) {
                let latest = records.max { $0.purchaseDate < $1.purchaseDate }
                if let latest = latest, let merchant = merchantsQuery.first(where: { $0.id == latest.merchantID }) {
                    productSummary += "- \(name): \(records.count)次记录, 最新¥\(String(format: "%.2f", latest.unitPrice))/\(latest.unit) (\(merchant.name), \(latest.purchaseDate.formatted(date: .abbreviated, time: .omitted)))\n"
                }
            }
            if productGroups.count > 20 {
                productSummary += "...（还有\(productGroups.count - 20)种商品）\n"
            }

            systemPrompt += "\n\n\(productSummary)"
        }

        var chatMessages: [ChatMessage] = [
            ChatMessage(role: .system, content: systemPrompt)
        ]

        // 添加历史消息
        let sessionMessages = messages
            .filter { $0.sessionID == session.id }
            .sorted { $0.createTime < $1.createTime }

        for msg in sessionMessages {
            if let role = ChatMessage.Role(rawValue: msg.role) {
                chatMessages.append(ChatMessage(role: role, content: msg.content))
            }
        }

        do {
            let response = try await llmService.sendChat(messages: chatMessages, config: config)
            return response
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
            return "抱歉，发生了错误：\(error.localizedDescription)\n\n请检查您的API配置后重试。"
        }
    }

    private func fallbackResponse(for userInput: String) -> String {
        let lowercased = userInput.lowercased()

        if lowercased.contains("/商品咨询：") {
            // 构建商品数据摘要
            var productSummary = "当前商品数据：\n"
            let productGroups = Dictionary(grouping: products) { $0.name }
            for (name, records) in productGroups.prefix(20) {
                let latest = records.max { $0.purchaseDate < $1.purchaseDate }
                if let latest = latest, let merchant = merchantsQuery.first(where: { $0.id == latest.merchantID }) {
                    productSummary += "- \(name): \(records.count)次记录, 最新¥\(String(format: "%.2f", latest.unitPrice))/\(latest.unit) (\(merchant.name), \(latest.purchaseDate.formatted(date: .abbreviated, time: .omitted)))\n"
                }
            }
            if productGroups.count > 20 {
                productSummary += "...（还有\(productGroups.count - 20)种商品）\n"
            }

            return """
            \(productSummary)

            基于您的数据，我可以帮您：
            1. 分析价格趋势
            2. 推荐最划算的商家
            3. 统计消费习惯
            4. 对比不同商品价格

            请问您想了解哪方面的信息？
            """
        }

        // 普通对话回复
        return "你好！我是价格记录助手。我可以帮你分析消费数据、比较价格趋势、推荐购买建议等。\n\n使用 \"/商品咨询：\" 前缀，我可以基于您录入的商品数据为您提供分析建议。\n\n请先在设置中配置您的API密钥以启用完整功能。"
    }
}

struct MessageRow: View {
    let message: AIMessage

    private var isUser: Bool {
        message.messageRole == .user
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer()
            }

            if !isUser {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(16)
                    .textSelection(.enabled)

                Text(message.createTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if isUser {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
            }

            if !isUser {
                Spacer()
            }
        }
    }
}

struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AISession.lastMessageTime, order: .reverse) private var sessions: [AISession]

    @Binding var selectedSession: AISession?

    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Section {
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            title: "暂无对话历史",
                            message: "开始新对话后会保存在这里"
                        )
                    }
                } else {
                    Section("历史对话") {
                        ForEach(sessions) { session in
                            Button(action: {
                                selectedSession = session
                                dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.headline)
                                    Text(session.lastMessageTime.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Section {
                        Button(action: {
                            let newSession = AISession()
                            modelContext.insert(newSession)
                            try? modelContext.save()
                            selectedSession = newSession
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "plus.bubble.fill")
                                    .foregroundColor(.blue)
                                Text("新建对话")
                            }
                        }
                    }
                }
            }
            .navigationTitle("历史对话")
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
    AIChatView()
        .modelContainer(for: [AIMessage.self, AISession.self, LLMConfig.self, ProductRecord.self, Merchant.self], inMemory: true)
}
