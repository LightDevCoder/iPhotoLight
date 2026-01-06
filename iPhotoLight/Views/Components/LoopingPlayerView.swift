// Path: Views/Components/LoopingPlayerView.swift

import SwiftUI
import AVKit
internal import Photos

struct LoopingPlayerView: UIViewControllerRepresentable {
    let asset: PHAsset
    var shouldPlay: Bool
    @Binding var isMuted: Bool // [新增] 绑定静音状态
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        
        // 初始配置
        setupPlayer(for: controller)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        guard let player = uiViewController.player else { return }
        
        // 1. 处理播放状态
        if shouldPlay {
            // 只有当 player 未播放时才调用 play，避免重复调用
            if player.timeControlStatus != .playing {
                player.play()
            }
        } else {
            player.pause()
        }
        
        // 2. [新增] 处理静音状态
        if player.isMuted != isMuted {
            player.isMuted = isMuted
        }
    }
    
    private func setupPlayer(for controller: AVPlayerViewController) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat // 预览不需要最高最高质量，平衡性能
        
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
            DispatchQueue.main.async {
                guard let item = item else { return }
                
                let player = AVPlayer(playerItem: item)
                player.isMuted = self.isMuted // 初始静音状态
                player.actionAtItemEnd = .none
                
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main) { _ in
                        player.seek(to: .zero)
                        player.play()
                    }
                
                controller.player = player
                if self.shouldPlay {
                    player.play()
                }
            }
        }
    }
}
