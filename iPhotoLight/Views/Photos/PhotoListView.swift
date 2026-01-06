import SwiftUI
internal import Photos
import PhotosUI

struct PhotoListView: View {
    @StateObject private var viewModel = PhotoListViewModel()
    
    // 控制设置页面的显示
    @State private var showSettingsSheet = false
    
    // 【新增】控制详情预览
    @State private var selectedPhotoForDetail: PhotoAsset? = nil
    
    // 配置导航栏外观
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. 背景层
                LiquidBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(0)
                
                // 2. 内容层
                if viewModel.permissionStatus == .denied || viewModel.permissionStatus == .restricted {
                    PermissionBlockingView()
                        .zIndex(10)
                } else {
                    VStack(spacing: 0) {
                        // 头部和控制栏
                        headerContent
                            .zIndex(10)
                        
                        // 卡片堆叠区
                        cardStackArea
                            .zIndex(1)
                        
                        Spacer().frame(height: 20)
                    }
                    // 高斯模糊背景 (当预览打开时)
                    .blur(radius: selectedPhotoForDetail != nil ? 20 : 0)
                }
                
                // 3. 【新增】全屏预览层
                if let photo = selectedPhotoForDetail {
                    PhotoDetailOverlay(asset: photo) {
                        withAnimation {
                            selectedPhotoForDetail = nil
                        }
                    }
                    .transition(.opacity) // 淡入淡出
                    .zIndex(100)
                }
            }
            .navigationViewStyle(.stack)
            .sheet(isPresented: $showSettingsSheet, onDismiss: {
                viewModel.loadAssets()
            }) {
                SettingsView()
            }
            .sheet(isPresented: $viewModel.showTrashReview) {
                TrashReviewView(viewModel: viewModel)
            }
        }
        .onAppear {
            // 【修复问题2】每次页面显示（包括从设置页回来，或者从后台回来）都尝试加载
            // 只有当权限已获取时才加载，避免未授权时无效调用
            if viewModel.permissionStatus == .authorized || viewModel.permissionStatus == .limited {
                viewModel.loadAssets()
            }
        }
    }
    
    // MARK: - Subviews extraction
    
    var headerContent: some View {
        VStack(spacing: 0) {
            // 标题区域
            VStack(spacing: 4) {
                // [修改后] 添加 .localized
                Text("Photos".localized)
                    .font(.custom("BradleyHandITCTT-Bold", size: 42))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                if viewModel.permissionStatus == .limited {
                    Button(action: {
                        PhotoLibraryManager.shared.presentLimitedLibraryPicker()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Photos")
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
                    .padding(.bottom, 6)
                    .contentShape(Rectangle())
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 5)
            .zIndex(101)
            
            // 控制栏
            HStack(spacing: 12) {
                Button { showSettingsSheet = true } label: {
                    NativeStyleIconButton(iconName: "gearshape.fill")
                }
                
                GlassCategoryPicker(selection: $viewModel.currentCategory)
                    .layoutPriority(1)
                
                Button { viewModel.showTrashReview = true } label: {
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
            .zIndex(100)
        }
    }
    
    var cardStackArea: some View {
        GeometryReader { geo in
            ZStack {
                if viewModel.displayedAssets.isEmpty {
                    emptyStateView
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ForEach(Array(viewModel.displayedAssets.prefix(3).enumerated().reversed()), id: \.element.id) { index, asset in
                        SwipeCardView(asset: asset) { action in
                            viewModel.handleSwipe(asset: asset, action: action)
                        }
                        .frame(width: geo.size.width - 32, height: geo.size.height - 20)
                        .scaleEffect(index == 0 ? 1.0 : 0.95)
                        .rotationEffect(.degrees(index == 0 ? 0 : (index % 2 == 0 ? 2 : -2)))
                        .offset(y: index == 0 ? 0 : 15)
                        .opacity(index == 0 ? 1.0 : 0.7)
                        .allowsHitTesting(index == 0)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        // 【新增】点击卡片进入详情预览
                        .onTapGesture {
                            if index == 0 { // 只有最上面的卡片能点
                                withAnimation {
                                    selectedPhotoForDetail = asset
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    func NativeStyleIconButton(iconName: String) -> some View {
        ZStack {
            Circle()
                .fill(.thickMaterial)
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .opacity(0.8)
        }
        .frame(width: 44, height: 44)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(Circle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Color.green.opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 10)
            VStack(spacing: 8) {
                Text("All Caught Up!")
                    .font(.custom("BradleyHandITCTT-Bold", size: 32))
                    .foregroundColor(.primary)
                Text("当前这组照片已整理完成").font(.body).foregroundColor(.secondary)
            }
            Button(action: { withAnimation { viewModel.loadAssets() } }) {
                HStack(spacing: 10) {
                    Text("开始整理下一组").font(.headline).fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill").font(.title3)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(LinearGradient(colors: [.black, .gray], startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 20)
            Spacer(); Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
