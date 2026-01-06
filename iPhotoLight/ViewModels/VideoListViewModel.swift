import SwiftUI
import Combine
internal import Photos // 遵守 PhotoKit 导入约束

class VideoListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var videos: [PhotoAsset] = []          // 待整理的视频卡片堆叠
    @Published var assetsToDelete: [PhotoAsset] = []  // 废纸篓队列
    @Published var isLoading: Bool = false
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    
    // MARK: - AppStorage Settings
    // 复用全局整理数量设置
    @AppStorage("organizeBatchSize") private var batchSize: Int = 20
    
    // MARK: - Dependencies
    private let libraryManager = PhotoLibraryManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        checkPermissionAndLoad()
    }
    
    // MARK: - Loading Logic
    func checkPermissionAndLoad() {
        // 简单封装权限检查
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.permissionStatus = status
        
        if status == .authorized || status == .limited {
            loadVideos()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.permissionStatus = newStatus
                    if newStatus == .authorized || newStatus == .limited {
                        self?.loadVideos()
                    }
                }
            }
        }
    }
    
    // MARK: - Loading Logic
    func loadVideos() {
        guard !isLoading else { return }
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let limit = self.batchSize == 0 ? 1000 : self.batchSize
            
            // 抓取更多以备过滤
            let fetchLimit = limit * 5
            let fetchedAssets = self.libraryManager.fetchVideos(limit: fetchLimit)
            
            // 【核心修改】过滤逻辑升级
            // 1. 过滤已阅 (HistoryManager)
            // 2. 过滤当前待删除队列 (防止删除后刷新又出现)
            let historyManager = ReviewHistoryManager.shared
            let pendingDeleteIDs = Set(self.assetsToDelete.map { $0.id })
            
            let filteredAssets = fetchedAssets.filter { asset in
                !historyManager.isReviewed(asset.id) && !pendingDeleteIDs.contains(asset.id)
            }
            
            // 截取
            let finalAssets = Array(filteredAssets.prefix(self.batchSize == 0 ? filteredAssets.count : self.batchSize))
            
            DispatchQueue.main.async {
                self.videos = finalAssets
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Swipe Logic
    
    func keepVideo(at index: Int) {
        guard videos.indices.contains(index) else { return }
        let video = videos[index]
        
        // 【核心修改】加入已阅历史
        ReviewHistoryManager.shared.markAsReviewed(video.id)
        
        removeVideo(at: index)
    }
    
    /// 上滑：删除视频 (移入废纸篓)
    func deleteVideo(at index: Int) {
        guard videos.indices.contains(index) else { return }
        let video = videos[index]
        
        assetsToDelete.append(video)
        
        // 【核心修改】通知 TrashManager 记录统计
        // 这一步会让 Stats 页面里的 "Cleaned" 和 "Deleted" 立即增加
        TrashManager.shared.addToTrash(asset: video.asset)
        
        removeVideo(at: index)
    }
    
    private func removeVideo(at index: Int) {
        // 从数组中移除，触发 UI 刷新
        videos.remove(at: index)
        
        // 如果所有视频都处理完了
        if videos.isEmpty {
            // 可以触发加载更多，或者显示空状态
            print("Video stack empty")
        }
    }
    
    // MARK: - Trash Logic
    
    /// 恢复废纸篓中的项目
    func restoreFromTrash(_ asset: PhotoAsset) {
        if let index = assetsToDelete.firstIndex(where: { $0.id == asset.id }) {
            assetsToDelete.remove(at: index)
            
            // 【核心修改】从 TrashManager 恢复，扣除统计数据
            TrashManager.shared.restore(asset.id)
            
            // 可选：是否加回 videos 堆叠？通常不需要，恢复意味着“保留”
        }
    }
    
    /// 执行最终物理删除 (调用 System API)
    func confirmDeletion(completion: @escaping (Bool) -> Void) {
        guard !assetsToDelete.isEmpty else {
            completion(true)
            return
        }
        
        let phAssets = assetsToDelete.map { $0.asset }
        
        libraryManager.deleteAssets(phAssets) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // 物理删除成功后清空本地队列
                    // 注意：不需要调用 TrashManager.emptyTrash()，因为我们要保留"总共节省了多少空间"的成就感数据
                    self?.assetsToDelete.removeAll()
                    
                    // 删除完后，通常建议重新加载下一批
                    self?.loadVideos()
                }
                completion(success)
            }
        }
    }
}
