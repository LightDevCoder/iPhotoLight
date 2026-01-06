import Foundation
internal import Photos
import UIKit // 用于 UIWindowScene
import PhotosUI // 【核心修复】必须导入这个框架，才能使用 presentLimitedLibraryPicker

class PhotoLibraryManager {
    
    // MARK: - Singleton
    static let shared = PhotoLibraryManager()
    
    private let imageManager = PHCachingImageManager()
    
    private init() {}
    
    // MARK: - Permission Check
    
    /// 检查并请求权限
    func checkPermission() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status == .notDetermined {
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    continuation.resume(returning: newStatus)
                }
            }
        }
        
        return status
    }
    
    // MARK: - Fetching Assets
    
    /// 获取指定分类的照片
    func fetchAssets(in category: PhotoCategory, limit: Int = 0) -> [PhotoAsset] {
        let options = PHFetchOptions()
        
        // 排序：按创建时间倒序 (最新的在最前)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // 谓词过滤 (根据 Category)
        if let predicate = category.predicate {
            options.predicate = predicate
        }
        
        // 如果有数量限制，fetchLimit 也可以设置 (虽然 PhotoKit 的 limit 只是建议)
        if limit > 0 {
            options.fetchLimit = limit
        }
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PhotoAsset] = []
        
        // 遍历结果
        // 注意：PHFetchResult 不支持直接 prefix，需要 enumerate
        let countToFetch = limit == 0 ? result.count : min(limit, result.count)
        
        result.enumerateObjects { asset, index, stop in
            if index < countToFetch {
                assets.append(PhotoAsset(asset: asset))
            } else {
                stop.pointee = true
            }
        }
        
        return assets
    }
    
    /// 获取视频
    func fetchVideos(limit: Int = 0) -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if limit > 0 { options.fetchLimit = limit }
        
        let result = PHAsset.fetchAssets(with: .video, options: options)
        var assets: [PhotoAsset] = []
        
        let countToFetch = limit == 0 ? result.count : min(limit, result.count)
        result.enumerateObjects { asset, index, stop in
            if index < countToFetch {
                assets.append(PhotoAsset(asset: asset))
            } else {
                stop.pointee = true
            }
        }
        return assets
    }
    
    // MARK: - Image Requesting
    
    /// 请求图片 (生成 UIImage)
    func requestImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }
    
    // MARK: - Deletion
    
    /// 删除资产 (需要弹窗确认)
    func deleteAssets(_ assets: [PHAsset], completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: - Permission Helpers (UI Related)

    /// 打开系统设置页 (用于用户被拒绝后手动开启)
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    /// 唤起“有限访问”的选择器 (用于 Limited 状态下增加照片)
    /// 唤起“有限访问”的选择器 (修复版)
    func presentLimitedLibraryPicker() {
        DispatchQueue.main.async {
            // 1. 尝试寻找当前活跃的 Scene
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? scenes.first as? UIWindowScene
            
            // 2. 寻找 Key Window
            guard let window = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first,
                    let rootVC = window.rootViewController else {
                print("Error: Could not find root view controller to present picker.")
                return
            }
            
            // 3. 找到最顶层的 Presented ViewController (防止被其他弹窗挡住)
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: topController)
        }
    }
}
