import Foundation
internal import Photos
import Combine

class TrashManager {
    static let shared = TrashManager()
    
    private let storageKey = "com.iphotolight.trashItems"
    
    // 内存中的废纸篓列表
    @Published private(set) var items: Set<TrashItem> = []
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Public API
    
    /// 将资产加入废纸篓 (上滑操作调用)
    func addToTrash(asset: PHAsset) {
        // 1. 确定类型
        var type: TrashItemType = .photo
        if asset.mediaType == .video {
            type = .video
        } else if asset.mediaSubtypes.contains(.photoScreenshot) {
            type = .screenshot
        }
        
        // 2. 异步计算文件大小 (避免卡顿 UI)
        calculateSize(for: asset) { [weak self] sizeInBytes in
            guard let self = self else { return }
            
            let item = TrashItem(
                id: asset.localIdentifier,
                type: type,
                size: sizeInBytes,
                deleteDate: Date()
            )
            
            DispatchQueue.main.async {
                self.items.insert(item)
                self.saveToDisk()
                print("Moved to Trash: \(type) - \(item.formattedSize)")
            }
        }
    }
    
    /// 从废纸篓恢复 (点击恢复按钮调用)
    func restore(_ id: String) {
        if let item = items.first(where: { $0.id == id }) {
            items.remove(item)
            saveToDisk()
        }
    }
    
    /// 清空废纸篓 (执行真正的删除逻辑时调用)
    func emptyTrash() {
        items.removeAll()
        saveToDisk()
    }
    
    // 在 TrashManager 类中添加

    /// [新增] 重置所有统计数据 (归零 "Cleaned Space" 和 "Deleted Count")
    func resetStatistics() {
        items.removeAll()
        saveToDisk()
        // 发送通知让 StatsViewModel 更新 (或者依赖 View 的 onAppear 刷新)
        print("Trash statistics have been reset.")
    }
    
    // MARK: - Stats Helpers (供 StatsViewModel 调用)
    
    func getCount(for type: TrashItemType) -> Int {
        return items.filter { $0.type == type }.count
    }
    
    func getSize(for type: TrashItemType) -> Int64 {
        return items.filter { $0.type == type }.reduce(0) { $0 + $1.size }
    }
    
    var totalSize: Int64 {
        return items.reduce(0) { $0 + $1.size }
    }
    
    // MARK: - Private Helpers
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedItems = try? JSONDecoder().decode(Set<TrashItem>.self, from: data) {
            self.items = savedItems
        }
    }
    
    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    /// 获取 PHAsset 的文件大小
    private func calculateSize(for asset: PHAsset, completion: @escaping (Int64) -> Void) {
        // 使用 PHAssetResource 获取文件大小是最准确的方法
        let resources = PHAssetResource.assetResources(for: asset)
        var size: Int64 = 0
        
        // 通常取第一个主资源的大小即可
        if let resource = resources.first {
            if let unsignedSize = resource.value(forKey: "fileSize") as? CLong {
                size = Int64(unsignedSize)
            }
        }
        completion(size)
    }
}
