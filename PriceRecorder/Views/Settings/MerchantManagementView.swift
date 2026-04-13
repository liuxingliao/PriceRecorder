//
//  MerchantManagementView.swift
//  PriceRecorder
//
//  商家管理页
//

import SwiftUI
import SwiftData

struct MerchantManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Merchant.name) private var merchants: [Merchant]
    @Query(sort: \MerchantCategory.name) private var categories: [MerchantCategory]

    @State private var showingAddMerchant = false
    @State private var showingCategoryManagement = false
    @State private var editingMerchant: Merchant?

    var body: some View {
        List {
            Section {
                Button(action: {
                    showingCategoryManagement = true
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        Text("管理分类")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }

            if merchants.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "storefront",
                        title: "还没有商家",
                        message: "点击右上角 + 添加第一个商家",
                        actionTitle: "添加商家",
                        action: { showingAddMerchant = true }
                    )
                }
            } else {
                Section("商家列表 (\(merchants.count))") {
                    ForEach(merchants) { merchant in
                        MerchantRow(merchant: merchant, categories: categories)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingMerchant = merchant
                            }
                    }
                }
            }
        }
        .navigationTitle("商家管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddMerchant = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMerchant) {
            MerchantEditView(merchant: nil)
        }
        .sheet(item: $editingMerchant) { merchant in
            MerchantEditView(merchant: merchant)
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView()
        }
    }
}

struct MerchantRow: View {
    let merchant: Merchant
    let categories: [MerchantCategory]

    var categoryName: String? {
        if let categoryId = merchant.categoryID {
            return categories.first { $0.id == categoryId }?.name
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(merchant.name)
                .font(.headline)
            if let categoryName = categoryName {
                Text(categoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let address = merchant.address, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MerchantEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MerchantCategory.name) private var categories: [MerchantCategory]

    let merchant: Merchant?

    @State private var name = ""
    @State private var selectedCategoryID: UUID?
    @State private var address = ""
    @State private var phone = ""
    @State private var notes = ""

    var isEditing: Bool { merchant != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("商家名称", text: $name)

                    Picker("分类", selection: $selectedCategoryID) {
                        Text("无").tag(nil as UUID?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id as UUID?)
                        }
                    }
                }

                Section("详细信息") {
                    TextField("地址", text: $address)
                    TextField("电话", text: $phone)
                    TextField("备注", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "编辑商家" : "添加商家")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "添加") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let merchant = merchant {
                    name = merchant.name
                    selectedCategoryID = merchant.categoryID
                    address = merchant.address ?? ""
                    phone = merchant.phone ?? ""
                    notes = merchant.notes ?? ""
                }
            }
        }
    }

    private func save() {
        if let merchant = merchant {
            merchant.name = name
            merchant.categoryID = selectedCategoryID
            merchant.address = address.isEmpty ? nil : address
            merchant.phone = phone.isEmpty ? nil : phone
            merchant.notes = notes.isEmpty ? nil : notes
            merchant.updateTime = Date()
        } else {
            let newMerchant = Merchant(
                name: name,
                categoryID: selectedCategoryID,
                address: address.isEmpty ? nil : address,
                phone: phone.isEmpty ? nil : phone,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(newMerchant)
        }
        dismiss()
    }
}

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MerchantCategory.name) private var categories: [MerchantCategory]

    @State private var showingAddCategory = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationStack {
            List {
                if categories.isEmpty {
                    Section {
                        EmptyStateView(
                            icon: "folder",
                            title: "还没有分类",
                            message: "点击右上角 + 添加第一个分类"
                        )
                    }
                } else {
                    Section("分类列表") {
                        ForEach(categories) { category in
                            Text(category.name)
                        }
                        .onDelete(perform: deleteCategories)
                    }
                }
            }
            .navigationTitle("商家分类")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("添加分类", isPresented: $showingAddCategory) {
                TextField("分类名称", text: $newCategoryName)
                Button("取消", role: .cancel) {
                    newCategoryName = ""
                }
                Button("添加") {
                    addCategory()
                }
                .disabled(newCategoryName.isEmpty)
            }
        }
    }

    private func addCategory() {
        let category = MerchantCategory(name: newCategoryName)
        modelContext.insert(category)
        newCategoryName = ""
    }

    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

#Preview {
    NavigationStack {
        MerchantManagementView()
    }
    .modelContainer(for: [Merchant.self, MerchantCategory.self], inMemory: true)
}
