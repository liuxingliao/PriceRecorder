//
//  BrandManagementView.swift
//  PriceRecorder
//
//  品牌管理页
//

import SwiftUI
import SwiftData

struct BrandManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Brand.name) private var brands: [Brand]

    @State private var showingAddBrand = false
    @State private var newBrandName = ""

    var body: some View {
        List {
            if brands.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "tag",
                        title: "还没有品牌",
                        message: "点击右上角 + 添加第一个品牌",
                        actionTitle: "添加品牌",
                        action: { showingAddBrand = true }
                    )
                }
            } else {
                Section("品牌列表 (\(brands.count))") {
                    ForEach(brands) { brand in
                        Text(brand.name)
                    }
                    .onDelete(perform: deleteBrands)
                }
            }
        }
        .navigationTitle("品牌管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddBrand = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("添加品牌", isPresented: $showingAddBrand) {
            TextField("品牌名称", text: $newBrandName)
            Button("取消", role: .cancel) {
                newBrandName = ""
            }
            Button("添加") {
                addBrand()
            }
            .disabled(newBrandName.isEmpty)
        }
    }

    private func addBrand() {
        let brand = Brand(name: newBrandName)
        modelContext.insert(brand)
        newBrandName = ""
    }

    private func deleteBrands(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(brands[index])
        }
    }
}

#Preview {
    NavigationStack {
        BrandManagementView()
    }
    .modelContainer(for: Brand.self, inMemory: true)
}
