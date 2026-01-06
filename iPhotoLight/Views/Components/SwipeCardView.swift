import SwiftUI
internal import Photos

struct SwipeCardView: View {
    let asset: PhotoAsset
    let onRemove: (SwipeAction) -> Void
    
    // 手势状态
    @State private var offset: CGSize = .zero
    @State private var image: UIImage? = nil
    
    // 物理阈值
    private let throwThreshold: CGFloat = 100.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 卡片容器 (模拟物理厚度)
                ZStack {
                    // 图片层
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        // Loading / Empty 状态：磨砂玻璃质感
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                            )
                            .onAppear {
                                loadAssetImage(size: geometry.size)
                            }
                    }
                }
                // 裁切圆角 (连续曲率，更像 Apple 原生硬件)
                .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                // 2. 玻璃光泽边框 (Inner Light)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6), // 左上角亮光
                                .white.opacity(0.1),
                                .white.opacity(0.05),
                                .white.opacity(0.3)  // 右下角微光
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                
                // 3. 意图覆盖层 (Overlay)
                overlayView
            }
            // 4. 深度投影 (让卡片浮起来)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2) // 环境光
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10) // 主阴影
            
            // 手势绑定
            .offset(x: offset.width, y: offset.height)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .scaleEffect(calculateScale())
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        self.offset = gesture.translation
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
        }
    }
    
    // 意图指示器 (保持逻辑不变，微调视觉)
    var overlayView: some View {
        ZStack {
            // 覆盖层蒙版 (让文字更清晰)
            if offset.height < -50 || offset.width < -50 {
                Rectangle()
                    .fill(.black.opacity(0.2))
                    .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            // 删除 (Up) - 红色垃圾桶
            if offset.height < -50 {
                VStack {
                    Spacer()
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 80))
                        .symbolRenderingMode(.hierarchical) // 层次感图标
                        .foregroundColor(.red)
                        .background(Circle().fill(.white).padding(4)) // 增加白色衬底
                        .shadow(radius: 10)
                        .padding(.bottom, 60)
                }
                .transition(.opacity)
            }
            
            // 保留 (Left) - 绿色对勾
            if offset.width < -50 {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.green)
                        .background(Circle().fill(.white).padding(4))
                        .shadow(radius: 10)
                        .padding(.trailing, 40)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: offset)
    }
    
    // ... 逻辑代码保持不变 ...
    
    private func loadAssetImage(size: CGSize) {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        PhotoLibraryManager.shared.requestImage(for: asset.asset, targetSize: targetSize) { loadedImage in
            withAnimation(.easeIn(duration: 0.2)) {
                self.image = loadedImage
            }
        }
    }
    
    private func calculateScale() -> CGFloat {
        let maxDistance = 300.0
        let distance = sqrt(pow(offset.width, 2) + pow(offset.height, 2))
        return 1.0 - min(distance / maxDistance * 0.05, 0.05)
    }
    
    private func handleDragEnd() {
        let verticalMove = offset.height
        let horizontalMove = offset.width
        
        if verticalMove < -throwThreshold && abs(verticalMove) > abs(horizontalMove) {
            withAnimation(.easeOut(duration: 0.3)) { offset.height = -1000 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onRemove(.delete) }
        }
        else if horizontalMove < -throwThreshold && abs(horizontalMove) > abs(verticalMove) {
            withAnimation(.easeOut(duration: 0.3)) { offset.width = -1000 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onRemove(.keep) }
        }
        else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { offset = .zero }
        }
    }
}
