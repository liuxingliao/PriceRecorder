//
//  DebugConfigView.swift
//  PriceRecorder
//
//  调试配置页
//

import SwiftUI
import SwiftData

struct DebugConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var cloudSyncService = CloudSyncService.shared

    @AppStorage("isICloudBackupEnabled") private var isICloudBackupEnabled = false
    @AppStorage("maxMerchantCountForComparison") private var maxMerchantCountForComparison = 5
    @AppStorage("photoQualityPercent") private var photoQualityPercent = 80

    var body: some View {
        NavigationStack {
            Form {
                Section("iCloud 备份") {
                    Toggle("启用 iCloud 备份", isOn: $isICloudBackupEnabled)
                        .onChange(of: isICloudBackupEnabled) { _, newValue in
                            cloudSyncService.saveAutoBackupSetting(newValue)
                        }

                    if isICloudBackupEnabled {
                        if let lastSync = cloudSyncService.lastSyncDate {
                            HStack {
                                Text("上次同步")
                                Spacer()
                                Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: {
                            cloudSyncService.backupToCloud(modelContext: modelContext) { _, _ in
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                    .foregroundColor(.blue)
                                if cloudSyncService.isSyncing {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text("立即备份")
                                }
                            }
                        }
                        .disabled(cloudSyncService.isSyncing)
                    }
                }

                Section("比价配置") {
                    HStack {
                        Text("最多选择商家数量")
                        Spacer()
                        Stepper("\(maxMerchantCountForComparison)", value: $maxMerchantCountForComparison, in: 1...10)
                    }
                }

                Section("照片质量") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("照片质量")
                            Spacer()
                            Text("\(photoQualityPercent)%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(photoQualityPercent) },
                            set: { photoQualityPercent = Int($0) }
                        ), in: 10...100, step: 5)
                    }
                }
            }
            .navigationTitle("调试配置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DebugConfigView()
}
