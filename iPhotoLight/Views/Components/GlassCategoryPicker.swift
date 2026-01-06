import SwiftUI

struct GlassCategoryPicker: View {
    @Binding var selection: PhotoCategory
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PhotoCategory.allCases) { category in
                let isSelected = selection == category
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = category
                    }
                } label: {
                    ZStack {
                        // 1. 选中态背景
                        // 模仿 iOS 原生 Segmented Control 的选中质感 (干净的白色 + 投影)
                        if isSelected {
                            Capsule()
                                .fill(Color.white) // 纯白底色
                                .matchedGeometryEffect(id: "ActiveTab", in: animation)
                                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1) // 原生感阴影
                        } else {
                            Capsule().fill(.clear)
                        }
                        
                        // 2. 图标
                        Image(systemName: category.systemIconName)
                            .font(.system(size: 17, weight: isSelected ? .semibold : .regular)) // 选中加粗
                            .scaleEffect(isSelected ? 1.0 : 0.95)
                            // 颜色逻辑：
                            // 选中：纯黑 (Black)
                            // 未选中：系统灰 (Secondary) - 像 TabBar 一样
                            .foregroundColor(isSelected ? .black : .secondary)
                    }
                    .frame(width: 50, height: 36) // 稍微压扁一点，更像原生条控件
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(4) // 内部留白
        // 背景容器：使用更通透的材质，不再加边框
        .background(.thickMaterial, in: Capsule())
        // 移除之前的 overlay 描边，保持极简
        .fixedSize()
    }
}
