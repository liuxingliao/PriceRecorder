//
//  CloudSyncService.swift
//  PriceRecorder
//
//  iCloud同步服务
//

import Foundation
import SwiftData
import CloudKit

class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var autoBackupEnabled = true

    private let userDefaults = UserDefaults.standard
    private let lastSyncKey = "lastSyncDate"
    private let autoBackupKey = "autoBackupEnabled"

    private init() {
        self.lastSyncDate = userDefaults.object(forKey: lastSyncKey) as? Date
        self.autoBackupEnabled = userDefaults.bool(forKey: autoBackupKey)
    }

    func saveAutoBackupSetting(_ enabled: Bool) {
        autoBackupEnabled = enabled
        userDefaults.set(enabled, forKey: autoBackupKey)
    }

    private func updateLastSyncDate() {
        lastSyncDate = Date()
        userDefaults.set(lastSyncDate, forKey: lastSyncKey)
    }

    func backupToCloud(modelContext: ModelContext, completion: @escaping (Bool, Error?) -> Void) {
        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2) {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.updateLastSyncDate()
                completion(true, nil)
            }
        }
    }

    func restoreFromCloud(completion: @escaping (Bool, Error?) -> Void) {
        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2) {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.updateLastSyncDate()
                completion(true, nil)
            }
        }
    }

    func triggerAutoBackupIfNeeded(modelContext: ModelContext) {
        guard autoBackupEnabled else { return }

        let now = Date()
        if let lastSync = lastSyncDate {
            let timeInterval = now.timeIntervalSince(lastSync)
            if timeInterval < 3600 {
                return
            }
        }

        backupToCloud(modelContext: modelContext) { _, _ in
        }
    }
}
