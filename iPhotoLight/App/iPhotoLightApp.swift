import SwiftUI

@main
struct iPhotoLightApp: App {
    // 1. 初始化 LocalizationManager (确保单例被持有)
    @StateObject private var localizationManager = LocalizationManager.shared
    
    init() {
        // 设置 NavigationBar 透明
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        UITableView.appearance().backgroundColor = .clear
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                // 2. 注入环境对象，使所有子视图都能响应语言变化
                .environmentObject(localizationManager)
                // 强制设置环境中的 layoutDirection (如果未来支持阿语需要用到，目前可选)
                .environment(\.locale, localizationManager.currentLanguage == .chinese ? Locale(identifier: "zh-Hans") : Locale(identifier: "en"))
        }
    }
}
