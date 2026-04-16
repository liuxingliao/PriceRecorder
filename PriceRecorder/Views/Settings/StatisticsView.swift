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

    var totalProducts: Int { products.count }
    var totalMerchants: Int { merchants.count }
    var totalCategories: Int { categories.count }

    // 图片统计
    var photosCount: Int {
        products.filter { $0.receiptPhoto != nil }.count
    }

    // 数据大小统计
    var totalDataSize: Int {
        var total = 0
        for product in products {
            if let photoData = product.receiptPhoto {
                total += photoData.count
            }
        }
        return total
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

    var merchantProductCounts: [(Merchant, Int)] {
        merchants.map { merchant in
            let count = products.filter { $0.merchantID == merchant.id }.count
            return (merchant, count)
        }.sorted { $0.1 > $1.1 }
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
                StatRow(icon: "externaldrive.fill", label: "数据占用", value: formatBytes(totalDataSize))
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
                Section("商家商品数量") {
                    ForEach(merchantProductCounts.prefix(5), id: \.0.id) { merchant, count in
                        HStack {
                            Text(merchant.name)
                            Spacer()
                            Text("\(count) 件")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("数据统计")
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
