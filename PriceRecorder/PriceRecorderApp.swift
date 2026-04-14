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
        do {
            let schema = Schema([
                ProductRecord.self,
                Merchant.self,
                MerchantCategory.self,
                Receipt.self
            ])
            container = try ModelContainer(for: schema, configurations: [
                ModelConfiguration(isStoredInMemoryOnly: false)
            ])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
        .modelContainer(for: [ProductRecord.self, Merchant.self], inMemory: true)
}
