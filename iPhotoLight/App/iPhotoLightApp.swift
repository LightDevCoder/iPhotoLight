import SwiftUI

@main
struct iPhotoLightApp: App {
    
    init() {
        // 1. 设置 NavigationBar 透明
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground() // 关键：完全透明
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        // 移除底部分割线
        navAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // 2. (可选) 如果你以后用了 List，也要把 TableView 背景去掉
        UITableView.appearance().backgroundColor = .clear
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
