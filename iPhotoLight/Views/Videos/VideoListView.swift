import SwiftUI
import AVKit
internal import Photos
import PhotosUI

struct VideoListView: View {
    @StateObject private var viewModel = VideoListViewModel()
    @State private var dragOffset: CGSize = .zero
    @State private var showTrash = false
    @State private var showSettings = false
    @State private var selectedVideoForDetail: PhotoAsset? = nil
    
    var body: some View {
        ZStack {
            // 1. 背景层 (禁止点击)
            LiquidBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(0)
            
            // 2. 内容层
            if viewModel.permissionStatus == .denied || viewModel.permissionStatus == .restricted {
                PermissionBlockingView().zIndex(10)
            } else {
                VStack(spacing: 0) {
                    // 头部区域 (包含标题和控制栏)
                    headerContent
                        .zIndex(10) // 确保按钮在最上层
                    
                    // 卡片区域 (自动填充剩余空间)
                    ZStack {
                        if viewModel.videos.isEmpty {
                            emptyStateView
                        } else {
                            cardStackView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 强制撑满剩余空间，还原卡片大小
                    .zIndex(1)
                    
                    Spacer().frame(height: 50) // 底部留白
                }
                .padding(.top, 10)
                .blur(radius: selectedVideoForDetail != nil ? 20 : 0)
            }
            
            // 全屏播放器
            if let video = selectedVideoForDetail {
                VideoDetailOverlay(asset: video) {
                    withAnimation { selectedVideoForDetail = nil }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onAppear { viewModel.checkPermissionAndLoad() }
        .sheet(isPresented: $showTrash) { VideoTrashReviewView(viewModel: viewModel) }
        .sheet(isPresented: $showSettings, onDismiss: { viewModel.loadVideos() }) { SettingsView() }
    }
    
    // MARK: - Header Content
    private var headerContent: some View {
        VStack(spacing: 4) {
            // 1. 标题
            // [修改后]
            Text("Videos")
                .font(.custom("BradleyHandITCTT-Bold", size: 42))
                .foregroundColor(.primary) // 【关键修改】自动适应黑/白
                .frame(maxWidth: .infinity)
            
            // 2. 控制栏：设置 - (Add Videos) - 垃圾桶
            // 放在同一行，高度持平
            HStack {
                // 左侧：设置
                Button(action: { showSettings = true }) {
                    NativeStyleIconButton(iconName: "gearshape.fill")
                }
                
                Spacer()
                
                // 中间：添加按钮 (仅在 Limited 权限下显示)
                if viewModel.permissionStatus == .limited {
                    Button(action: {
                        PhotoLibraryManager.shared.presentLimitedLibraryPicker()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Videos")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .contentShape(Rectangle()) // 增加点击区域
                }
                
                Spacer()
                
                // 右侧：垃圾桶
                Button(action: { showTrash = true }) {
                    ZStack {
                        NativeStyleIconButton(iconName: "trash.fill")
                        if !viewModel.assetsToDelete.isEmpty {
                            Text("\(viewModel.assetsToDelete.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 12, y: -12)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Components
    @ViewBuilder
    func NativeStyleIconButton(iconName: String) -> some View {
        ZStack {
            // 背景：材质会自动适应深色模式（变成深灰色半透明）
            Circle()
                .fill(.thickMaterial)
            
            // 图标：颜色改为 primary
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary) // 【关键修改】浅色模式黑，深色模式白
                .opacity(0.8) // 稍微加一点透明度更有质感，也可以去掉
        }
        .frame(width: 44, height: 44)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(Circle())
    }
    
    private var cardStackView: some View {
        let visibleVideos = viewModel.videos.prefix(2).reversed()
        return ZStack {
            ForEach(Array(visibleVideos), id: \.id) { video in
                let index = viewModel.videos.firstIndex(where: { $0.id == video.id }) ?? 0
                let isTop = index == 0
                SwipeVideoView(asset: video, isTopCard: isTop, onTapForDetail: { withAnimation { selectedVideoForDetail = video } })
                    .padding()
                    .offset(x: isTop ? dragOffset.width : 0, y: isTop ? dragOffset.height : 0)
                    .rotationEffect(.degrees(isTop ? Double(dragOffset.width / 20) : 0))
                    .scaleEffect(isTop ? 1 : 0.95)
                    .opacity(isTop ? 1 : 0.5)
                    .gesture(isTop ? DragGesture().onChanged { v in self.dragOffset = v.translation }.onEnded { v in handleSwipe(translation: v.translation, index: index) } : nil)
                    .zIndex(Double(-index))
            }
        }
    }
    
    private func handleSwipe(translation: CGSize, index: Int) {
        let threshold: CGFloat = 100
        if translation.height < -threshold { moveCardAway(to: .up, index: index) }
        else if translation.width < -threshold { moveCardAway(to: .left, index: index) }
        else if translation.width > threshold { moveCardAway(to: .right, index: index) }
        else { withAnimation(.spring()) { dragOffset = .zero } }
    }
    
    private enum SwipeDirection { case left, right, up }
    private func moveCardAway(to direction: SwipeDirection, index: Int) {
        let w = UIScreen.main.bounds.width; let h = UIScreen.main.bounds.height
        var target: CGSize = .zero
        switch direction {
        case .left: target = CGSize(width: -w, height: 0)
        case .right: target = CGSize(width: w, height: 0)
        case .up: target = CGSize(width: 0, height: -h)
        }
        withAnimation(.easeIn(duration: 0.3)) { dragOffset = target }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if direction == .up { viewModel.deleteVideo(at: index) } else { viewModel.keepVideo(at: index) }
            dragOffset = .zero
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Color.green.opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundColor(.green).shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 10)
            VStack(spacing: 8) {
                Text("All Caught Up!").font(.custom("BradleyHandITCTT-Bold", size: 32)).foregroundColor(.primary)
                Text("当前这组视频已整理完成").font(.body).foregroundColor(.secondary)
            }
            Button(action: { withAnimation { viewModel.loadVideos() } }) {
                HStack(spacing: 10) { Text("开始整理下一组").font(.headline).fontWeight(.semibold); Image(systemName: "arrow.right.circle.fill").font(.title3) }
                .foregroundColor(.white).padding(.vertical, 16).padding(.horizontal, 32).background(LinearGradient(colors: [.black, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)).cornerRadius(30).shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 20)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// 记得保留 VideoDetailOverlay 和 VideoPlayerWrapper
// MARK: - Helper Components

struct VideoDetailOverlay: View {
    let asset: PhotoAsset
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VideoPlayerWrapper(asset: asset.asset)
                .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            .padding(.top, 50)
        }
    }
}

struct VideoPlayerWrapper: UIViewControllerRepresentable {
    let asset: PHAsset
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
            guard let item = item else { return }
            DispatchQueue.main.async {
                let player = AVPlayer(playerItem: item)
                controller.player = player
                player.play()
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
