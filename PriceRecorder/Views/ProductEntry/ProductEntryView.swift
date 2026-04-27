//
//  ProductEntryView.swift
//  PriceRecorder
//
//  商品录入入口页
//

import SwiftUI
import SwiftData

// 输入验证工具
private struct ValidationError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

private enum ProductValidation {
    static func validateName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError(message: "商品名称不能为空")
        }
        guard trimmed.count <= 100 else {
            throw ValidationError(message: "商品名称不能超过100个字符")
        }
    }

    static func validateSpec(_ spec: String?) throws {
        if let spec = spec, !spec.isEmpty {
            let trimmed = spec.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= 50 else {
                throw ValidationError(message: "规格不能超过50个字符")
            }
        }
    }

    static func validateNotes(_ notes: String?) throws {
        if let notes = notes, !notes.isEmpty {
            let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= 200 else {
                throw ValidationError(message: "备注不能超过200个字符")
            }
        }
    }

    static func validateQuantity(_ quantity: Double) throws {
        guard quantity > 0 else {
            throw ValidationError(message: "数量必须大于0")
        }
        guard quantity <= 1_000_000 else {
            throw ValidationError(message: "数量不能超过1,000,000")
        }
    }

    static func validateTotalPrice(_ price: Double) throws {
        guard price > 0 else {
            throw ValidationError(message: "总价必须大于0")
        }
        guard price <= 1_000_000 else {
            throw ValidationError(message: "总价不能超过1,000,000")
        }
    }

    static func validateUnit(_ unit: String) throws {
        let trimmed = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError(message: "单位不能为空")
        }
        guard trimmed.count <= 20 else {
            throw ValidationError(message: "单位不能超过20个字符")
        }
    }

    static func validateProduct(
        name: String,
        spec: String?,
        notes: String?,
        quantity: Double,
        unit: String,
        totalPrice: Double
    ) throws {
        try validateName(name)
        try validateSpec(spec)
        try validateNotes(notes)
        try validateQuantity(quantity)
        try validateUnit(unit)
        try validateTotalPrice(totalPrice)
    }
}

