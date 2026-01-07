import SwiftUI

struct PermissionBlockingView: View {
    // 监听语言管理器，确保切换语言时视图会自动刷新
    // 虽然我们直接用 String.localized，但保留这个 ObservedObject 可以通知 View 重绘
    @ObservedObject var l10n = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            // 文案
            VStack(spacing: 10) {
                // 使用 .localized 扩展
                Text("Access Required".localized)
                    .font(.custom("Bradley Hand", size: 32)) // 保持 App 风格
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("iPhotoLight needs access to your photo library to help you organize and clean up.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // 按钮：跳转设置
            Button(action: {
                PhotoLibraryManager.shared.openSystemSettings()
            }) {
                Text("Open Settings".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(Color.blue)
                    .cornerRadius(30)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 20)
            
            Spacer()
            Spacer()
        }
        .background(.ultraThinMaterial) // 保持毛玻璃背景
    }
}
