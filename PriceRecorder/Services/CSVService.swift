//
//  CSVService.swift
//  PriceRecorder
//
//  CSV导入导出服务
//

import Foundation

struct CSVExportData {
    let productName: String
    let brand: String?
    let quantity: Double
    let unit: String
    let spec: String?
    let totalPrice: Double
    let unitPrice: Double
    let merchantName: String
    let merchantCategory: String?
    let purchaseDate: Date
    let notes: String?
    let createTime: Date
    let updateTime: Date
}

class CSVService {
    static let shared = CSVService()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private init() {}

    func exportCSV(data: [CSVExportData]) throws -> String {
        var csvString = "商品名称,品牌,数量,单位,规格,总价,单价,商家名称,商家分类,购买时间,备注,创建时间,更新时间\n"

        for item in data {
            let row = [
                escapeCSVField(item.productName),
                escapeCSVField(item.brand ?? ""),
                "\(item.quantity)",
                escapeCSVField(item.unit),
                escapeCSVField(item.spec ?? ""),
                "\(item.totalPrice)",
                "\(item.unitPrice)",
                escapeCSVField(item.merchantName),
                escapeCSVField(item.merchantCategory ?? ""),
                dateFormatter.string(from: item.purchaseDate),
                escapeCSVField(item.notes ?? ""),
                dateFormatter.string(from: item.createTime),
                dateFormatter.string(from: item.updateTime)
            ].joined(separator: ",")

            csvString.append(row + "\n")
        }

        return csvString
    }

    func parseCSV(_ csvString: String) throws -> [CSVExportData] {
        var results: [CSVExportData] = []
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }

        guard lines.count > 1 else {
            throw NSError(domain: "CSVService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CSV文件格式无效"])
        }

        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count >= 13 else { continue }

            guard let quantity = Double(fields[2]),
                  let totalPrice = Double(fields[5]),
                  let unitPrice = Double(fields[6]),
                  let purchaseDate = dateFormatter.date(from: fields[9]),
                  let createTime = dateFormatter.date(from: fields[11]),
                  let updateTime = dateFormatter.date(from: fields[12]) else {
                continue
            }

            let data = CSVExportData(
                productName: fields[0],
                brand: fields[1].isEmpty ? nil : fields[1],
                quantity: quantity,
                unit: fields[3],
                spec: fields[4].isEmpty ? nil : fields[4],
                totalPrice: totalPrice,
                unitPrice: unitPrice,
                merchantName: fields[7],
                merchantCategory: fields[8].isEmpty ? nil : fields[8],
                purchaseDate: purchaseDate,
                notes: fields[10].isEmpty ? nil : fields[10],
                createTime: createTime,
                updateTime: updateTime
            )

            results.append(data)
        }

        return results
    }

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]

            if char == "\"" {
                if inQuotes {
                    let nextIndex = line.index(after: index)
                    if nextIndex < line.endIndex && line[nextIndex] == "\"" {
                        currentField.append("\"")
                        index = nextIndex
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }

            index = line.index(after: index)
        }

        fields.append(currentField)
        return fields
    }
}
