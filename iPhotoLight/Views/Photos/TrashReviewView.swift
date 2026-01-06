import SwiftUI
internal import Photos

struct TrashReviewView: View {
    @ObservedObject var viewModel: PhotoListViewModel
    @Environment(\.dismiss) var dismiss
    
    // 【状态】记录哪些照片是被“勾选”要删除的
    // 逻辑：Selected (红圈) = 确认删除; Unselected (无圈) = 确认保留/恢复
    @State private var selectedIDs: Set<String> = []
    
    // 用于控制我们自己的“二次确认”弹窗
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
                            ForEach(viewModel.assetsToDelete) { asset in
                                ZStack(alignment: .topTrailing) {
                                    // 缩略图
                                    TrashThumbnail(asset: asset)
                                        .aspectRatio(1, contentMode: .fill)
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                        .clipped()
                                        // 未选中时增加遮罩，表示"保留"
                                        .opacity(selectedIDs.contains(asset.id) ? 1.0 : 0.5)
                                    
                                    // 选中状态指示器
                                    // (假设你项目里有这个 Views/Components/SelectionIndicator.swift 组件)
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
                    Text(selectedIDs.isEmpty ? "Tap button below to restore all" : "Unselected photos will be restored")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if selectedIDs.isEmpty {
                            // 一个都没选 -> 全部恢复
                            handleFinalAction()
                        } else {
                            // 有选中的 -> 弹窗确认删除
                            showConfirmationAlert = true
                        }
                    }) {
                        // 动态按钮标题
                        Text(buttonTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            // 样式区分：删除用红，恢复用蓝
                            .background(selectedIDs.isEmpty ? Color.blue : Color.red)
                            .cornerRadius(12)
                    }
                    // 永远不禁用，确保 Restore All 可用
                    .disabled(false)
                }
                .padding()
                .background(.thinMaterial)
            }
            .navigationTitle("Review Delete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                // 【初始化】默认全选 (全部待删除)
                let allIDs = viewModel.assetsToDelete.map { $0.id }
                selectedIDs = Set(allIDs)
            }
            .alert("Confirm Deletion", isPresented: $showConfirmationAlert) {
                Button("Delete", role: .destructive) {
                    handleFinalAction()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure? Unselected photos will be kept.")
            }
        }
    }
    
    // MARK: - Logic
    
    private var buttonTitle: String {
        if selectedIDs.isEmpty {
            return "Restore All"
        } else {
            return "Delete \(selectedIDs.count) Photos"
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
    
    // 【核心修复】统一处理逻辑
    private func handleFinalAction() {
        // 1. 区分出哪些要删除，哪些要恢复
        // selectedIDs = 用户确认要删的
        // unselected = 用户没勾选，意味着要恢复的
        
        // 场景 A: 一个都没选 -> 全部恢复 (Restore All)
        if selectedIDs.isEmpty {
            // 调用 VM 的新方法，确保统计数据归零
            viewModel.restoreAll()
            dismiss()
            return
        }
        
        // 场景 B: 部分删除，部分恢复
        // 1. 先找出所有未选中的照片 (要恢复的)
        let assetsToRestore = viewModel.assetsToDelete.filter { !selectedIDs.contains($0.id) }
        
        // 2. 逐个恢复它们 (这一步会更新 TrashManager 统计，并从 assetsToDelete 移除)
        for asset in assetsToRestore {
            viewModel.restoreFromTrash(asset: asset)
        }
        
        // 3. 此时 viewModel.assetsToDelete 里剩下的全是 selectedIDs (要删的)
        // 直接执行确认删除
        viewModel.confirmDeletion { success in
            if success {
                dismiss()
            }
        }
    }
    
    var emptyTrashView: some View {
        VStack(spacing: 15) {
            Image(systemName: "trash.slash")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No photos pending delete")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Components

struct TrashThumbnail: View {
    let asset: PhotoAsset
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
            } else {
                Color.gray.opacity(0.2)
                    .onAppear {
                        let manager = PHImageManager.default()
                        let options = PHImageRequestOptions()
                        options.isSynchronous = false
                        options.deliveryMode = .opportunistic
                        options.isNetworkAccessAllowed = true
                        
                        manager.requestImage(for: asset.asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { img, _ in
                            self.image = img
                        }
                    }
            }
        }
    }
}
