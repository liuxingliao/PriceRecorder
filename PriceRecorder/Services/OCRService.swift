//
//  OCRService.swift
//  PriceRecorder
//
//  OCR文字识别服务 - 使用iOS Vision框架
//

import Foundation
import Vision
import UIKit

struct OCRResult {
    let text: String
    let boundingBox: CGRect
}

class OCRService {
    static let shared = OCRService()

    private init() {}

    func recognizeText(from image: UIImage, completion: @escaping ([OCRResult], Error?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([], NSError(domain: "OCRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取图片数据"]))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion([], error)
                }
                return
            }

            var results: [OCRResult] = []

            if let observations = request.results as? [VNRecognizedTextObservation] {
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        let result = OCRResult(
                            text: topCandidate.string,
                            boundingBox: observation.boundingBox
                        )
                        results.append(result)
                    }
                }
            }

            DispatchQueue.main.async {
                completion(results, nil)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion([], error)
                }
            }
        }
    }

    func parseReceiptItems(from results: [OCRResult]) -> [PendingProduct] {
        var items: [PendingProduct] = []
        let allText = results.map { $0.text }.joined(separator: "\n")

        let lines = allText.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        for line in lines {
            if let item = parseLine(line) {
                items.append(item)
            }
        }

        return items
    }

    private func parseLine(_ line: String) -> PendingProduct? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        let pricePattern = "\\d+[.,]\\d{2}"
        guard let priceRegex = try? NSRegularExpression(pattern: pricePattern, options: []) else {
            return nil
        }

        let range = NSRange(trimmedLine.startIndex..., in: trimmedLine)
        let matches = priceRegex.matches(in: trimmedLine, options: [], range: range)

        guard let lastMatch = matches.last,
              let priceRange = Range(lastMatch.range, in: trimmedLine) else {
            return nil
        }

        let priceString = String(trimmedLine[priceRange])
            .replacingOccurrences(of: ",", with: ".")
        guard let price = Double(priceString) else {
            return nil
        }

        var name = String(trimmedLine[..<priceRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let quantity = parseQuantity(&name) {
            return PendingProduct(
                name: name,
                quantity: quantity,
                unit: "个",
                totalPrice: price
            )
        }

        return PendingProduct(
            name: name.isEmpty ? "未知商品" : name,
            quantity: 1,
            unit: "个",
            totalPrice: price
        )
    }

    private func parseQuantity(_ name: inout String) -> Double? {
        let quantityPattern = "^(\\d+)\\s*[xX×]?\\s*"
        guard let regex = try? NSRegularExpression(pattern: quantityPattern, options: []) else {
            return nil
        }

        let range = NSRange(name.startIndex..., in: name)
        if let match = regex.firstMatch(in: name, options: [], range: range),
           let quantityRange = Range(match.range(at: 1), in: name),
           let quantity = Double(String(name[quantityRange])),
           let fullRange = Range(match.range, in: name) {
            name = String(name[fullRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            return quantity
        }

        return nil
    }
}

struct PendingProduct: Identifiable {
    let id = UUID()
    var name: String
    var brand: String?
    var quantity: Double
    var unit: String
    var spec: String?
    var totalPrice: Double
    var notes: String?
}
