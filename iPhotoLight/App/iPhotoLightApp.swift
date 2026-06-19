import SwiftUI

@main
struct iPhotoLightApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared

    init() {
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
                .environmentObject(localizationManager)
                .environment(\.locale, localizationManager.currentLanguage == .chinese ? Locale(identifier: "zh-Hans") : Locale(identifier: "en"))
        }
    }
}
