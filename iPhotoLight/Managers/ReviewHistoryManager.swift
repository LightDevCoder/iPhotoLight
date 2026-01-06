import Foundation

class ReviewHistoryManager {
    static let shared = ReviewHistoryManager()
    
    private let key = "reviewed_asset_ids"
    private var reviewedIDs: Set<String> = []
    
    private init() {
        // 初始化时从本地加载
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            reviewedIDs = Set(saved)
        }
    }
    
    /// 标记一个资源为“已阅” (Keep)
    func markAsReviewed(_ id: String) {
        reviewedIDs.insert(id)
        save()
    }
    
    /// 检查资源是否已阅
    func isReviewed(_ id: String) -> Bool {
        return reviewedIDs.contains(id)
    }
    
    /// 获取所有已阅 ID 集合（用于过滤）
    var allReviewedIDs: Set<String> {
        return reviewedIDs
    }
    
    /// 清除历史（比如用户在设置里想重置整理进度）
    func clearHistory() {
        reviewedIDs.removeAll()
        save()
    }
    
    private func save() {
        UserDefaults.standard.set(Array(reviewedIDs), forKey: key)
    }
}
