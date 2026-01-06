# iPhotoLight 📸

![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-LifeCycle-success) ![PhotoKit](https://img.shields.io/badge/Framework-PhotoKit-purple)

**iPhotoLight** 是一款基于 SwiftUI 和 PhotoKit 构建的现代化相册整理工具。它采用了类似 Tinder 的“左滑保留、上滑删除”交互模式，结合智能记忆系统、原生级预览体验以及 **V1.1 全新的多语言支持**，帮助用户在沉浸式的氛围中高效清理冗余照片与视频，释放手机存储空间。

---

## ✨ 核心功能 (Features)

* **🌍 多语言支持 (Global Localization) [New]**
    * **即时切换**：内置 `LocalizationManager`，支持在 App 内一键切换 **English / 中文**，无需重启应用。
    * **全面覆盖**：从 Tab 标签、页面标题到删除确认弹窗，所有文案均实现动态化适配。

* **👆 极简手势交互 (Gesture-Based Cleaning)**
    * **Tinder 式操作**：左滑 (Keep) 保留美好回忆，上滑 (Delete) 移入垃圾桶。
    * **批量加载**：支持自定义 Batch Size (如每次 50 张)，避免内存溢出，保证丝滑流畅。
    * **智能过滤**：内置 `ReviewHistoryManager`，自动跳过已整理过的照片，防止重复劳动。

* **👁️ 原生级预览体验 (Native Preview)**
    * **Live Photo 支持**：完美复刻系统相册体验，支持**长按播放**动态画面，左上角提供静音开关。
    * **双指缩放**：在全屏预览模式下，支持双指捏合 (Pinch) 查看照片细节。
    * **自动播放**：视频卡片支持静音循环预览，快速判断内容价值。

* **🛡️ 安全删除机制 (Safe Deletion)**
    * **废纸篓回顾**：删除操作不立即执行，而是进入临时暂存区。
    * **反选恢复**：在垃圾桶页面，未勾选的照片会自动恢复 (Restore)，且**实时回滚统计数据**。
    * **动态提示**：删除按钮根据选中数量动态显示文案 (如 "Delete 5 Photos")。
    * **权限友好**：完美适配 iOS 14+ 的 **Limited Access**，提供 "Add Photos" 按钮手动补充整理范围。

* **🎨 沉浸式视觉 (Immersive Visuals)**
    * **流体背景**：全屏动态 `LiquidBackground`，随操作流转。
    * **手写风格**：标题统一使用 **BradleyHandITCTT-Bold** 字体，营造轻松的整理氛围。
    * **深色模式**：全线 UI 适配 iOS 深色模式，使用语义化色彩 (`.primary`) 和毛玻璃材质。

---

## 📂 项目结构 (Project Structure)

```text
iPhotoLight
├── App
│   └── iPhotoLightApp.swift           # [入口] App 生命周期，注入 LocalizationManager 环境对象
│
├── Managers                           # [核心逻辑] 单例管理器
│   ├── LocalizationManager.swift      # [新增] 多语言管理器：负责中英切换、字典管理与状态发布
│   ├── PhotoLibraryManager.swift      # PhotoKit 封装：权限请求、Fetch Assets、执行物理删除
│   ├── ReviewHistoryManager.swift     # 记忆系统：记录用户左滑“保留”的资源 ID
│   └── TrashManager.swift             # 统计系统：计算清理的字节数 (Bytes)
│
├── Models                             # [数据模型]
│   ├── PhotoAsset.swift               # 封装 PHAsset：提供 Identifiable 协议支持
│   ├── PhotoCategory.swift            # 枚举：定义筛选分类 (All, Favorites, Screenshots, Live)
│   └── TrashItem.swift                # 垃圾桶数据模型
│
├── ViewModels                         # [业务逻辑] MVVM 的 VM 层
│   ├── PhotoListViewModel.swift       # 照片页逻辑：加载、过滤历史、手势操作
│   ├── StatsViewModel.swift           # 统计页逻辑：动态计算清理占比，响应语言切换刷新数据
│   └── VideoListViewModel.swift       # 视频页逻辑：视频加载、播放管理、删除确认
│
├── Views                              # [UI 层]
│   ├── Components                     # [通用组件库]
│   │   ├── GlassCategoryPicker.swift  # 毛玻璃分类选择器
│   │   ├── LiquidBackground.swift     # 全局流体动态背景
│   │   ├── LoopingPlayerView.swift    # 视频卡片内嵌播放器
│   │   ├── PermissionBlockingView.swift # 权限阻断引导页
│   │   ├── PhotoDetailOverlay.swift   # 全屏预览 (Zoom, Live Photo)
│   │   ├── SelectionIndicator.swift   # 勾选指示器
│   │   ├── SettingsView.swift         # [更新] 设置页：Batch Size、重置统计、文案国际化
│   │   └── SwipeCardView.swift        # 通用手势卡片
│   │
│   ├── Photos                         # [照片模块]
│   │   ├── PhotoListView.swift        # 照片主页：Header 字体已统一
│   │   └── TrashReviewView.swift      # 照片垃圾桶：支持反选恢复，动态按钮标题
│   │
│   ├── Stats                          # [统计模块]
│   │   └── StatsView.swift            # [更新] 统计主页：新增语言切换按钮 (Switch Language)
│   │
│   ├── Videos                         # [视频模块]
│   │   ├── SwipeVideoView.swift       # 视频卡片容器
│   │   ├── VideoListView.swift        # 视频主页
│   │   └── VideoTrashReviewView.swift # 视频垃圾桶
│   │
│   └── MainTabView.swift              # [根视图] 底部 Tab 导航，管理 Stats/Photos/Videos 三大页面切换
│
└── Assets.xcassets                    # 资源文件：存放 AppIcon, 颜色集, 图片素材
```

## 🛠 技术栈 (Tech Stack)
语言: Swift 5.0+

UI 框架: SwiftUI (主要), UIKit (用于 ZoomableScrollView, PHLivePhotoView)

核心框架: PhotoKit, PhotosUI, AVKit, Combine

架构模式: MVVM (Model-View-ViewModel)

数据存储: UserDefaults (用于历史记录), Photo Library (系统相册)

## 🚀 快速开始 (Getting Started)
1. 环境要求
Xcode 14.0+

iOS 16.0+ (PhotoKit 现代 API)

2. 权限配置 (Permissions)
本项目严格遵守 iOS 隐私规范，Info.plist 已配置：

NSPhotoLibraryUsageDescription: 必须配置，用于申请读写权限。

PHPhotoLibraryPreventAutomaticLimitedAccessAlert: 设置为 YES，禁用系统自带的 Limited 弹窗，使用 App 内置的 Add 按钮接管交互。

3. 安装运行
克隆仓库：

Bash

git clone [https://github.com/your-username/iPhotoLight.git](https://github.com/your-username/iPhotoLight.git)
打开 iPhotoLight.xcodeproj。

配置签名 (Signing & Capabilities) 为你的开发团队。

连接真机，点击 Run (Cmd + R)。

推荐使用真机调试以获得最佳的 Haptics 震动反馈体验。

## 🤝 贡献 (Contribution)
欢迎提交 Issue 和 PR！特别是针对以下方向的优化：

iCloud 同步状态检测与优化。

针对相似照片的 AI 识别算法。

📄 License
MIT License