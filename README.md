# iPhotoLight 📸✨

![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.0-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-LifeCycle-success) ![PhotoKit](https://img.shields.io/badge/Framework-PhotoKit-purple)

**iPhotoLight** 是一款基于 SwiftUI 和 PhotoKit 构建的现代化相册整理工具。它采用了类似 Tinder 的“左滑保留、上滑删除”交互模式，结合智能记忆系统与原生级预览体验，帮助用户在沉浸式的氛围中高效清理冗余照片与视频，释放手机存储空间。

> **Update Log (2026-01-06):**
> * 🌍 **Localization Fix:** 修复了 `PermissionBlockingView` (无权限引导页) 的双语支持，现已完美适配中/英切换。
> * 🔧 **Refactor:** 优化了权限视图代码，全面采用 `.localized` 扩展进行字符串绑定。
> * 🚀 **V1.0 Gold Ready:** 完成了所有核心功能的开发与真机测试，项目结构已固化。

## ✨ 核心功能 (Features)

* **👆 极简手势交互 (Gesture-Based Cleaning)**
    * **Tinder 式操作**：左滑 (Keep) 保留美好回忆，上滑 (Delete) 移入垃圾桶。
    * **批量加载**：支持自定义 Batch Size (如每次 50 张)，避免内存溢出，保证丝滑流畅。
    * **智能过滤**：内置 `ReviewHistoryManager`，自动跳过已整理过的照片，防止重复劳动。

* **🎞️ 原生级预览体验 (Native Preview)**
    * **Live Photo 支持**：完美复刻系统相册体验，支持**长按播放**动态画面，左上角提供静音开关。
    * **双指缩放**：在全屏预览模式下，支持双指捏合 (Pinch) 查看照片细节。
    * **自动播放**：视频卡片支持静音循环预览，快速判断内容价值。

* **🛡️ 安全删除机制 (Safe Deletion)**
    * **废纸篓回顾**：删除操作不立即执行，而是进入临时暂存区。
    * **反选恢复**：在垃圾桶页面，未勾选的照片会自动恢复 (Restore)，且**实时回滚统计数据**。
    * **权限友好**：完美适配 iOS 14+ 的 **Limited Access**，提供 "Add Photos" 按钮手动补充整理范围。

* **🎨 沉浸式视觉 (Immersive Visuals)**
    * **流体背景**：全屏动态 `LiquidBackground`，随操作流转。
    * **手写风格**：标题统一使用 **Bradley Hand** 字体，营造轻松的整理氛围。
    * **深色模式**：全线 UI 适配 iOS 深色模式，使用语义化色彩 (`.primary`) 和毛玻璃材质。

## 📂 项目结构 (Project Structure)

```text
iPhotoLight
├── App
│   └── iPhotoLightApp.swift           # [入口] App 生命周期入口，配置 WindowGroup 和根视图
│
├── Managers                           # [核心逻辑] 单例管理器，负责底层业务
│   ├── PhotoLibraryManager.swift      # PhotoKit 封装：负责权限请求、拉取资源、执行物理删除
│   ├── ReviewHistoryManager.swift     # 记忆系统：记录用户左滑“保留”的资源 ID，防止重复出现
│   └── TrashManager.swift             # 统计系统：计算清理的字节数 (Bytes)，管理统计数据
│
├── Models                             # [数据模型]
│   ├── PhotoAsset.swift               # 封装 PHAsset：提供 Identifiable 协议支持，便于 SwiftUI 遍历
│   ├── PhotoCategory.swift            # 枚举：定义筛选分类 (All, Favorites, Screenshots, Live)
│   └── TrashItem.swift                # (新) 垃圾桶数据模型：用于在 Review 页面封装待删除项
│
├── ViewModels                         # [业务逻辑] MVVM 的 VM 层
│   ├── PhotoListViewModel.swift       # 照片页逻辑：处理加载、过滤历史、手势操作、恢复逻辑
│   ├── StatsViewModel.swift           # 统计页逻辑：计算总清理空间、处理重置历史操作
│   └── VideoListViewModel.swift       # 视频页逻辑：处理视频加载、播放状态管理、删除逻辑
│
├── Views                              # [UI 层]
│   ├── Components                     # [通用组件库] 可复用的 UI 模块
│   │   ├── GlassCategoryPicker.swift  # 分类选择器：毛玻璃风格的 Segment Control
│   │   ├── LiquidBackground.swift     # 全局背景：流体动态渐变背景 (allowsHitTesting: false)
│   │   ├── LoopingPlayerView.swift    # 视频播放器：用于视频卡片中的自动循环播放组件
│   │   ├── PermissionBlockingView.swift # 权限阻断页：当权限为 Denied 时显示的引导页
│   │   ├── PhotoDetailOverlay.swift   # 全屏预览：支持双指缩放、Live Photo 长按播放
│   │   ├── SelectionIndicator.swift   # 选择指示器：垃圾桶页面中用于勾选的小圆圈
│   │   ├── SettingsView.swift         # 设置页：修改 Batch Size 及重置历史的入口
│   │   └── SwipeCardView.swift        # 照片卡片：处理照片的渲染和 Tinder 式手势动画
│   │
│   ├── Photos                         # [照片模块]
│   │   ├── PhotoListView.swift        # 照片主页：整合 Header、卡片堆叠、空状态和 Add 按钮
│   │   └── TrashReviewView.swift      # 照片垃圾桶：网格展示待删照片，处理 Restore/Delete 逻辑
│   │
│   ├── Stats                          # [统计模块]
│   │   └── StatsView.swift            # 统计主页：展示仪表盘、清理数据汇总及重置入口
│   │
│   ├── Videos                         # [视频模块]
│   │   ├── SwipeVideoView.swift       # 视频卡片：继承通用卡片逻辑，但内嵌 LoopingPlayerView
│   │   ├── VideoListView.swift        # 视频主页：布局类似照片页，但针对视频优化
│   │   └── VideoTrashReviewView.swift # 视频垃圾桶：处理视频的最终删除确认
│   │
│   └── MainTabView.swift              # [根视图] 底部 Tab 导航，管理 Stats/Photos/Videos 三大页面切换
│
└── Assets.xcassets                    # 资源文件：存放 AppIcon, 颜色集 (如 BackgroundBase), 图片素材
```
## 🛠 技术栈 (Tech Stack)
语言: Swift 5.0+

UI 框架: SwiftUI (主要), UIKit (用于 ZoomableScrollView, PHLivePhotoView)

核心框架: PhotoKit, PhotosUI, AVKit, Combine

架构模式: MVVM (Model-View-ViewModel)

数据存储: UserDefaults (用于历史记录), Photo Library (系统相册)

## 🚀 快速开始 (Getting Started)
环境要求: Xcode 14.0+, iOS 16.0+

克隆项目: git clone https://github.com/your-username/iPhotoLight.git

运行: 连接真机，Cmd + R 运行。首次启动请允许相册访问权限。

## 📄 License
MIT License