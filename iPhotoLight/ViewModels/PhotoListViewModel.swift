import SwiftUI
import Photos

enum SwipeAction {
    case keep
    case delete
}

@MainActor
final class PhotoListViewModel: ObservableObject {
    @Published var currentCategory: PhotoCategory = .all {
        didSet {
            guard currentCategory != oldValue else { return }
            loadAssets()
        }
    }
    @Published var displayedAssets: [PhotoAsset] = []
    @Published var assetsToDelete: [PhotoAsset] = []
    @Published var showTrashReview = false
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false

    @AppStorage("organizeBatchSize") var batchSize: Int = 50

    private let manager = PhotoLibraryManager.shared
    private var loadGeneration = 0

    init() {
        Task {
            await checkPermissionAndLoad()
        }
    }

    func checkPermissionAndLoad() async {
        let status = await manager.checkPermission()
        permissionStatus = status

        if status == .authorized || status == .limited {
            loadAssets()
        }
    }

    func selectCategory(_ category: PhotoCategory) {
        if category == currentCategory {
            loadAssets()
        } else {
            currentCategory = category
        }
    }

    func loadAssets() {
        loadGeneration += 1
        let generation = loadGeneration
        let category = currentCategory
        let requestedBatchSize = batchSize
        let pendingDeleteIDs = Set(assetsToDelete.map(\.id))
        let reviewedIDs = ReviewHistoryManager.shared.allReviewedIDs
        let manager = manager

        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targetCount = requestedBatchSize == 0 ? 1000 : requestedBatchSize
            let fetchLimit = targetCount * 5
            let fetched = manager.fetchAssets(in: category, limit: fetchLimit)
            let filteredAssets = fetched.filter { asset in
                !pendingDeleteIDs.contains(asset.id) && !reviewedIDs.contains(asset.id)
            }
            let finalAssets = Array(
                filteredAssets.prefix(
                    requestedBatchSize == 0 ? filteredAssets.count : requestedBatchSize
                )
            )

            DispatchQueue.main.async {
                guard let self, generation == self.loadGeneration else { return }
                self.displayedAssets = finalAssets
                self.isLoading = false
            }
        }
    }

    func handleSwipe(asset: PhotoAsset, action: SwipeAction) {
        if let index = displayedAssets.firstIndex(of: asset) {
            displayedAssets.remove(at: index)
        }

        switch action {
        case .keep:
            ReviewHistoryManager.shared.markAsReviewed(asset.id)

        case .delete:
            if !assetsToDelete.contains(where: { $0.id == asset.id }) {
                assetsToDelete.append(asset)
            }
            TrashManager.shared.addToTrash(asset: asset.asset)
        }

        if displayedAssets.isEmpty && !assetsToDelete.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showTrashReview = true
            }
        }
    }
    
    func restoreFromTrash(asset: PhotoAsset) {
        if let index = assetsToDelete.firstIndex(of: asset) {
            assetsToDelete.remove(at: index)
        }
        TrashManager.shared.restore(asset.id)
    }

    func restoreAll() {
        for asset in assetsToDelete {
            TrashManager.shared.restore(asset.id)
        }

        assetsToDelete.removeAll()
        showTrashReview = false
        loadAssets()
    }

    func confirmDeletion(completion: @escaping (Bool) -> Void) {
        let phAssets = assetsToDelete.map { $0.asset }

        guard !phAssets.isEmpty else {
            completion(true)
            return
        }

        manager.deleteAssets(phAssets) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.assetsToDelete.removeAll()
                    self?.showTrashReview = false
                    self?.loadAssets()
                } else if let error = error {
                    print("Error deleting assets: \(error.localizedDescription)")
                }

                completion(success)
            }
        }
    }
}
