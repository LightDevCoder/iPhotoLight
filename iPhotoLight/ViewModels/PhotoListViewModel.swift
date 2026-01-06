import SwiftUI
internal import Photos
import Combine

// 定义手势方向
enum SwipeAction {
    case keep   // 左滑：保留
    case delete // 上滑：进入删除队列
}

@MainActor
class PhotoListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentCategory: PhotoCategory = .all {
            didSet {
                // 【修复问题1】监听分类变化，立即刷新数据
                // 取消之前的任何加载任务，重新开始
                loadAssets()
            }
        }
    @Published var displayedAssets: [PhotoAsset] = []
    @Published var assetsToDelete: [PhotoAsset] = []
    @Published var showTrashReview: Bool = false
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    
    // 整理数量设置 (AppStorage 自动持久化)
    @AppStorage("organizeBatchSize") var batchSize: Int = 50
    
    private let manager = PhotoLibraryManager.shared
    
    // MARK: - Init
    init() {
        Task {
            await checkPermissionAndLoad()
        }
    }
    
    // MARK: - Loading Logic
    func checkPermissionAndLoad() async {
        let status = await manager.checkPermission()
        self.permissionStatus = status
        
        if status == .authorized || status == .limited {
            loadAssets()
        }
    }
    
    func selectCategory(_ category: PhotoCategory) {
        self.currentCategory = category
        loadAssets()
    }
    
    func loadAssets() {
        guard !isLoading else { return }
        isLoading = true
        
        // 放到后台线程处理数据过滤，避免卡顿
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 1. 确定抓取策略
            let targetCount = self.batchSize == 0 ? 1000 : self.batchSize
            let fetchLimit = targetCount * 5
            
            // 2. 从 PhotoKit 获取原始数据
            let fetched = self.manager.fetchAssets(in: self.currentCategory, limit: fetchLimit)
            
            // 3. 过滤逻辑
            let pendingDeleteIDs = Set(self.assetsToDelete.map { $0.id })
            let historyManager = ReviewHistoryManager.shared
            
            let filteredAssets = fetched.filter { asset in
                // 过滤掉：待删除的 OR 历史已阅的
                !pendingDeleteIDs.contains(asset.id) && !historyManager.isReviewed(asset.id)
            }
            
            // 4. 截取最终展示的数量
            let finalAssets = Array(filteredAssets.prefix(self.batchSize == 0 ? filteredAssets.count : self.batchSize))
            
            // 5. 回到主线程更新 UI
            DispatchQueue.main.async {
                self.displayedAssets = finalAssets
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Swipe Logic
    func handleSwipe(asset: PhotoAsset, action: SwipeAction) {
        // 1. 立即从当前显示堆栈中移除
        if let index = displayedAssets.firstIndex(of: asset) {
            displayedAssets.remove(at: index)
        }
        
        // 2. 业务逻辑
        switch action {
        case .keep:
            // 左滑保留：记入“已阅历史”
            ReviewHistoryManager.shared.markAsReviewed(asset.id)
            
        case .delete:
            // 上滑删除：
            // A. 加入本地待删除队列 (用于 TrashReviewView 展示)
            if !assetsToDelete.contains(where: { $0.id == asset.id }) {
                assetsToDelete.append(asset)
            }
            
            // B. 通知 TrashManager 记录统计数据
            TrashManager.shared.addToTrash(asset: asset.asset)
        }
        
        // 3. 自动跳转回顾页
        if displayedAssets.isEmpty && !assetsToDelete.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showTrashReview = true
            }
        }
    }
    
    // MARK: - Deletion & Restore Logic
    
    /// 恢复单个照片
    func restoreFromTrash(asset: PhotoAsset) {
        if let index = assetsToDelete.firstIndex(of: asset) {
            assetsToDelete.remove(at: index)
        }
        // 同步扣除统计
        TrashManager.shared.restore(asset.id)
    }
    
    /// 【新增】恢复全部照片 (用于 TrashReviewView 的 Restore All)
    func restoreAll() {
        // 1. 遍历所有待删除的项目，逐个通知 Manager 恢复统计
        for asset in assetsToDelete {
            TrashManager.shared.restore(asset.id)
        }
        
        // 2. 清空数组
        assetsToDelete.removeAll()
        
        // 3. 重新加载 (可选，或者关闭页面)
        showTrashReview = false
        loadAssets()
    }
    
    /// 确认删除 (调用 PhotoLibraryManager 执行物理删除)
    func confirmDeletion(completion: @escaping (Bool) -> Void) {
        // 1. 获取当前 assetsToDelete 中的所有 PHAsset
        let phAssets = assetsToDelete.map { $0.asset }
        
        guard !phAssets.isEmpty else {
            completion(true)
            return
        }
        
        // 2. 调用 Manager 执行物理删除
        PhotoLibraryManager.shared.deleteAssets(phAssets) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // 物理删除成功
                    // 注意：这里不需要调用 restore，因为是真的删了，成就感要保留
                    self?.assetsToDelete.removeAll()
                    self?.loadAssets() // 加载下一批
                } else if let error = error {
                    print("Error deleting assets: \(error.localizedDescription)")
                }
                
                completion(success)
            }
        }
    }
    private func cleanupAfterDeletion() {
        self.assetsToDelete.removeAll()
        self.showTrashReview = false
        self.loadAssets()
    }
}
