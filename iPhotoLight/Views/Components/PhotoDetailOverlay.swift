import SwiftUI
internal import Photos
import PhotosUI // 必须引入

struct PhotoDetailOverlay: View {
    let asset: PhotoAsset
    let onDismiss: () -> Void
    
    // 状态
    @State private var image: UIImage? = nil
    @State private var livePhoto: PHLivePhoto? = nil
    @State private var isMuted: Bool = false // 静音状态
    @State private var isLivePhoto: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 1. 黑色背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 2. 内容区域 (图片 或 Live Photo)
            GeometryReader { geo in
                ZStack {
                    if isLivePhoto, let livePhoto = livePhoto {
                        // --- Live Photo 模式 ---
                        LivePhotoViewWrapper(livePhoto: livePhoto, isMuted: isMuted)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .onTapGesture {
                                onDismiss()
                            }
                    } else if let image = image {
                        // --- 普通图片模式 ---
                        ZoomableScrollView {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .onTapGesture {
                            onDismiss()
                        }
                    } else {
                        // --- 加载中 ---
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
            
            // 3. 顶部控制栏
            HStack(spacing: 12) {
                // 左侧：如果是 Live Photo，显示原生样式徽章和静音按钮
                if isLivePhoto {
                    HStack(spacing: 8) {
                        // A. 原生样式的 LIVE 徽章
                        HStack(spacing: 4) {
                            Image(systemName: "livephoto") // 原生图标
                                .font(.system(size: 14))
                            Text("LIVE")
                                .font(.system(size: 12, weight: .semibold))
                                .offset(y: 0.5) // 微调文字垂直对齐
                        }
                        .foregroundColor(.primary) // 自动适应模式
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.thickMaterial) // 漂亮的毛玻璃
                        .clipShape(Capsule())
                        
                        // B. 静音按钮 (圆形)
                        Button(action: {
                            isMuted.toggle()
                        }) {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32) // 固定大小
                                .background(.thickMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.leading, 20)
                }
                
                Spacer()
                
                // 右侧：关闭按钮
                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold)) //稍微调小一点，更精致
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.6)) // 半透明黑底，对比度更高
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 50) // 避开刘海
        }
        .onAppear {
            checkAndLoadAsset()
        }
    }
    
    // MARK: - Loading Logic
    private func checkAndLoadAsset() {
        if asset.asset.mediaSubtypes.contains(.photoLive) {
            self.isLivePhoto = true
            loadLivePhoto()
        } else {
            self.isLivePhoto = false
            loadImage()
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { img, _ in
            if let img = img {
                withAnimation { self.image = img }
            }
        }
    }
    
    private func loadLivePhoto() {
        let manager = PHImageManager.default()
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestLivePhoto(for: asset.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { livePhoto, _ in
            if let livePhoto = livePhoto {
                withAnimation { self.livePhoto = livePhoto }
            }
        }
    }
}

// MARK: - Live Photo Wrapper
struct LivePhotoViewWrapper: UIViewRepresentable {
    let livePhoto: PHLivePhoto
    let isMuted: Bool
    
    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        return view
    }
    
    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
        uiView.isMuted = isMuted
    }
}

// MARK: - Zoomable ScrollView Helper
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        context.coordinator.hostingController = hostingController
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        var hostingController: UIHostingController<Content>!
        
        init(_ parent: ZoomableScrollView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}
