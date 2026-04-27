//
//  OCRService.swift
//  PriceRecorder
//
//  OCR文字识别服务 - 使用iOS Vision框架
//

import Foundation
@preconcurrency import Vision
import UIKit

struct OCRResult {
    let text: String
    let boundingBox: CGRect
}

class OCRService {
    static let shared = OCRService()

    private init() {}

    /// 最大图片尺寸（宽度或高度），用于压缩
    private let maxImageDimension: CGFloat = 1024

    /// 压缩图片到指定尺寸
    private func compressImage(_ image: UIImage) -> UIImage {
        let width = image.size.width
        let height = image.size.height

        // 如果图片已经小于最大尺寸，直接返回
        guard width > maxImageDimension || height > maxImageDimension else {
            return image
        }

        // 计算缩放比例
        let scale = min(maxImageDimension / width, maxImageDimension / height)
        let newSize = CGSize(width: width * scale, height: height * scale)

        // 渲染压缩后的图片
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let compressedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return compressedImage
    }

    /// 现代 async/await 版本的文字识别
    func recognizeText(from image: UIImage) async throws -> [OCRResult] {
        let compressedImage = compressImage(image)

        guard let cgImage = compressedImage.cgImage else {
            throw NSError(domain: "OCRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取图片数据"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
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

                continuation.resume(returning: results)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 保留兼容的 completion handler 版本
    @available(*, deprecated, renamed: "recognizeText(from:)")
    func recognizeText(from image: UIImage, completion: @escaping ([OCRResult], Error?) -> Void) {
        Task {
            do {
                let results = try await recognizeText(from: image)
                DispatchQueue.main.async {
                    completion(results, nil)
                }
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
                brand: nil,
                quantity: quantity,
                unit: "个",
                spec: nil,
                totalPrice: price,
                notes: nil,
                receiptPhoto: nil
            )
        }

        return PendingProduct(
            name: name.isEmpty ? "未知商品" : name,
            brand: nil,
            quantity: 1,
            unit: "个",
            spec: nil,
            totalPrice: price,
            notes: nil,
            receiptPhoto: nil
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
    var receiptPhoto: Data?
}

/// 照片质量选项
enum PhotoQuality: String, CaseIterable, Identifiable {
    case compressed = "compressed"
    case original = "original"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compressed: return "压缩图（推荐）"
        case .original: return "原图"
        }
    }

    var compressionQuality: CGFloat {
        switch self {
        case .compressed: return 0.7
        case .original: return 1.0
        }
    }

    var maxDimension: CGFloat {
        switch self {
        case .compressed: return 1024
        case .original: return CGFloat.greatestFiniteMagnitude
        }
    }
}

/// 照片处理服务
class PhotoService {
    static let shared = PhotoService()

    private init() {}

    /// 按照指定质量处理图片
    func processImage(_ image: UIImage, quality: PhotoQuality) -> Data? {
        let scaledImage = scaleImage(image, maxDimension: quality.maxDimension)
        return scaledImage.jpegData(compressionQuality: quality.compressionQuality)
    }

    /// 缩放图片到最大尺寸
    private func scaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        if maxDimension == .greatestFiniteMagnitude {
            return image
        }

        let width = image.size.width
        let height = image.size.height

        guard width > maxDimension || height > maxDimension else {
            return image
        }

        let scale = min(maxDimension / width, maxDimension / height)
        let newSize = CGSize(width: width * scale, height: height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
