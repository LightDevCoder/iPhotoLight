import SwiftUI
import Combine

enum Language: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // 监听语言变化，自动触发 UI 刷新
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        if let savedString = UserDefaults.standard.string(forKey: "appLanguage"),
           let savedLang = Language(rawValue: savedString) {
            self.currentLanguage = savedLang
        } else {
            self.currentLanguage = .english
        }
    }
    
    func toggleLanguage() {
        withAnimation {
            currentLanguage = (currentLanguage == .english) ? .chinese : .english
        }
    }
    
    private let translations: [String: [Language: String]] = [
        // --- 核心 Tabs ---
        "Photos": [.english: "Photos", .chinese: "照片"],
        "Videos": [.english: "Videos", .chinese: "视频"],
        "Stats": [.english: "Stats", .chinese: "统计"],
        
        // --- Stats 页面 ---
        "Storage Manager": [.english: "Stats", .chinese: "使用统计"], // 按你要求修改
        "Total Cleaned": [.english: "Total Cleaned", .chinese: "已清理总量"],
        "Storage Saved": [.english: "Storage Saved", .chinese: "已节省空间"],
        "Reset Review History": [.english: "Reset Review History", .chinese: "重置已阅记录"],
        "Switch Language": [.english: "Switch Language", .chinese: "切换语言"],
        "Viewed": [.english: "Viewed", .chinese: "已阅"],
        "Deleted": [.english: "Deleted", .chinese: "待删"],
        "Cleaned": [.english: "Cleaned", .chinese: "已清理"],
        
        // --- Settings 设置页 ---
        "Settings": [.english: "Settings", .chinese: "设置"],
        "Manual Input": [.english: "Manual Input", .chinese: "手动输入"],
        "Custom Amount": [.english: "Custom Amount", .chinese: "自定义数量"],
        "Enter number": [.english: "Enter number", .chinese: "输入数字"],
        "Enter 0 or select 'Unlimited' to load all items.": [.english: "Enter 0 or select 'Unlimited' to load all items.", .chinese: "输入 0 或选择“无限”以加载所有项目。"],
        "Quick Select": [.english: "Quick Select", .chinese: "快速选择"],
        "Current Limit": [.english: "Current Limit", .chinese: "当前限制"],
        "Unlimited": [.english: "Unlimited", .chinese: "无限"],
        "Items": [.english: "Items", .chinese: "项"],
        "Data Management": [.english: "Data Management", .chinese: "数据管理"],
        "Reset All Statistics": [.english: "Reset All Statistics", .chinese: "重置所有统计"],
        "This will clear 'Cleaned Space' counter and 'Deleted' count.": [.english: "This will clear 'Cleaned Space' counter and 'Deleted' count.", .chinese: "这将清除“已清理空间”计数器和“已删除”计数。"],
        "Reset All Stats?": [.english: "Reset All Stats?", .chinese: "重置所有统计？"],
        "This will clear your 'Cleaned Space' achievement and deleted counts. This cannot be undone.": [.english: "This will clear your 'Cleaned Space' achievement and deleted counts. This cannot be undone.", .chinese: "这将清除您的“已清理空间”成就和已删除计数。此操作无法撤销。"],
        "Reset All": [.english: "Reset All", .chinese: "全部重置"],
        "Done": [.english: "Done", .chinese: "完成"],
        "Access Required": [.english: "Access Required", .chinese: "需要访问权限"],
        "iPhotoLight needs access to your photo library to help you organize and clean up.": [.english: "iPhotoLight needs access to your photo library to help you organize and clean up.", .chinese: "iPhotoLight 需要访问您的相册以帮助您整理和清理照片。"],
        "Open Settings": [.english: "Open Settings", .chinese: "打开设置"],
        
        // --- Trash / Review Pages 删除确认页 ---
        "Review Delete": [.english: "Review Delete", .chinese: "确认删除"],
        "Close": [.english: "Close", .chinese: "关闭"],
        "Trash is Empty": [.english: "Trash is Empty", .chinese: "废纸篓为空"],
        "No photos pending delete": [.english: "No photos pending delete", .chinese: "暂无待删除照片"],
        "Tap button below to restore all": [.english: "Tap button below to restore all", .chinese: "点击下方按钮全部恢复"],
        "Unselected videos will be restored": [.english: "Unselected videos will be restored", .chinese: "未选中的视频将被恢复"],
        "Unselected photos will be restored": [.english: "Unselected photos will be restored", .chinese: "未选中的照片将被恢复"],
        "Restore All": [.english: "Restore All", .chinese: "全部恢复"],
        "Delete": [.english: "Delete", .chinese: "删除"], // 用于拼接 "Delete 5 Photos"
        "Confirm Deletion": [.english: "Confirm Deletion", .chinese: "确认删除"],
        "Cancel": [.english: "Cancel", .chinese: "取消"],
        "Selected videos will be deleted. Unselected ones will be restored to your library.": [.english: "Selected videos will be deleted. Unselected ones will be restored to your library.", .chinese: "选中的视频将被删除，未选中的将恢复至相册。"],
        "Are you sure? Unselected photos will be kept.": [.english: "Are you sure? Unselected photos will be kept.", .chinese: "确定吗？未选中的照片将被保留。"],
        
        // Common Assets
        "Screenshots": [.english: "Screenshots", .chinese: "截图"]
    ]
    
    func localized(_ key: String) -> String {
        return translations[key]?[currentLanguage] ?? key
    }
}

extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
