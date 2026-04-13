//
//  ProductDetailView.swift
//  PriceRecorder
//
//  商品详情页
//

import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var product: ProductRecord

    @Query private var merchants: [Merchant]
    @Query private var brands: [Brand]

    @State private var isEditing = false
    @State private var editName = ""
    @State private var editBrand: String?
    @State private var editQuantity: Double = 0
    @State private var editUnit = ""
    @State private var editSpec: String?
    @State private var editTotalPrice: Double = 0
    @State private var editMerchantID: UUID?
    @State private var editPurchaseDate = Date()
    @State private var editNotes: String?
    @State private var showingMerchantSelector = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingBrandSelector = false

    init(product: ProductRecord) {
        self.product = product
        _merchants = Query()
        _brands = Query()
    }

    var merchant: Merchant? {
        merchants.first { $0.id == product.merchantID }
    }

    var unitPrice: Double {
        editQuantity > 0 ? editTotalPrice / editQuantity : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let photoData = product.receiptPhoto, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                }

                if isEditing {
                    editForm
                } else {
                    detailView
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? "编辑商品" : "商品详情")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "保存" : "编辑") {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                }
            }
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isEditing = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingMerchantSelector) {
            MerchantSelectorView(selectedMerchantID: $editMerchantID)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage, let data = image.jpegData(compressionQuality: 0.8) {
                product.receiptPhoto = data
            }
        }
        .onAppear {
            loadData()
        }
    }

    private var detailView: some View {
        VStack(spacing: 16) {
            DetailGroup(title: "商品信息") {
                DetailRow(label: "名称", value: product.name)
                if let brand = product.brand {
                    DetailRow(label: "品牌", value: brand)
                }
                if let spec = product.spec {
                    DetailRow(label: "规格", value: spec)
                }
            }

            DetailGroup(title: "价格信息") {
                DetailRow(label: "数量", value: "\(product.quantity) \(product.unit)")
                DetailRow(label: "总价", value: String(format: "¥%.2f", product.totalPrice))
                DetailRow(label: "单价", value: String(format: "¥%.2f/%@", product.unitPrice, product.unit))
            }

            DetailGroup(title: "购买信息") {
                if let merchant = merchant {
                    DetailRow(label: "商家", value: merchant.name)
                }
                DetailRow(label: "购买时间", value: product.purchaseDate.formatted(date: .long, time: .shortened))
            }

            if let notes = product.notes {
                DetailGroup(title: "备注") {
                    Text(notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if product.receiptPhoto == nil {
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("添加小票照片")
                    }
                }
            }
        }
    }

    private var editForm: some View {
        VStack(spacing: 16) {
            DetailGroup(title: "商品信息") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("名称")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("商品名称", text: $editName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("品牌")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("品牌", text: Binding(
                            get: { editBrand ?? "" },
                            set: { editBrand = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)

                        if !brands.isEmpty {
                            Button("选择") {
                                showingBrandSelector = true
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("规格")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("规格（可选）", text: Binding(
                        get: { editSpec ?? "" },
                        set: { editSpec = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }

            DetailGroup(title: "价格信息") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("数量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("", value: $editQuantity, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("单位")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("单位", text: $editUnit)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("总价")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("", value: $editTotalPrice, format: .currency(code: "CNY"))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("单价")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "¥%.2f/%@", unitPrice, editUnit))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            DetailGroup(title: "购买信息") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("商家")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button(action: {
                        showingMerchantSelector = true
                    }) {
                        HStack {
                            if let merchantId = editMerchantID,
                               let merchant = merchants.first(where: { $0.id == merchantId }) {
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

                DatePicker("购买时间", selection: $editPurchaseDate, displayedComponents: [.date, .hourAndMinute])
            }

            DetailGroup(title: "备注") {
                TextField("备注（可选）", text: Binding(
                    get: { editNotes ?? "" },
                    set: { editNotes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func loadData() {
        editName = product.name
        editBrand = product.brand
        editQuantity = product.quantity
        editUnit = product.unit
        editSpec = product.spec
        editTotalPrice = product.totalPrice
        editMerchantID = product.merchantID
        editPurchaseDate = product.purchaseDate
        editNotes = product.notes
    }

    private func startEditing() {
        loadData()
        isEditing = true
    }

    private func saveChanges() {
        product.name = editName
        product.brand = editBrand
        product.quantity = editQuantity
        product.unit = editUnit
        product.spec = editSpec
        product.totalPrice = editTotalPrice
        product.unitPrice = editQuantity > 0 ? editTotalPrice / editQuantity : 0
        product.merchantID = editMerchantID ?? product.merchantID
        product.purchaseDate = editPurchaseDate
        product.notes = editNotes
        product.updateTime = Date()
        isEditing = false
    }
}

struct DetailGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct MerchantSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Merchant.name) private var merchants: [Merchant]
    @Binding var selectedMerchantID: UUID?

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
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: ProductRecord(
            name: "示例商品",
            quantity: 1,
            unit: "个",
            totalPrice: 10.0,
            merchantID: UUID()
        ))
    }
    .modelContainer(for: ProductRecord.self, inMemory: true)
}
