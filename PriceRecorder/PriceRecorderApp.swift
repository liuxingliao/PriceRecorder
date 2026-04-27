//
//  PriceRecorderApp.swift
//  PriceRecorder
//
//  主应用入口
//

import SwiftUI
import SwiftData

@main
struct PriceRecorderApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            ProductRecord.self,
            Merchant.self,
            MerchantCategory.self,
            Receipt.self,
            APIConfig.self,
            LLMConfig.self,
            AIMessage.self,
            AISession.self
        ])

        let storeURL = Self.storeURL

        do {
            container = try ModelContainer(for: schema, configurations: [
                ModelConfiguration(url: storeURL)
            ])
        } catch {
            print("Failed to create ModelContainer: \(error)")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite-wal"))
            do {
                container = try ModelContainer(for: schema, configurations: [
                    ModelConfiguration(url: storeURL)
                ])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    private static var storeURL: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent("pricedata_v2.store")
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            ProductRecord.self, Merchant.self, APIConfig.self,
            LLMConfig.self, AIMessage.self, AISession.self
        ], inMemory: true)
}
