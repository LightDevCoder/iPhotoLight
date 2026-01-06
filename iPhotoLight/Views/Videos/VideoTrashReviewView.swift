import SwiftUI
internal import Photos

struct VideoTrashReviewView: View {
    @ObservedObject var viewModel: VideoListViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // 注入语言环境
    @EnvironmentObject var languageManager: LocalizationManager
    
    @State private var selectedIDs: Set<String> = []
    @State private var showConfirmationAlert = false
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 1. 内容区域
                if viewModel.assetsToDelete.isEmpty {
                    emptyTrashView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.assetsToDelete, id: \.id) { asset in
                                ZStack(alignment: .topTrailing) {
                                    // A. 视频缩略图
                                    VideoTrashThumbnail(asset: asset)
                                        .aspectRatio(1, contentMode: .fill)
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                        .clipped()
                                        .opacity(selectedIDs.contains(asset.id) ? 1.0 : 0.5)
                                    
                                    // B. 视频标识
                                    Image(systemName: "play.fill")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(6)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                        .position(x: 20, y: 20)
                                        .padding(4)
                                    
                                    // C. 选中状态指示器
                                    SelectionIndicator(isSelected: selectedIDs.contains(asset.id))
                                        .padding(6)
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(for: asset)
                                }
                            }
                        }
                    }
                }
                
                // 2. 底部操作栏
                VStack(spacing: 12) {
                    Text(selectedIDs.isEmpty ? "Tap button below to restore all".localized : "Unselected videos will be restored".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if selectedIDs.isEmpty {
                            handleFinalAction()
                        } else {
                            showConfirmationAlert = true
                        }
                    }) {
                        Text(buttonTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedIDs.isEmpty ? Color.blue : Color.red)
                            .cornerRadius(12)
                    }
                    .disabled(false)
                }
                .padding()
                .background(.thinMaterial)
            }
            .navigationTitle("Review Delete".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized) { presentationMode.wrappedValue.dismiss() }
                }
            }
            .onAppear {
                let allIDs = viewModel.assetsToDelete.map { $0.id }
                selectedIDs = Set(allIDs)
            }
            .alert("Confirm Deletion".localized, isPresented: $showConfirmationAlert) {
                Button("Delete".localized, role: .destructive) {
                    handleFinalAction()
                }
                Button("Cancel".localized, role: .cancel) { }
            } message: {
                Text("Selected videos will be deleted. Unselected ones will be restored to your library.".localized)
            }
        }
    }
    
    // MARK: - Logic
    
    private var buttonTitle: String {
        if selectedIDs.isEmpty {
            return "Restore All".localized
        } else {
            // 简单拼接："Delete" (删除) + 数量 + "Videos" (视频)
            // 中文效果：删除 5 视频 (虽然不如“个”完美，但通用性高且开发成本低)
            return "\("Delete".localized) \(selectedIDs.count) \("Videos".localized)"
        }
    }
    
    private func toggleSelection(for asset: PhotoAsset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedIDs.contains(asset.id) {
                selectedIDs.remove(asset.id)
            } else {
                selectedIDs.insert(asset.id)
            }
        }
    }
    
    private func handleFinalAction() {
        let assetsToDelete = viewModel.assetsToDelete.filter { selectedIDs.contains($0.id) }
        let assetsToRestore = viewModel.assetsToDelete.filter { !selectedIDs.contains($0.id) }
        
        for asset in assetsToRestore {
            viewModel.restoreFromTrash(asset)
        }
        
        if assetsToDelete.isEmpty {
            presentationMode.wrappedValue.dismiss()
        } else {
            viewModel.assetsToDelete = assetsToDelete
            viewModel.confirmDeletion { success in
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    var emptyTrashView: some View {
        VStack(spacing: 15) {
            Image(systemName: "trash.slash")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("Trash is Empty".localized)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 缩略图组件保持不变 (无需国际化)
struct VideoTrashThumbnail: View {
    let asset: PhotoAsset
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
            } else {
                Color.black.opacity(0.1)
                    .onAppear {
                        let manager = PHImageManager.default()
                        let options = PHImageRequestOptions()
                        options.isSynchronous = false
                        options.deliveryMode = .opportunistic
                        options.isNetworkAccessAllowed = true
                        
                        manager.requestImage(for: asset.asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { result, _ in
                            self.image = result
                        }
                    }
            }
        }
    }
}
