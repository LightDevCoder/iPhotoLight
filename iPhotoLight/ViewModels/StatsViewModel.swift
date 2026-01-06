import SwiftUI
internal import Photos
import Combine

// 1. 定义单行数据的模型
struct CategoryStatData {
    let typeName: String
    let icon: String
    let color: Color
    var viewedCount: Int
    var deletedCount: Int
    var savedSpace: String
}

class StatsViewModel: ObservableObject {
    @Published var photoStats = CategoryStatData(typeName: "Photos", icon: "photo", color: .blue, viewedCount: 0, deletedCount: 0, savedSpace: "0")
    @Published var screenshotStats = CategoryStatData(typeName: "Screenshots", icon: "camera.viewfinder", color: .red, viewedCount: 0, deletedCount: 0, savedSpace: "0")
    @Published var videoStats = CategoryStatData(typeName: "Videos", icon: "play.rectangle", color: .green, viewedCount: 0, deletedCount: 0, savedSpace: "0")
    
    @Published var totalSavedSpace: String = "0"
    @Published var totalReviewedCount: Int = 0
    @Published var totalDeletedCount: Int = 0
    
    @Published var photoPercent: CGFloat = 0.33
    @Published var screenshotPercent: CGFloat = 0.33
    @Published var videoPercent: CGFloat = 0.33
    
    func loadStats() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 1. 获取废纸篓数据 (TrashManager)
            let trash = TrashManager.shared
            let deletedPhotosCount = trash.getCount(for: .photo)
            let deletedScreenshotsCount = trash.getCount(for: .screenshot)
            let deletedVideosCount = trash.getCount(for: .video)
            
            // 2. 【核心修复】准确计算已阅 (Viewed) 数量
            // 逻辑：从 ReviewHistoryManager 拿所有 ID -> 用 PHAsset 查类型 -> 统计数量
            let reviewedIDs = ReviewHistoryManager.shared.allReviewedIDs
            var reviewedPhotos = 0
            var reviewedScreenshots = 0
            var reviewedVideos = 0
            
            if !reviewedIDs.isEmpty {
                // 批量查询 ID 对应的资产类型 (性能通常很快)
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: Array(reviewedIDs), options: nil)
                
                assets.enumerateObjects { asset, _, _ in
                    if asset.mediaType == .video {
                        reviewedVideos += 1
                    } else if asset.mediaType == .image {
                        if asset.mediaSubtypes.contains(.photoScreenshot) {
                            reviewedScreenshots += 1
                        } else {
                            reviewedPhotos += 1
                        }
                    }
                }
            }
            // 注意：fetchAssets 可能查不到已经彻底物理删除的图，
            // 但因为我们的逻辑是“先软删除进 Trash”，PHAsset 对象通常还在，或者 TrashManager 里的计数能帮我们需要补齐。
            // 这里为了 UI 逻辑简单：Viewed 显示的是“当前还能查到的历史记录”。
            // 如果你希望 Viewed 包含已物理删除的，可以将 deletedCounts 加回来（视需求而定），
            // 但目前 fetchAssets 逻辑对于“重置归零”是最稳健的。
            
            DispatchQueue.main.async {
                self.totalReviewedCount = reviewedIDs.count
                self.totalDeletedCount = deletedPhotosCount + deletedScreenshotsCount + deletedVideosCount
                
                // 格式化总空间
                self.totalSavedSpace = self.formatBytes(trash.totalSize)
                
                // 更新 UI数据
                self.photoStats = CategoryStatData(
                    typeName: "Photos",
                    icon: "photo",
                    color: .blue,
                    viewedCount: reviewedPhotos, // 修复：使用真实统计值
                    deletedCount: deletedPhotosCount,
                    savedSpace: self.formatBytes(trash.getSize(for: .photo))
                )
                
                self.screenshotStats = CategoryStatData(
                    typeName: "Screenshots",
                    icon: "camera.viewfinder",
                    color: .red,
                    viewedCount: reviewedScreenshots, // 修复：使用真实统计值
                    deletedCount: deletedScreenshotsCount,
                    savedSpace: self.formatBytes(trash.getSize(for: .screenshot))
                )
                
                self.videoStats = CategoryStatData(
                    typeName: "Videos",
                    icon: "play.rectangle",
                    color: .green,
                    viewedCount: reviewedVideos, // 修复：使用真实统计值
                    deletedCount: deletedVideosCount,
                    savedSpace: self.formatBytes(trash.getSize(for: .video))
                )
                
                // 计算比例 (保持不变)
                let totalDeleted = Double(self.totalDeletedCount)
                if totalDeleted > 0 {
                    self.photoPercent = Double(deletedPhotosCount) / totalDeleted
                    self.screenshotPercent = Double(deletedScreenshotsCount) / totalDeleted
                    self.videoPercent = Double(deletedVideosCount) / totalDeleted
                } else {
                    self.photoPercent = 0.33; self.screenshotPercent = 0.33; self.videoPercent = 0.33
                }
            }
        }
    }
    
    func resetHistory() {
        ReviewHistoryManager.shared.clearHistory()
        // 这里的 loadStats 会重新获取 IDs，因为清空了所以 fetch 结果为 0，UI 会瞬间归零
        loadStats()
    }
    
    // 辅助：统一的格式化逻辑
    private func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 { return "0" } // 强制显示 0
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB, .useKB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Helper
    private func fetchCount(mediaType: PHAssetMediaType, subtype: PHAssetMediaSubtype?) -> Int {
        let options = PHFetchOptions()
        if let subtype = subtype {
            options.predicate = NSPredicate(format: "mediaSubtypes == %ld", subtype.rawValue)
        }
        return PHAsset.fetchAssets(with: mediaType, options: options).count
    }
}
