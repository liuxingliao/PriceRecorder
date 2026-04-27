//
//  PriceComparisonView.swift
//  PriceRecorder
//
//  比价页面
//

import SwiftUI
import SwiftData
import Charts

struct PriceComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ProductRecord.name) private var products: [ProductRecord]
    @Query(sort: \Merchant.name) private var merchants: [Merchant]

    @State private var step: ComparisonStep = .selectProduct
    @State private var selectedProductName: String?
    @State private var selectedMerchantIDs: Set<UUID> = []
    @State private var productSearchText = ""
    @AppStorage("maxMerchantCountForComparison") private var maxMerchantCount = 5
    @State private var selectedChartDate: Date?
    @State private var chartScrollPosition: Date?
    @State private var isScrollingEnabled = true

    enum TimeRange: String, CaseIterable, Identifiable {
        case day = "日"
        case week = "周"
        case month = "月"
        case year = "年"

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .day: return 7
            case .week: return 14
            case .month: return 30
            case .year: return 365
            }
        }

        var striding: Calendar.Component {
            switch self {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }
    }

    @State private var selectedTimeRange: TimeRange = .month

    enum ComparisonStep {
        case selectProduct
        case selectMerchants
        case showComparison
    }

    var uniqueProductNames: [String] {
        let names = Set(products.map { $0.name })
        let filtered = productSearchText.isEmpty ? Array(names) : Array(names).filter {
            $0.localizedCaseInsensitiveContains(productSearchText)
        }
        return filtered.sorted()
    }

    var filteredMerchants: [Merchant] {
        guard let productName = selectedProductName else { return [] }
        let merchantIDs = Set(products
            .filter { $0.name == productName }
            .map { $0.merchantID })
        return merchants.filter { merchantIDs.contains($0.id) }
    }

    var comparisonData: [(merchant: Merchant, records: [ProductRecord])] {
        guard let productName = selectedProductName else { return [] }
        return selectedMerchantIDs.compactMap { merchantID in
            guard let merchant = merchants.first(where: { $0.id == merchantID }) else {
                return nil
            }
            let records = products
                .filter { $0.name == productName && $0.merchantID == merchantID }
                .sorted { $0.purchaseDate < $1.purchaseDate }
                .suffix(100)
            return (merchant, Array(records))
        }
    }

    var body: some View {
        NavigationStack {
            switch step {
            case .selectProduct:
                productSelectionView
            case .selectMerchants:
                merchantSelectionView
            case .showComparison:
                comparisonResultView
            }
        }
    }

    private var productSelectionView: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索商品名称...", text: $productSearchText)
                }
                .padding(.vertical, 8)
            }

            if uniqueProductNames.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: productSearchText.isEmpty ? "没有商品数据" : "未找到相关商品",
                        message: productSearchText.isEmpty ? "先去录入一些商品数据吧" : "试试其他关键词"
                    )
                }
            } else {
                Section("选择商品") {
                    ForEach(uniqueProductNames, id: \.self) { name in
                        Button(action: {
                            selectedProductName = name
                            step = .selectMerchants
                        }) {
                            HStack {
                                Text(name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("比价")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
        }
    }

    private var merchantSelectionView: some View {
        List {
            if let productName = selectedProductName {
                Section("已选商品") {
                    Text(productName)
                        .font(.headline)
                }
            }

            if filteredMerchants.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "storefront",
                        title: "没有商家数据",
                        message: "该商品还没有在任何商家录入过"
                    )
                }
            } else {
                Section("选择商家（最多\(maxMerchantCount)个）") {
                    ForEach(filteredMerchants) { merchant in
                        MerchantCheckboxRow(
                            merchant: merchant,
                            isSelected: selectedMerchantIDs.contains(merchant.id)
                        ) {
                            if selectedMerchantIDs.contains(merchant.id) {
                                selectedMerchantIDs.remove(merchant.id)
                            } else if selectedMerchantIDs.count < maxMerchantCount {
                                selectedMerchantIDs.insert(merchant.id)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Text("已选择")
                        Spacer()
                        Text("\(selectedMerchantIDs.count)/\(maxMerchantCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("选择商家")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    step = .selectProduct
                    selectedMerchantIDs.removeAll()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("确定") {
                    step = .showComparison
                }
                .disabled(selectedMerchantIDs.isEmpty)
            }
        }
    }

    private var comparisonResultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let productName = selectedProductName {
                    Text(productName)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                priceTrendChart

                latestPriceComparison
            }
            .padding()
        }
        .navigationTitle("比价结果")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("返回") {
                    step = .selectMerchants
                }
            }
        }
    }

    private var priceTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("历史价格趋势")
                    .font(.headline)

                Spacer()

                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if #available(iOS 16.0, *) {
                VStack(spacing: 12) {
                    Chart {
                        ForEach(comparisonData, id: \.merchant.id) { data in
                            ForEach(data.records) { record in
                                LineMark(
                                    x: .value("日期", record.purchaseDate),
                                    y: .value("单价", record.unitPrice)
                                )
                                .foregroundStyle(by: .value("商家", data.merchant.name))
                                .symbol(by: .value("商家", data.merchant.name))
                            }
                        }

                        if let selectedDate = selectedChartDate {
                            RuleMark(x: .value("选中日期", selectedDate))
                                .foregroundStyle(Color.blue.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))

                            ForEach(comparisonData, id: \.merchant.id) { data in
                                if let record = data.records.first(where: {
                                    Calendar.current.isDate($0.purchaseDate, inSameDayAs: selectedDate)
                                }) {
                                    PointMark(
                                        x: .value("日期", record.purchaseDate),
                                        y: .value("单价", record.unitPrice)
                                    )
                                    .foregroundStyle(by: .value("商家", data.merchant.name))
                                    .symbolSize(120)
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                    .chartXAxisLabel("日期")
                    .chartYAxisLabel("单价 (¥)")
                    .chartScrollableAxes(.horizontal)
                    .chartXVisibleDomain(length: TimeInterval(selectedTimeRange.days * 24 * 60 * 60))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: selectedTimeRange.striding, count: 1)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    let xPos = location.x - geometry[proxy.plotAreaFrame].origin.x
                                    if let date: Date = proxy.value(atX: xPos) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedChartDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedChartDate!) {
                                                selectedChartDate = nil
                                            } else {
                                                selectedChartDate = date
                                            }
                                        }
                                    }
                                }
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let xPos = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                            if let date: Date = proxy.value(atX: xPos) {
                                                if selectedChartDate == nil {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        selectedChartDate = date
                                                    }
                                                } else {
                                                    selectedChartDate = date
                                                }
                                            }
                                        }
                                )
                        }
                    }

                    if let selectedDate = selectedChartDate {
                        chartSelectionDetail(selectedDate)
                    }
                }
            } else {
                Text("图表需要 iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @available(iOS 16.0, *)
    private func chartSelectionDetail(_ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedChartDate = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }

            Divider()

            ForEach(comparisonData, id: \.merchant.id) { data in
                if let record = data.records.first(where: {
                    Calendar.current.isDate($0.purchaseDate, inSameDayAs: date)
                }) {
                    HStack {
                        Text(data.merchant.name)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "¥%.2f", record.unitPrice))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }

            Text("点击图表任意位置或X关闭")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    private var latestPriceComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最新价格对比")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(comparisonData.sorted(by: {
                    ($0.records.last?.unitPrice ?? 0) < ($1.records.last?.unitPrice ?? 0)
                }), id: \.merchant.id) { data in
                    if let latest = data.records.last {
                        LatestPriceRow(
                            merchant: data.merchant,
                            record: latest,
                            isCheapest: data.records.last?.unitPrice == comparisonData.flatMap({ $0.records }).map({ $0.unitPrice }).min()
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MerchantCheckboxRow: View {
    let merchant: Merchant
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(merchant.name)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
        }
    }
}

struct LatestPriceRow: View {
    let merchant: Merchant
    let record: ProductRecord
    let isCheapest: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(merchant.name)
                        .font(.headline)
                    if isCheapest {
                        Text("最便宜")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                Text(record.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "¥%.2f", record.unitPrice))
                    .font(.headline)
                    .foregroundColor(isCheapest ? .green : .blue)
                Text("/\(record.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    PriceComparisonView()
        .modelContainer(for: [ProductRecord.self, Merchant.self], inMemory: true)
}
