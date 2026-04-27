//
//  DoubaoEntryView.swift
//  PriceRecorder
//
//  豆包商品录入入口视图
//

import SwiftUI
import SwiftData

struct DoubaoEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var apiConfigs: [APIConfig]

    @State private var jsonText: String = ""
    @State private var isParsing = false
    @State private var parseError: String?
    @State private var parsedProducts: [PendingProduct] = []
    @State private var showingProductList = false

    var currentConfig: APIConfig {
        if let config = apiConfigs.first {
            return config
        }
        let newConfig = APIConfig()
        modelContext.insert(newConfig)
        try? modelContext.save()
        return newConfig
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 提示信息
                    VStack(spacing: 12) {
                        Text("使用豆包智能录入商品")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "1.circle.fill")
                                    .foregroundColor(.blue)
                                Text("点击下方按钮，在豆包中复制商品数据")
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "2.circle.fill")
                                    .foregroundColor(.blue)
                                Text("将 JSON 数据粘贴到下方编辑框")
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "3.circle.fill")
                                    .foregroundColor(.blue)
                                Text("点击\"解析商品\"按钮，确认后保存")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.top)

                    // 打开豆包按钮
                    Button(action: {
                        if let url = URL(string: currentConfig.doubaoLink) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "safari.fill")
                                .font(.title2)
                            Text("打开豆包")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }

                    // JSON 编辑框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JSON 商品数据")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $jsonText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // 解析按钮
                    Button(action: {
                        parseJSON()
                    }) {
                        HStack {
                            if isParsing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.right.doc.on.clipboard")
                                Text("解析商品")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(jsonText.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(10)
                    }
                    .disabled(jsonText.isEmpty || isParsing)

                    if let error = parseError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("豆包录入")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showingProductList) {
                DoubaoProductListView(products: $parsedProducts, onSave: {
                    dismiss()
                })
            }
        }
    }

    private func parseJSON() {
        isParsing = true
        parseError = nil

        let jsonData = jsonText.data(using: .utf8)!

        do {
            let items = try JSONDecoder().decode([DoubaoProductItem].self, from: jsonData)

            parsedProducts = items.map { item in
                PendingProduct(
                    name: item.name,
                    brand: nil,
                    quantity: item.quantity,
                    unit: item.unit,
                    spec: item.spec,
                    totalPrice: item.totalPrice,
                    notes: nil,
                    receiptPhoto: nil
                )
            }

            isParsing = false
            showingProductList = true
        } catch {
            parseError = "解析失败: \(error.localizedDescription)\n请检查 JSON 格式是否正确"
            isParsing = false
        }
    }
}

struct DoubaoProductItem: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let totalPrice: Double
    let spec: String?
}

struct DoubaoProductListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var products: [PendingProduct]
    let onSave: () -> Void

    @State private var selectedMerchantID: UUID?
    @State private var purchaseDate = Date()
    @State private var showingMerchantSelector = false
    @State private var showingAddMerchant = false
    @State private var editingProduct: PendingProduct?

    @Query(sort: \Merchant.name) private var merchants: [Merchant]

    var selectedMerchant: Merchant? {
        if let id = selectedMerchantID {
            return merchants.first { $0.id == id }
        }
        return nil
    }

    var canSave: Bool {
        !products.isEmpty && selectedMerchantID != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("商品列表 (\(products.count))") {
                    ForEach($products) { $product in
                        PendingProductRow(product: product)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingProduct = product
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    products.removeAll { $0.id == product.id }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)

            bottomBar
        }
        .navigationTitle("确认商品")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    // 返回编辑
                }
            }
        }
        .sheet(item: $editingProduct) { product in
            ProductEditSheet(product: product) { updated in
                if let index = products.firstIndex(where: { $0.id == product.id }) {
                    products[index] = updated
                }
            }
        }
        .sheet(isPresented: $showingMerchantSelector) {
            MerchantSelectionSheet(selectedMerchantID: $selectedMerchantID, showingAddMerchant: $showingAddMerchant)
        }
        .sheet(isPresented: $showingAddMerchant) {
            MerchantEditView(merchant: nil)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("商家")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button(action: { showingMerchantSelector = true }) {
                            HStack {
                                if let merchant = selectedMerchant {
                                    Text(merchant.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("选择商家")
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("购买时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $purchaseDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                }

                Button(action: save) {
                    Text("保存 \(products.count) 件商品")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!canSave)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    private func save() {
        guard let merchantID = selectedMerchantID else { return }

        for pending in products {
            let product = ProductRecord(
                name: pending.name.isEmpty ? "未知商品" : pending.name,
                brand: pending.brand,
                quantity: pending.quantity,
                unit: pending.unit,
                spec: pending.spec,
                totalPrice: pending.totalPrice,
                merchantID: merchantID,
                purchaseDate: purchaseDate,
                receiptPhoto: pending.receiptPhoto,
                notes: pending.notes
            )
            modelContext.insert(product)
        }

        onSave()
    }
}

#Preview {
    NavigationStack {
        DoubaoEntryView()
    }
    .modelContainer(for: [APIConfig.self, Merchant.self, ProductRecord.self], inMemory: true)
}
