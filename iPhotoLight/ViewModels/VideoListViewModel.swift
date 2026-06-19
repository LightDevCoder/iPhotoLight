import SwiftUI
import Photos

@MainActor
final class VideoListViewModel: ObservableObject {
    @Published var videos: [PhotoAsset] = []
    @Published var assetsToDelete: [PhotoAsset] = []
    @Published var isLoading = false
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined

    @AppStorage("organizeBatchSize") private var batchSize: Int = 20

    private let libraryManager = PhotoLibraryManager.shared
    private var loadGeneration = 0

    func checkPermissionAndLoad() async {
        let status = await libraryManager.checkPermission()
        permissionStatus = status

        if status == .authorized || status == .limited {
            loadVideos()
        }
    }

    func loadVideos() {
        loadGeneration += 1
        let generation = loadGeneration
        let requestedBatchSize = batchSize
        let pendingDeleteIDs = Set(assetsToDelete.map(\.id))
        let reviewedIDs = ReviewHistoryManager.shared.allReviewedIDs
        let libraryManager = libraryManager

        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let limit = requestedBatchSize == 0 ? 1000 : requestedBatchSize
            let fetchLimit = limit * 5
            let fetchedAssets = libraryManager.fetchVideos(limit: fetchLimit)
            let filteredAssets = fetchedAssets.filter { asset in
                !reviewedIDs.contains(asset.id) && !pendingDeleteIDs.contains(asset.id)
            }
            let finalAssets = Array(
                filteredAssets.prefix(
                    requestedBatchSize == 0 ? filteredAssets.count : requestedBatchSize
                )
            )

            DispatchQueue.main.async {
                guard let self, generation == self.loadGeneration else { return }
                self.videos = finalAssets
                self.isLoading = false
            }
        }
    }

    func keepVideo(at index: Int) {
        guard videos.indices.contains(index) else { return }
        let video = videos[index]

        ReviewHistoryManager.shared.markAsReviewed(video.id)
        removeVideo(at: index)
    }

    func deleteVideo(at index: Int) {
        guard videos.indices.contains(index) else { return }
        let video = videos[index]

        if !assetsToDelete.contains(where: { $0.id == video.id }) {
            assetsToDelete.append(video)
        }
        TrashManager.shared.addToTrash(asset: video.asset)
        removeVideo(at: index)
    }

    private func removeVideo(at index: Int) {
        videos.remove(at: index)
    }

    func restoreFromTrash(_ asset: PhotoAsset) {
        if let index = assetsToDelete.firstIndex(where: { $0.id == asset.id }) {
            assetsToDelete.remove(at: index)
            TrashManager.shared.restore(asset.id)
        }
    }

    func confirmDeletion(completion: @escaping (Bool) -> Void) {
        guard !assetsToDelete.isEmpty else {
            completion(true)
            return
        }

        let phAssets = assetsToDelete.map { $0.asset }

        libraryManager.deleteAssets(phAssets) { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.assetsToDelete.removeAll()
                    self?.loadVideos()
                }
                completion(success)
            }
        }
    }
}
