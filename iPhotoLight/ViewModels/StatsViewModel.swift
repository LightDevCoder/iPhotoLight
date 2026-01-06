import SwiftUI
internal import Photos
import Combine

struct CategoryStatData {
    let typeName: String
    let icon: String
    let color: Color
    var viewedCount: Int
    var deletedCount: Int
    var savedSpace: String
}

class StatsViewModel: ObservableObject {
    // 初始化时使用 localized key，虽然稍后 loadStats 会覆盖它
    @Published var photoStats = CategoryStatData(typeName: "Photos".localized, icon: "photo", color: .blue, viewedCount: 0, deletedCount: 0, savedSpace: "0")
    @Published var screenshotStats = CategoryStatData(typeName: "Screenshots".localized, icon: "camera.viewfinder", color: .red, viewedCount: 0, deletedCount: 0, savedSpace: "0")
    @Published var videoStats = CategoryStatData(typeName: "Videos".localized, icon: "play.rectangle", color: .green, viewedCount: 0, deletedCount: 0, savedSpace: "0")
    
    @Published var totalSavedSpace: String = "0"
    @Published var totalReviewedCount: Int = 0
    @Published var totalDeletedCount: Int = 0
    
    @Published var photoPercent: CGFloat = 0.33
    @Published var screenshotPercent: CGFloat = 0.33
    @Published var videoPercent: CGFloat = 0.33
    
    func loadStats() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let trash = TrashManager.shared
            let deletedPhotosCount = trash.getCount(for: .photo)
            let deletedScreenshotsCount = trash.getCount(for: .screenshot)
            let deletedVideosCount = trash.getCount(for: .video)
            
            let reviewedIDs = ReviewHistoryManager.shared.allReviewedIDs
            var reviewedPhotos = 0
            var reviewedScreenshots = 0
            var reviewedVideos = 0
            
            if !reviewedIDs.isEmpty {
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
            
            DispatchQueue.main.async {
                self.totalReviewedCount = reviewedIDs.count
                self.totalDeletedCount = deletedPhotosCount + deletedScreenshotsCount + deletedVideosCount
                self.totalSavedSpace = self.formatBytes(trash.totalSize)
                
                // 【修改点】这里使用 .localized 确保卡片标题随语言变化
                self.photoStats = CategoryStatData(
                    typeName: "Photos".localized,
                    icon: "photo",
                    color: .blue,
                    viewedCount: reviewedPhotos,
                    deletedCount: deletedPhotosCount,
                    savedSpace: self.formatBytes(trash.getSize(for: .photo))
                )
                
                self.screenshotStats = CategoryStatData(
                    typeName: "Screenshots".localized,
                    icon: "camera.viewfinder",
                    color: .red,
                    viewedCount: reviewedScreenshots,
                    deletedCount: deletedScreenshotsCount,
                    savedSpace: self.formatBytes(trash.getSize(for: .screenshot))
                )
                
                self.videoStats = CategoryStatData(
                    typeName: "Videos".localized,
                    icon: "play.rectangle",
                    color: .green,
                    viewedCount: reviewedVideos,
                    deletedCount: deletedVideosCount,
                    savedSpace: self.formatBytes(trash.getSize(for: .video))
                )
                
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
        loadStats()
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 { return "0" }
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
