//
//  VideoTrashReviewView.swift
//  iPhotoLight
//
//  Path: Views/Videos/VideoTrashReviewView.swift
//

import SwiftUI
internal import Photos

struct VideoTrashReviewView: View {
    @ObservedObject var viewModel: VideoListViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // 【状态】记录哪些视频是“被选中要删除”的（默认全选）
    // 逻辑：Selected (红圈) = 确认删除; Unselected (无圈) = 确认保留/恢复
    @State private var selectedIDs: Set<String> = []
    
    // 二次确认弹窗
    @State private var showConfirmationAlert = false
    
    // 布局：自适应网格
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
                                        // 【视觉反馈】未选中（即保留）时增加遮罩
                                        .opacity(selectedIDs.contains(asset.id) ? 1.0 : 0.5)
                                    
                                    // B. 视频标识 (Play Icon)
                                    Image(systemName: "play.fill")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(6)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                        .position(x: 20, y: 20)
                                        .padding(4)
                                    
                                    // C. 选中状态指示器 (右上角)
                                    SelectionIndicator(isSelected: selectedIDs.contains(asset.id))
                                        .padding(6)
                                }
                                .aspectRatio(1, contentMode: .fit) // 强制正方形
                                .contentShape(Rectangle()) // 确保点击区域填满整个正方形
                                .onTapGesture {
                                    toggleSelection(for: asset)
                                }
                            }
                        }
                    }
                }
                
                // 2. 底部操作栏
                VStack(spacing: 12) {
                    Text(selectedIDs.isEmpty ? "Tap button below to restore all" : "Unselected videos will be restored")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if selectedIDs.isEmpty {
                            // 如果一个都没选，直接执行“全部恢复”
                            handleFinalAction()
                        } else {
                            // 如果有选中的，弹出删除确认
                            showConfirmationAlert = true
                        }
                    }) {
                        // 【修复】按钮逻辑：根据选中数量动态显示文本，且不再禁用
                        Text(buttonTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            // 样式区分：如果有删除项显示红色，全是恢复项显示蓝色或灰色
                            .background(selectedIDs.isEmpty ? Color.blue : Color.red)
                            .cornerRadius(12)
                    }
                    // 【关键修复】永远不禁用按钮，保证用户可以操作“全部恢复”
                    .disabled(false)
                }
                .padding()
                .background(.thinMaterial)
            }
            .navigationTitle("Review Delete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
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
                Text("Selected videos will be deleted. Unselected ones will be restored to your library.")
            }
        }
    }
    
    // MARK: - Logic
    
    private var buttonTitle: String {
        if selectedIDs.isEmpty {
            return "Restore All"
        } else {
            return "Delete \(selectedIDs.count) Videos"
        }
    }
    
    private func toggleSelection(for asset: PhotoAsset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedIDs.contains(asset.id) {
                selectedIDs.remove(asset.id) // 移除勾选 = 变为恢复状态
            } else {
                selectedIDs.insert(asset.id) // 增加勾选 = 变为删除状态
            }
        }
    }
    
    // 【核心修复】统一处理逻辑：删除选中的，恢复未选中的
    private func handleFinalAction() {
        // 1. 区分“要删的”和“要留的”
        let assetsToDelete = viewModel.assetsToDelete.filter { selectedIDs.contains($0.id) }
        let assetsToRestore = viewModel.assetsToDelete.filter { !selectedIDs.contains($0.id) }
        
        // 2. 处理恢复：将未选中的视频移出废纸篓，加回主列表
        for asset in assetsToRestore {
            viewModel.restoreFromTrash(asset)
        }
        
        // 3. 处理删除：执行物理删除
        if assetsToDelete.isEmpty {
            // 如果没有要删的（全是恢复），直接关闭即可
            presentationMode.wrappedValue.dismiss()
        } else {
            // 此时 viewModel.assetsToDelete 应该只剩下要删除的了
            // 为了安全，我们手动更新一下 VM 的列表为“仅包含要删除的项”
            // 这样 confirmDeletion 内部逻辑就不会误删刚刚恢复的项
            viewModel.assetsToDelete = assetsToDelete
            
            viewModel.confirmDeletion { success in
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    var emptyTrashView: some View {
        VStack(spacing: 15) {
            Image(systemName: "trash.slash")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("Trash is Empty")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Components

// 专用于视频废纸篓的缩略图组件
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
