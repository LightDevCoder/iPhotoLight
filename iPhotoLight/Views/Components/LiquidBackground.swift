import SwiftUI

struct LiquidBackground: View {
    @State private var animate = false
    
    // 定义三种核心流体颜色 (您可以根据喜好调整)
    // 这里的配色方案是：科技蓝 + 梦幻紫 + 活力青
    let color1 = Color(red: 0.4, green: 0.6, blue: 0.9) // Blue-ish
    let color2 = Color(red: 0.7, green: 0.4, blue: 0.9) // Purple-ish
    let color3 = Color(red: 0.4, green: 0.9, blue: 0.8) // Cyan-ish
    
    var body: some View {
        ZStack {
            // 基础底色 (避免深色模式下背景太黑)
            Color("BackgroundBase") // 如果没有 Assets 颜色，可以用 Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Blob 1: 左上 -> 右下
            Circle()
                .fill(color1)
                .frame(width: 350, height: 350)
                .blur(radius: 60) // 核心：重度模糊产生液态感
                .offset(x: animate ? 100 : -100, y: animate ? 50 : -150)
                .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: animate)
            
            // Blob 2: 右下 -> 左上
            Circle()
                .fill(color2)
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 150, y: animate ? -100 : 100)
                .opacity(0.7)
                .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animate)
            
            // Blob 3: 中间呼吸
            Circle()
                .fill(color3)
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: animate ? -50 : 50, y: animate ? 100 : -50)
                .opacity(0.6)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: animate)
        }
        .ignoresSafeArea()
        .onAppear {
            // 启动动画
            animate.toggle()
        }
    }
}

// 预览辅助
struct LiquidBackground_Previews: PreviewProvider {
    static var previews: some View {
        LiquidBackground()
    }
}
