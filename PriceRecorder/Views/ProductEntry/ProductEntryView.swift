//
//  ProductEntryView.swift
//  PriceRecorder
//
//  商品录入入口页
//

import SwiftUI
import SwiftData
import Vision
import UIKit

struct ProductEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Merchant.name) private var merchants: [Merchant]
    @Query(sort: \MerchantCategory.name) private var categories: [MerchantCategory]
    @Query(sort: \Brand.name) private var brands: [Brand]

    @State private var entryMode: EntryMode? = nil
    @State private var pendingProducts: [PendingProduct] = []
    @State private var selectedMerchantID: UUID?
    @State private var purchaseDate = Date()
    @State private var receiptPhoto: UIImage?
    @State private var showingMerchantSelector = false
    @State private var showingImagePicker = false
    @State private var showingSourceSelection = false
    @State private var showingAddMerchant = false
    @State private var isRecognizing = false
    @State private var editingProduct: PendingProduct?

    enum EntryMode: String {
        case manual = "manual"
        case photo = "photo"
    }

    var selectedMerchant: Merchant? {
        if let id = selectedMerchantID {
            return merchants.first { $0.id == id }
        }
        return nil
    }

    var canSave: Bool {
        !pendingProducts.isEmpty && selectedMerchantID != nil
    }

    var body: some View {
        NavigationStack {
            if entryMode == nil {
                entryModeSelection
            } else {
                productEntryForm
            }
        }
    }

    private var entryModeSelection: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    entryMode = .manual
                    pendingProducts = []
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("手动输入")
                                .font(.headline)
                            Text("手动录入商品信息")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Button(action: {
                    entryMode = .photo
                    pendingProducts = []
                    showingSourceSelection = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green)
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("拍照识别")
                                .font(.headline)
                            Text("拍摄小票自动识别")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()

            Spacer()
        }
        .navigationTitle("选择录入方式")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
        }
        .confirmationDialog("选择图片来源", isPresented: $showingSourceSelection) {
            Button("拍照") {
                showingImagePicker = true
            }
            Button("从相册选择") {
                showingImagePicker = true
            }
            Button("取消", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $receiptPhoto)
        }
        .onChange(of: receiptPhoto) { _, image in
            if let image = image {
                if entryMode == .photo {
                    recognizeText(from: image)
                }
            }
        }
    }

    private var productEntryForm: some View {
        VStack(spacing: 0) {
            if pendingProducts.isEmpty {
                emptyProductList
            } else {
                productList
            }

            bottomBar
        }
        .navigationTitle(entryMode == .manual ? "手动录入" : "拍照识别")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    entryMode = nil
                }
            }
        }
        .sheet(item: $editingProduct) { product in
            ProductEditSheet(product: product, brands: brands) { updated in
                if let index = pendingProducts.firstIndex(where: { $0.id == product.id }) {
                    pendingProducts[index] = updated
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

    private var emptyProductList: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "cart.badge.plus",
                title: "还没有商品",
                message: "点击下方按钮添加商品",
                actionTitle: "添加商品",
                action: { addEmptyProduct() }
            )
            Spacer()
        }
    }

    private var productList: some View {
        List {
            Section("商品列表") {
                ForEach(pendingProducts) { product in
                    PendingProductRow(product: product)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingProduct = product
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                pendingProducts.removeAll { $0.id == product.id }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }

            Section {
                Button(action: { addEmptyProduct() }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("添加商品")
                    }
                }
            }
        }
        .listStyle(.plain)
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
                    if isRecognizing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(10)
                    } else {
                        Text("保存 \(pendingProducts.count) 件商品")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                }
                .disabled(!canSave || isRecognizing)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    private func addEmptyProduct() {
        let product = PendingProduct(
            name: "",
            quantity: 1,
            unit: "个",
            totalPrice: 0
        )
        pendingProducts.append(product)
        editingProduct = product
    }

    private func recognizeText(from image: UIImage) {
        isRecognizing = true
        pendingProducts = []

        OCRService.shared.recognizeText(from: image) { results, error in
            isRecognizing = false

            if let error = error {
                print("OCR Error: \(error)")
                addEmptyProduct()
                return
            }

            let items = OCRService.shared.parseReceiptItems(from: results)
            if items.isEmpty {
                addEmptyProduct()
            } else {
                pendingProducts = items
            }
        }
    }

    private func save() {
        guard let merchantID = selectedMerchantID else { return }

        let photoData = receiptPhoto?.jpegData(compressionQuality: 0.8)

        let receipt = Receipt(
            merchantID: merchantID,
            purchaseDate: purchaseDate,
            photo: photoData
        )
        modelContext.insert(receipt)

        for pending in pendingProducts {
            let product = ProductRecord(
                name: pending.name.isEmpty ? "未知商品" : pending.name,
                brand: pending.brand,
                quantity: pending.quantity,
                unit: pending.unit,
                spec: pending.spec,
                totalPrice: pending.totalPrice,
                merchantID: merchantID,
                purchaseDate: purchaseDate,
                receiptPhoto: photoData,
                notes: pending.notes
            )
            modelContext.insert(product)
        }

        dismiss()
    }
}