struct ProductEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Merchant.name) private var merchants: [Merchant]

    @State private var entryMode: EntryMode? = nil
    @State private var pendingProducts: [PendingProduct] = []
    @State private var selectedMerchantID: UUID?
    @State private var purchaseDate = Date()
    @State private var showingMerchantSelector = false
    @State private var showingAddMerchant = false
    @State private var editingProduct: PendingProduct?
    @State private var showingDoubaoEntry = false

    enum EntryMode: String {
        case manual = "manual"
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
        .sheet(isPresented: $showingDoubaoEntry) {
            DoubaoEntryView()
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
                    showingDoubaoEntry = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green)
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("豆包录入")
                                .font(.headline)
                            Text("通过豆包智能录入")
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
        .navigationTitle("手动录入")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    entryMode = nil
                }
            }
        }
        .sheet(item: $editingProduct) { product in
            ProductEditSheet(product: product) { updated in
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
                    Text("保存 \(pendingProducts.count) 件商品")
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

    private func save() {
        guard let merchantID = selectedMerchantID else { return }

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
                receiptPhoto: pending.receiptPhoto,
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
    @Query(sort: \ProductRecord.name) private var existingProducts: [ProductRecord]

    let product: PendingProduct
    let onSave: (PendingProduct) -> Void

    @State private var name: String
    @State private var brand: String?
    @State private var quantity: Double
    @State private var unit: String
    @State private var spec: String?
    @State private var totalPrice: Double
    @State private var notes: String?
    @State private var receiptPhoto: Data?
    @State private var photoQuality: PhotoQuality = .compressed
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var validationError: String?
    @State private var showingValidationError = false

    init(product: PendingProduct, onSave: @escaping (PendingProduct) -> Void) {
        self.product = product
        self.onSave = onSave
        _name = State(initialValue: product.name)
        _brand = State(initialValue: product.brand)
        _quantity = State(initialValue: product.quantity)
        _unit = State(initialValue: product.unit)
        _spec = State(initialValue: product.spec)
        _totalPrice = State(initialValue: product.totalPrice)
        _notes = State(initialValue: product.notes)
        _receiptPhoto = State(initialValue: product.receiptPhoto)
    }

    var unitPrice: Double {
        quantity > 0 ? totalPrice / quantity : 0
    }

    // 获取已有的商品名称建议（去重）
    var existingProductNames: [String] {
        Array(Set(existingProducts.map { $0.name })).sorted()
    }

    // 获取已有的品牌建议
    var existingBrands: [String] {
        let brandsFromProducts = existingProducts.compactMap { $0.brand }
        return Array(Set(brandsFromProducts)).sorted()
    }

    // 获取已有的规格建议
    var existingSpecs: [String] {
        Array(Set(existingProducts.compactMap { $0.spec })).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 商品信息区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("商品信息")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            // 商品名称
                            VStack(alignment: .leading, spacing: 8) {
                                Text("商品名称")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("商品名称", text: $name)
                                    .textFieldStyle(.roundedBorder)

                                // 商品名称建议
                                let filteredNames = existingProductNames.filter {
                                    !name.isEmpty && $0.localizedCaseInsensitiveContains(name)
                                }.prefix(6)
                                if !filteredNames.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(Array(filteredNames), id: \.self) { suggestion in
                                            Button(action: {
                                                name = suggestion
                                            }) {
                                                HStack {
                                                    Text(suggestion)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    if name == suggestion {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)

                                            if suggestion != filteredNames.last {
                                                Divider()
                                            }
                                        }
                                    }
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(8)
                                }
                            }

                            // 品牌
                            VStack(alignment: .leading, spacing: 8) {
                                Text("品牌（可选）")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("品牌（可选）", text: Binding(
                                    get: { brand ?? "" },
                                    set: { brand = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)

                                // 品牌建议
                                let brandText = brand ?? ""
                                let filteredBrands = existingBrands.filter {
                                    !brandText.isEmpty && $0.localizedCaseInsensitiveContains(brandText)
                                }.prefix(6)
                                if !filteredBrands.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(Array(filteredBrands), id: \.self) { suggestion in
                                            Button(action: {
                                                brand = suggestion
                                            }) {
                                                HStack {
                                                    Text(suggestion)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    if brand == suggestion {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)

                                            if suggestion != filteredBrands.last {
                                                Divider()
                                            }
                                        }
                                    }
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(8)
                                }
                            }

                            // 规格
                            VStack(alignment: .leading, spacing: 8) {
                                Text("规格（可选）")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("规格（可选）", text: Binding(
                                    get: { spec ?? "" },
                                    set: { spec = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)

                                // 规格建议
                                let specText = spec ?? ""
                                let filteredSpecs = existingSpecs.filter {
                                    !specText.isEmpty && $0.localizedCaseInsensitiveContains(specText)
                                }.prefix(6)
                                if !filteredSpecs.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(Array(filteredSpecs), id: \.self) { suggestion in
                                            Button(action: {
                                                spec = suggestion
                                            }) {
                                                HStack {
                                                    Text(suggestion)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    if spec == suggestion {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)

                                            if suggestion != filteredSpecs.last {
                                                Divider()
                                            }
                                        }
                                    }
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // 价格信息区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("价格信息")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // 数量
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("数量")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("", value: $quantity, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                }
                                .frame(maxWidth: .infinity)

                                // 单位
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("单位")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("单位", text: $unit)
                                        .textFieldStyle(.roundedBorder)
                                }
                                .frame(maxWidth: .infinity)
                            }

                            // 总价
                            VStack(alignment: .leading, spacing: 4) {
                                Text("总价")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("", value: $totalPrice, format: .currency(code: "CNY"))
                                    .textFieldStyle(.roundedBorder)
                            }

                            // 单价
                            HStack {
                                Text("单价")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "¥%.2f/%@", unitPrice, unit))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // 照片区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("小票照片")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            if let photoData = receiptPhoto, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)

                                Button(role: .destructive, action: {
                                    receiptPhoto = nil
                                }) {
                                    Text("删除照片")
                                }
                            } else {
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("添加小票照片")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                                }
                            }

                            if receiptPhoto != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("照片质量")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Picker("照片质量", selection: $photoQuality) {
                                        ForEach(PhotoQuality.allCases) { quality in
                                            Text(quality.displayName).tag(quality)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // 备注区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("备注")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            TextField("备注（可选）", text: Binding(
                                get: { notes ?? "" },
                                set: { notes = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
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
                        do {
                            try ProductValidation.validateProduct(
                                name: name,
                                spec: spec,
                                notes: notes,
                                quantity: quantity,
                                unit: unit,
                                totalPrice: totalPrice
                            )
                            var updated = product
                            updated.name = name
                            updated.brand = brand
                            updated.quantity = quantity
                            updated.unit = unit
                            updated.spec = spec
                            updated.totalPrice = totalPrice
                            updated.notes = notes
                            updated.receiptPhoto = receiptPhoto
                            onSave(updated)
                            dismiss()
                        } catch let error as ValidationError {
                            validationError = error.message
                            showingValidationError = true
                        } catch {
                            validationError = "保存失败，请重试"
                            showingValidationError = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { _, newImage in
                if let image = newImage {
                    receiptPhoto = PhotoService.shared.processImage(image, quality: photoQuality)
                }
            }
            .alert("验证错误", isPresented: $showingValidationError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(validationError ?? "未知错误")
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
