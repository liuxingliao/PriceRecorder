//
//  SettingsView.swift
//  PriceRecorder
//
//  设置页
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var cloudSyncService = CloudSyncService.shared

    @Query private var apiConfigs: [APIConfig]

    @State private var showingMerchantManagement = false
    @State private var showingDataManagement = false
    @State private var showingClearDataAlert = false
    @State private var showingStatistics = false
    @State private var showingAPIConfig = false

    var currentConfig: APIConfig {
        if let config = apiConfigs.first {
            return config
        }
        let newConfig = APIConfig()
        modelContext.insert(newConfig)
        try? modelContext.save()
        return newConfig
    }

    var body: some View {
        NavigationStack {
            List {
                Section("豆包配置") {
                    Button(action: {
                        showingAPIConfig = true
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("豆包链接配置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("数据管理") {
                    Button(action: {
                        showingMerchantManagement = true
                    }) {
                        HStack {
                            Image(systemName: "storefront.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("商家管理")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        showingDataManagement = true
                    }) {
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            Text("数据导入导出")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: {
                        showingStatistics = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("数据统计")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("iCloud 备份") {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Toggle("自动备份", isOn: $cloudSyncService.autoBackupEnabled)
                            .onChange(of: cloudSyncService.autoBackupEnabled) { _, newValue in
                                cloudSyncService.saveAutoBackupSetting(newValue)
                            }
                    }

                    if let lastSync = cloudSyncService.lastSyncDate {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 30)
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
                                .frame(width: 30)
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

                Section("调试") {
                    Button(role: .destructive, action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 30)
                            Text("清空所有数据")
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .alert("确认清空数据?", isPresented: $showingClearDataAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将删除所有数据，不可恢复！")
            }
            .navigationDestination(isPresented: $showingMerchantManagement) {
                MerchantManagementView()
            }
            .navigationDestination(isPresented: $showingDataManagement) {
                DataManagementView()
            }
            .navigationDestination(isPresented: $showingStatistics) {
                StatisticsView()
            }
            .navigationDestination(isPresented: $showingAPIConfig) {
                APIConfigView(config: currentConfig)
            }
        }
    }

    private func clearAllData() {
        try? modelContext.delete(model: ProductRecord.self)
        try? modelContext.delete(model: Merchant.self)
        try? modelContext.delete(model: MerchantCategory.self)
        try? modelContext.delete(model: Receipt.self)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [ProductRecord.self, Merchant.self], inMemory: true)
}
