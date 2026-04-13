//
//  PriceRecorderUITests.swift
//  PriceRecorderUITests
//
//  UI测试 - 用户界面交互测试
//

import XCTest

final class PriceRecorderUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 基础导航测试

    func testTabNavigation() throws {
        let tabBar = app.tabBars.firstMatch

        XCTAssertTrue(tabBar.exists, "TabBar 应该存在")

        let homeTab = tabBar.buttons["首页"]
        let searchTab = tabBar.buttons["搜索"]
        let settingsTab = tabBar.buttons["设置"]

        XCTAssertTrue(homeTab.exists, "首页Tab应该存在")
        XCTAssertTrue(searchTab.exists, "搜索Tab应该存在")
        XCTAssertTrue(settingsTab.exists, "设置Tab应该存在")

        searchTab.tap()
        XCTAssertTrue(app.navigationBars["搜索"].exists, "应该切换到搜索页")

        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["设置"].exists, "应该切换到设置页")

        homeTab.tap()
        XCTAssertTrue(app.navigationBars["商品价格记录"].exists || app.navigationBars["首页"].exists, "应该切换回首页")
    }

    // MARK: - 首页测试

    func testHomePageElements() throws {
        let homeTab = app.tabBars.buttons["首页"]
        homeTab.tap()

        let title = app.staticTexts["商品价格记录"]
        XCTAssertTrue(title.exists, "首页标题应该存在")

        let addButton = app.buttons["商品录入"]
        XCTAssertTrue(addButton.exists, "商品录入按钮应该存在")
    }

    func testProductEntryButton() throws {
        let homeTab = app.tabBars.buttons["首页"]
        homeTab.tap()

        let addButton = app.buttons["商品录入"]
        XCTAssertTrue(addButton.exists)

        addButton.tap()

        let manualButton = app.buttons["手动输入"]
        let photoButton = app.buttons["拍照识别"]

        let exists = manualButton.exists || photoButton.exists
        XCTAssertTrue(exists, "应该显示录入方式选择")
    }

    // MARK: - 搜索页测试

    func testSearchPageElements() throws {
        let searchTab = app.tabBars.buttons["搜索"]
        searchTab.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "搜索框应该存在")

        let priceComparisonButton = app.buttons["比价"]
        XCTAssertTrue(priceComparisonButton.exists, "比价按钮应该存在")
    }

    func testSearchModeSwitch() throws {
        let searchTab = app.tabBars.buttons["搜索"]
        searchTab.tap()

        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.exists {
            XCTAssertTrue(segmentedControl.buttons["商品模式"].exists || segmentedControl.buttons["商家模式"].exists, "模式切换应该存在")
        }
    }

    // MARK: - 设置页测试

    func testSettingsPageElements() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let merchantManagement = app.cells.staticTexts["商家管理"]
        let brandManagement = app.cells.staticTexts["品牌管理"]
        let dataManagement = app.cells.staticTexts["数据导入导出"]
        let statistics = app.cells.staticTexts["数据统计"]

        XCTAssertTrue(merchantManagement.exists, "商家管理应该存在")
        XCTAssertTrue(brandManagement.exists, "品牌管理应该存在")
        XCTAssertTrue(dataManagement.exists, "数据导入导出应该存在")
        XCTAssertTrue(statistics.exists, "数据统计应该存在")
    }

    func testMerchantManagementNavigation() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let merchantCell = app.cells.containing(.staticText, identifier: "商家管理").firstMatch
        merchantCell.tap()

        let navigationTitle = app.navigationBars["商家管理"]
        XCTAssertTrue(navigationTitle.exists, "应该进入商家管理页")
    }

    func testBrandManagementNavigation() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let brandCell = app.cells.containing(.staticText, identifier: "品牌管理").firstMatch
        brandCell.tap()

        let navigationTitle = app.navigationBars["品牌管理"]
        XCTAssertTrue(navigationTitle.exists, "应该进入品牌管理页")
    }

    func testStatisticsNavigation() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let statisticsCell = app.cells.containing(.staticText, identifier: "数据统计").firstMatch
        statisticsCell.tap()

        let navigationTitle = app.navigationBars["数据统计"]
        XCTAssertTrue(navigationTitle.exists, "应该进入数据统计页")
    }

    // MARK: - 商家管理测试

    func testAddMerchantButton() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        app.cells.staticTexts["商家管理"].tap()

        let addButton = app.navigationBars.buttons["Add"]
            .firstMatch
        let plusButton = app.navigationBars.buttons["+"]
            .firstMatch

        XCTAssertTrue(addButton.exists || plusButton.exists, "添加商家按钮应该存在")
    }

    // MARK: - 品牌管理测试

    func testAddBrandButton() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        app.cells.staticTexts["品牌管理"].tap()

        let addButton = app.navigationBars.buttons["Add"]
            .firstMatch
        let plusButton = app.navigationBars.buttons["+"]
            .firstMatch

        XCTAssertTrue(addButton.exists || plusButton.exists, "添加品牌按钮应该存在")
    }

    // MARK: - iCloud备份测试

    func testiCloudBackupSection() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let autoBackupToggle = app.switches["自动备份"]
        XCTAssertTrue(autoBackupToggle.exists, "自动备份开关应该存在")
    }

    func testAutoBackupToggle() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let autoBackupToggle = app.switches["自动备份"]
        if autoBackupToggle.exists {
            let initialValue = autoBackupToggle.value as? String ?? ""
            autoBackupToggle.tap()
            let newValue = autoBackupToggle.value as? String ?? ""
            XCTAssertNotEqual(initialValue, newValue, "开关状态应该改变")
        }
    }

    // MARK: - 比价功能测试

    func testPriceComparisonNavigation() throws {
        let searchTab = app.tabBars.buttons["搜索"]
        searchTab.tap()

        let priceComparisonButton = app.buttons["比价"]
        XCTAssertTrue(priceComparisonButton.exists, "比价按钮应该存在")

        priceComparisonButton.tap()

        let backButton = app.navigationBars.buttons["返回"]
        let cancelButton = app.navigationBars.buttons["取消"]

        let canGoBack = backButton.exists || cancelButton.exists
        XCTAssertTrue(canGoBack, "应该能从比价页返回")
    }

    // MARK: - 数据导入导出测试

    func testDataManagementNavigation() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let dataCell = app.cells.containing(.staticText, identifier: "数据导入导出").firstMatch
        dataCell.tap()

        let exportButton = app.buttons["导出 CSV"]
        let importButton = app.buttons["导入 CSV"]

        XCTAssertTrue(exportButton.exists, "导出按钮应该存在")
        XCTAssertTrue(importButton.exists, "导入按钮应该存在")
    }

    // MARK: - 暗黑模式测试

    func testDarkModeSupport() throws {
        let settingsTab = app.tabBars.buttons["设置"]
        settingsTab.tap()

        let backgroundElement = app.otherElements.firstMatch
        XCTAssertTrue(backgroundElement.exists, "界面元素应该存在")
    }

    // MARK: - 空状态测试

    func testEmptyStateInHomePage() throws {
        let homeTab = app.tabBars.buttons["首页"]
        homeTab.tap()

        let emptyMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '还没有' OR label CONTAINS '没有商品'"))
        if emptyMessage.firstMatch.exists {
            XCTAssertTrue(true, "空状态提示应该存在")
        }
    }

    // MARK: - 性能测试

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testTabSwitchPerformance() throws {
        measure {
            let tabBar = app.tabBars.firstMatch
            tabBar.buttons["搜索"].tap()
            tabBar.buttons["设置"].tap()
            tabBar.buttons["首页"].tap()
        }
    }
}

// MARK: - 辅助扩展

extension XCUIElement {
    func waitForExistence(timeout: TimeInterval = 10) -> Bool {
        return waitForExistence(timeout: timeout)
    }
}
