//
//  MainTabView.swift
//  iPhotoLight
//
//  Path: Views/MainTabView.swift
//

import SwiftUI

struct MainTabView: View {
    // 控制 Tab 选中状态
    @State private var selection = 0
    
    init() {
        // 【关键】配置 UIKit 的 TabBar 外观为透明
        // 这样我们的 LiquidBackground 才能透过底部的 TabBar 显示出来
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground() // 全透明
        
        // 可选：设置 Tab 选中时的颜色（例如黑色或特定主题色）
        // appearance.stackedLayoutAppearance.selected.iconColor = .black
        // appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selection) {
            
            // Tab 0: 照片整理
            PhotoListView()
                .tabItem {
                    Label("Photos", systemImage: "photo.stack")
                }
                .tag(0)
            
            // Tab 1: 视频整理 (已替换为真实页面)
            VideoListView()
                .tabItem {
                    Label("Videos", systemImage: "play.rectangle")
                }
                .tag(1)
            
            // 3. Stats Tab (正式接入)
            StatsView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("Stats")
                }
                .tag(2)
        }
        // 确保 TabView 不会被遮挡
        .zIndex(1)
        // 设置 TabBar 的强调色 (这里设为黑色以配合 Bradley Hand 字体风格)
        .accentColor(.black)
    }
}
