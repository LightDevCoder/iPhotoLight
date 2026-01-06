// Path: Views/Videos/SwipeVideoView.swift

import SwiftUI
internal import Photos

struct SwipeVideoView: View {
    let asset: PhotoAsset
    let isTopCard: Bool
    
    // [新增] 交互回调
    var onTapForDetail: () -> Void
    
    // [新增] 内部管理静音状态，默认静音
    @State private var isMuted: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 1. 播放器 (传入绑定)
                LoopingPlayerView(asset: asset.asset, shouldPlay: isTopCard, isMuted: $isMuted)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    // [新增] 点击卡片区域触发全屏预览
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTapForDetail()
                    }
                
                // 2. 遮罩
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                .frame(height: 150)
                .allowsHitTesting(false) // 让点击穿透到播放器
                
                // 3. 信息层
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(asset.dateString)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 8) {
                            Label(asset.durationString, systemImage: "clock")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial)
                                .cornerRadius(8)
                            
                            // 简单的分辨率显示
                            Text("\(asset.asset.pixelWidth)p")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial)
                                .cornerRadius(8)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // [修改] 静音按钮 (独立点击区域)
                    Button(action: {
                        isMuted.toggle()
                    }) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(20)
            }
            .background(Color.black)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Helper Extensions for Display
// 确保 PhotoAsset 有这些辅助属性，如果没有，请添加到 Models/PhotoAsset.swift
extension PhotoAsset {
    var durationString: String {
        let duration = asset.duration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: asset.creationDate ?? Date())
    }
}
