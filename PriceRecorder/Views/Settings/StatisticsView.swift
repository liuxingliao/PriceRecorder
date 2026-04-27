//
//  StatisticsView.swift
//  PriceRecorder
//
//  数据统计页
//

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query private var products: [ProductRecord]
    @Query private var merchants: [Merchant]
    @Query private var categories: [MerchantCategory]

    @State private var selectedMerchantForDetail: Merchant?

    var totalProducts: Int { products.count }
    var totalMerchants: Int { merchants.count }
    var totalCategories: Int { categories.count }

    // 图片统计
    var photosCount: Int {
        products.filter { $0.receiptPhoto != nil }.count
    }

    // 数据大小统计
    var photoDataSize: Int {
        var total = 0
        for product in products {
            if let photoData = product.receiptPhoto {
                total += photoData.count
            }
        }
        return total
    }

    var estimatedOtherDataSize: Int {
        // 估算其他数据大小（商品元数据、商家、分类等）
        let productBaseSize = products.count * 500 // 每个商品约500字节
        let merchantSize = merchants.count * 300
        let categorySize = categories.count * 200
        return productBaseSize + merchantSize + categorySize
    }

    var totalDataSize: Int {
        photoDataSize + estimatedOtherDataSize
    }

    func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    var totalSpent: Double {
        products.reduce(0) { $0 + $1.totalPrice }
    }

    var mostExpensiveProduct: ProductRecord? {
        products.max { $0.unitPrice < $1.unitPrice }
    }

    var mostFrequentProduct: (name: String, count: Int)? {
        let counts = Dictionary(grouping: products) { $0.name }
            .mapValues { $0.count }
        if let maxElement = counts.max(by: { $0.value < $1.value }) {
            return (name: maxElement.key, count: maxElement.value)
        }
        return nil
    }

    var merchantProductCounts: [(Merchant, Int, Double)] {
        merchants.map { merchant in
            let merchantProducts = products.filter { $0.merchantID == merchant.id }
            let count = merchantProducts.count
            let spent = merchantProducts.reduce(0) { $0 + $1.totalPrice }
            return (merchant, count, spent)
        }.sorted { $0.2 > $1.2 } // 按消费总额倒序
    }

    func merchantStats(for merchant: Merchant) -> (totalSpent: Double, productCount: Int, categoryCounts: [(String, Int)]) {
        let merchantProducts = products.filter { $0.merchantID == merchant.id }
        let spent = merchantProducts.reduce(0) { $0 + $1.totalPrice }

        var categoryDict: [String: Int] = [:]
        for product in merchantProducts {
            let category = merchant.categoryID.flatMap { catID in
                categories.first { $0.id == catID }?.name
            } ?? "未分类"
            categoryDict[category, default: 0] += 1
        }

        let sortedCategories = categoryDict.sorted { $0.value > $1.value }
        return (spent, merchantProducts.count, sortedCategories)
    }

    var body: some View {
        List {
            Section("概览") {
                StatRow(icon: "cart.fill", label: "商品总数", value: "\(totalProducts)")
                StatRow(icon: "storefront.fill", label: "商家数量", value: "\(totalMerchants)")
                StatRow(icon: "folder.fill", label: "分类数量", value: "\(totalCategories)")
            }

            Section("数据统计") {
                StatRow(icon: "photo.fill", label: "照片数量", value: "\(photosCount)")
                StatRow(icon: "photo.on.rectangle.fill", label: "照片占用", value: formatBytes(photoDataSize))
                StatRow(icon: "doc.text.fill", label: "其他数据", value: formatBytes(estimatedOtherDataSize))
                StatRow(icon: "externaldrive.fill", label: "总占用", value: formatBytes(totalDataSize))
            }

            Section("消费统计") {
                StatRow(icon: "yensign.circle.fill", label: "总支出", value: String(format: "¥%.2f", totalSpent))
            }

            if let expensive = mostExpensiveProduct {
                Section("最贵商品") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(expensive.name)
                            .font(.headline)
                        Text("单价: ¥\(String(format: "%.2f", expensive.unitPrice))/\(expensive.unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if let frequent = mostFrequentProduct {
                Section("最常购买") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(frequent.name)
                            .font(.headline)
                        Text("购买了 \(frequent.count) 次")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if !merchantProductCounts.isEmpty {
                Section("商家统计") {
                    ForEach(merchantProductCounts, id: \.0.id) { merchant, count, spent in
                        Button(action: {
                            selectedMerchantForDetail = merchant
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(merchant.name)
                                        .font(.headline)
                                    Text("\(count) 件商品")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(String(format: "¥%.2f", spent))
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("数据统计")
        .sheet(item: $selectedMerchantForDetail) { merchant in
            MerchantDetailSheet(merchant: merchant, stats: merchantStats(for: merchant))
        }
    }
}

struct MerchantDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let merchant: Merchant
    let stats: (totalSpent: Double, productCount: Int, categoryCounts: [(String, Int)])

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        Text(merchant.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 4) {
                            Text("总消费")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "¥%.2f", stats.totalSpent))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)
                        }

                        HStack(spacing: 40) {
                            VStack(spacing: 4) {
                                Text("\(stats.productCount)")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                Text("商品")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                if !stats.categoryCounts.isEmpty {
                    Section("商品分类（按数量）") {
                        ForEach(stats.categoryCounts, id: \.0) { category, count in
                            HStack {
                                Text(category)
                                Spacer()
                                Text("\(count) 件")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(merchant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
    .modelContainer(for: [ProductRecord.self, Merchant.self], inMemory: true)
}
