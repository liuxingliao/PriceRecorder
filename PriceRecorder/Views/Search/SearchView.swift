//
//  SearchView.swift
//  PriceRecorder
//
//  搜索页
//

import SwiftUI
import SwiftData

enum SearchMode: String, CaseIterable {
    case product = "商品模式"
    case merchant = "商家模式"
}

enum SortOption: String, CaseIterable {
    case time = "按时间"
    case price = "按价格"
    case name = "按名称"
}

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProducts: [ProductRecord]
    @Query private var merchants: [Merchant]

    @State private var searchText = ""
    @State private var searchMode: SearchMode = .product
    @State private var sortOption: SortOption = .time
    @State private var showingSortOptions = false
    @State private var selectedProduct: ProductRecord?
    @State private var showingPriceComparison = false
    @State private var productToDelete: ProductRecord?
    @State private var showingDeleteAlert = false
    @State private var showingAIChat = false

    // 商家字典缓存，避免重复查找
    private var merchantById: [UUID: Merchant] {
        Dictionary(uniqueKeysWithValues: merchants.map { ($0.id, $0) })
    }

    // 使用任务修饰符缓存过滤结果，避免重复计算
    var filteredProducts: [ProductRecord] {
        var products = searchText.isEmpty ? allProducts : allProducts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }

        switch sortOption {
        case .time:
            products.sort { $0.purchaseDate > $1.purchaseDate }
        case .price:
            products.sort { $0.totalPrice < $1.totalPrice }
        case .name:
            products.sort { $0.name < $1.name }
        }

        return products
    }

    var merchantGroupedResults: [(merchant: Merchant, products: [ProductRecord])] {
        let filtered = filteredProducts
        var groups: [UUID: [ProductRecord]] = [:]

        for product in filtered {
            groups[product.merchantID, default: []].append(product)
        }

        let merchantDict = merchantById
        return groups.compactMap { merchantId, products in
            guard let merchant = merchantDict[merchantId] else {
                return nil
            }
            return (merchant, products)
        }.sorted { $0.merchant.name < $1.merchant.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索商品名称...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    HStack {
                        Picker("模式", selection: $searchMode) {
                            ForEach(SearchMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        Button(action: {
                            showingSortOptions = true
                        }) {
                            HStack(spacing: 4) {
                                Text(sortOption.rawValue)
                                    .font(.subheadline)
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding()

                if filteredProducts.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: searchText.isEmpty ? "还没有商品记录" : "未找到相关商品",
                        message: searchText.isEmpty ? "先去首页录入一些商品吧" : "试试其他关键词"
                    )
                } else {
                    List {
                        switch searchMode {
                        case .product:
                            productResultsSection
                        case .merchant:
                            merchantResultsSection
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("搜索")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAIChat = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                            Text("AI咨询")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("比价") {
                        showingPriceComparison = true
                    }
                }
            }
            .confirmationDialog("排序方式", isPresented: $showingSortOptions) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
            }
            .navigationDestination(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
            .navigationDestination(isPresented: $showingPriceComparison) {
                PriceComparisonView()
            }
            .sheet(isPresented: $showingAIChat) {
                AIChatView()
            }
            .alert("确认删除商品?", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let product = productToDelete {
                        modelContext.delete(product)
                    }
                }
            } message: {
                if let product = productToDelete {
                    Text("确定要删除商品「\(product.name)」吗？此操作不可恢复。")
                } else {
                    Text("确定要删除此商品吗？此操作不可恢复。")
                }
            }
        }
    }

    private var productResultsSection: some View {
        Section("搜索结果 (\(filteredProducts.count))") {
            let merchantDict = merchantById
            ForEach(filteredProducts) { product in
                let merchantName = merchantDict[product.merchantID]?.name ?? "未知商家"
                SearchProductRow(product: product, merchantName: merchantName)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProduct = product
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            productToDelete = product
                            showingDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var merchantResultsSection: some View {
        ForEach(merchantGroupedResults, id: \.merchant.id) { group in
            Section(group.merchant.name) {
                if let latest = group.products.first {
                    SearchMerchantRow(merchant: group.merchant, latestProduct: latest)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProduct = latest
                        }
                }
            }
        }
    }
}

struct SearchProductRow: View {
    let product: ProductRecord
    let merchantName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(product.name)
                    .font(.headline)
                Spacer()
                Text("¥\(String(format: "%.2f", product.totalPrice))")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            HStack {
                if let brand = product.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.4f", product.quantity) + " \(product.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(merchantName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("单价: ¥\(String(format: "%.2f", product.unitPrice))/\(product.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(product.purchaseDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SearchMerchantRow: View {
    let merchant: Merchant
    let latestProduct: ProductRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(merchant.name)
                    .font(.headline)
                Spacer()
                Text("¥\(String(format: "%.2f", latestProduct.totalPrice))")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            HStack {
                Text(latestProduct.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(latestProduct.quantity) \(latestProduct.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("单价: ¥\(String(format: "%.2f", latestProduct.unitPrice))/\(latestProduct.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(latestProduct.purchaseDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [ProductRecord.self, Merchant.self], inMemory: true)
}
