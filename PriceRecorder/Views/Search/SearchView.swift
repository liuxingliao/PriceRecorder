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
    @Query private var allProducts: [ProductRecord]
    @Query private var merchants: [Merchant]

    @State private var searchText = ""
    @State private var searchMode: SearchMode = .product
    @State private var sortOption: SortOption = .time
    @State private var showingSortOptions = false
    @State private var selectedProduct: ProductRecord?
    @State private var showingPriceComparison = false

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

        return groups.compactMap { merchantId, products in
            guard let merchant = merchants.first(where: { $0.id == merchantId }) else {
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
        }
    }

    private var productResultsSection: some View {
        Section("搜索结果 (\(filteredProducts.count))") {
            ForEach(filteredProducts) { product in
                SearchProductRow(product: product)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProduct = product
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
    @Query private var merchants: [Merchant]

    var merchantName: String {
        merchants.first { $0.id == product.merchantID }?.name ?? "未知商家"
    }

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
                Text(merchantName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(product.quantity) \(product.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("单价: ¥\(String(format: "%.2f", product.unitPrice))/\(product.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
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
