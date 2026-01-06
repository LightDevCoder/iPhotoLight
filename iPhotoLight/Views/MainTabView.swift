//
//  MainTabView.swift
//  iPhotoLight
//

import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    // 1. 监听语言变化
    @EnvironmentObject var languageManager: LocalizationManager
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selection) {
            
            // Tab 0: Photos
            PhotoListView()
                .tabItem {
                    // 2. 使用 localized 获取翻译
                    Label("Photos".localized, systemImage: "photo.stack")
                }
                .tag(0)
            
            // Tab 1: Videos
            VideoListView()
                .tabItem {
                    Label("Videos".localized, systemImage: "play.rectangle")
                }
                .tag(1)
            
            // Tab 2: Stats
            StatsView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("Stats".localized)
                }
                .tag(2)
        }
        .zIndex(1)
        .accentColor(.black)
        // 3. 关键：当语言改变时，强制刷新 TabView ID 以确保 tabItem 文字重绘
        .id(languageManager.currentLanguage)
    }
}