struct PendingProductRow: View {
    let product: PendingProduct

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name.isEmpty ? "未命名商品" : product.name)
                    .font(.headline)
                if let brand = product.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "¥%.2f", product.totalPrice))
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("\(product.quantity) \(product.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProductEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let product: PendingProduct
    let brands: [Brand]
    let onSave: (PendingProduct) -> Void

    @State private var name: String
    @State private var brand: String?
    @State private var quantity: Double
    @State private var unit: String
    @State private var spec: String?
    @State private var totalPrice: Double
    @State private var notes: String?

    init(product: PendingProduct, brands: [Brand], onSave: @escaping (PendingProduct) -> Void) {
        self.product = product
        self.brands = brands
        self.onSave = onSave
        _name = State(initialValue: product.name)
        _brand = State(initialValue: product.brand)
        _quantity = State(initialValue: product.quantity)
        _unit = State(initialValue: product.unit)
        _spec = State(initialValue: product.spec)
        _totalPrice = State(initialValue: product.totalPrice)
        _notes = State(initialValue: product.notes)
    }

    var unitPrice: Double {
        quantity > 0 ? totalPrice / quantity : 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("商品信息") {
                    TextField("商品名称", text: $name)
                    TextField("品牌（可选）", text: Binding(
                        get: { brand ?? "" },
                        set: { brand = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("规格（可选）", text: Binding(
                        get: { spec ?? "" },
                        set: { spec = $0.isEmpty ? nil : $0 }
                    ))
                }

                Section("价格信息") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("数量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("", value: $quantity, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading) {
                            Text("单位")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("单位", text: $unit)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("总价")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("", value: $totalPrice, format: .currency(code: "CNY"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("单价")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "¥%.2f/%@", unitPrice, unit))
                            .foregroundColor(.secondary)
                    }
                }

                Section("备注") {
                    TextField("备注（可选）", text: Binding(
                        get: { notes ?? "" },
                        set: { notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                }
            }
            .navigationTitle("编辑商品")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        var updated = product
                        updated.name = name
                        updated.brand = brand
                        updated.quantity = quantity
                        updated.unit = unit
                        updated.spec = spec
                        updated.totalPrice = totalPrice
                        updated.notes = notes
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MerchantSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Merchant.name) private var merchants: [Merchant]
    @Binding var selectedMerchantID: UUID?
    @Binding var showingAddMerchant: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(merchants) { merchant in
                    Button(action: {
                        selectedMerchantID = merchant.id
                        dismiss()
                    }) {
                        HStack {
                            Text(merchant.name)
                            Spacer()
                            if merchant.id == selectedMerchantID {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择商家")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingAddMerchant = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    ProductEntryView()
        .modelContainer(for: [ProductRecord.self, Merchant.self, Receipt.self], inMemory: true)
}
