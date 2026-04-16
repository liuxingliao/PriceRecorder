//
//  HomeView.swift
//  PriceRecorder
//
//  首页 - 显示最近录入的商品
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \ProductRecord.createTime, order: .reverse)
    private var allProducts: [ProductRecord]
    @Query private var merchants: [Merchant]

    @State private var showingProductEntry = false
    @State private var selectedProduct: ProductRecord?

    var recentProducts: [ProductRecord] {
        Array(allProducts.prefix(10))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("商品价格记录")
                        .font(.title)
                        .fontWeight(.bold)

                    Button(action: {
                        showingProductEntry = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("商品录入")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding()

                if recentProducts.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "cart")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("还没有商品记录")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("点击上方按钮开始录入第一个商品吧")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: {
                            showingProductEntry = true
                        }) {
                            Text("开始录入")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        Section("最近录入") {
                            ForEach(recentProducts) { product in
                                ProductRow(product: product, merchants: merchants)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedProduct = product
                                    }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationDestination(isPresented: $showingProductEntry) {
                ProductEntryView()
            }
            .navigationDestination(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
        }
    }
}

struct ProductRow: View {
    let product: ProductRecord
    let merchants: [Merchant]

    var merchantName: String {
        merchants.first { $0.id == product.merchantID }?.name ?? "未知商家"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(product.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "¥%.2f", product.totalPrice))
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            HStack {
                Text(String(format: "%.4f", product.quantity) + " \(product.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(merchantName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [ProductRecord.self, Merchant.self], inMemory: true)
}
