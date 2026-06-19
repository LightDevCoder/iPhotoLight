import Foundation
import Photos
import PhotosUI
import UIKit

final class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()

    private let imageManager = PHCachingImageManager()

    private init() {}

    func checkPermission() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        guard status == .notDetermined else {
            return status
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                continuation.resume(returning: newStatus)
            }
        }
    }

    func fetchAssets(in category: PhotoCategory, limit: Int = 0) -> [PhotoAsset] {
        fetchAssets(mediaType: .image, predicate: category.predicate, limit: limit)
    }

    func fetchVideos(limit: Int = 0) -> [PhotoAsset] {
        fetchAssets(mediaType: .video, predicate: nil, limit: limit)
    }

    func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    func deleteAssets(_ assets: [PHAsset], completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        } completionHandler: { success, error in
            completion(success, error)
        }
    }

    @MainActor
    func openSystemSettings() {
        guard
            let url = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(url)
        else {
            return
        }

        UIApplication.shared.open(url)
    }

    @MainActor
    func presentLimitedLibraryPicker() {
        guard let presenter = topViewController() else {
            return
        }

        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter)
    }

    private func fetchAssets(
        mediaType: PHAssetMediaType,
        predicate: NSPredicate?,
        limit: Int
    ) -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = predicate
        options.fetchLimit = max(0, limit)

        let result = PHAsset.fetchAssets(with: mediaType, options: options)
        var assets: [PhotoAsset] = []

        result.enumerateObjects { asset, _, _ in
            assets.append(PhotoAsset(asset: asset))
        }

        return assets
    }

    @MainActor
    private func topViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }?
            .rootViewController

        if let navigationController = root as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabController = root as? UITabBarController {
            return topViewController(from: tabController.selectedViewController)
        }

        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }

        return root
    }
}
