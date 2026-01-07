import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var showResetAlert = false
    
    // 1. 获取 LocalizationManager
    @EnvironmentObject var languageManager: LocalizationManager
    
    var body: some View {
        ZStack {
            // 背景
            LiquidBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    // [修改后] 使用 Storage Manager 获取 "使用统计"，并统一字体
                    Text("Storage Manager".localized)
                        .font(.custom("BradleyHandITCTT-Bold", size: 42))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                ScrollView {
                    VStack(spacing: 10) {
                        
                        // --- 第一部分：分类详情卡片 ---
                        VStack(spacing: 10) {
                            StatRowCard(data: viewModel.photoStats)
                            StatRowCard(data: viewModel.screenshotStats)
                            StatRowCard(data: viewModel.videoStats)
                        }
                        .padding(.horizontal)
                        
                        // --- 第二部分：总腾出空间 & 条形图 ---
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundColor(.gray)
                                Text("Total Cleaned".localized) // 国际化
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(viewModel.totalSavedSpace)
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                            
                            // 彩色条形图
                            StorageBarChart(
                                blueRatio: viewModel.photoPercent,
                                redRatio: viewModel.screenshotPercent,
                                greenRatio: viewModel.videoPercent
                            )
                            .frame(height: 12)
                            
                            // 图例 (带实时百分比)
                            HStack(spacing: 16) {
                                let hasData = viewModel.totalDeletedCount > 0
                                
                                LegendItem(
                                    color: .blue,
                                    text: "Photos".localized, // 国际化
                                    ratio: hasData ? viewModel.photoPercent : 0
                                )
                                LegendItem(
                                    color: .red,
                                    text: "Screenshots".localized, // 国际化
                                    ratio: hasData ? viewModel.screenshotPercent : 0
                                )
                                LegendItem(
                                    color: .green,
                                    text: "Videos".localized, // 国际化
                                    ratio: hasData ? viewModel.videoPercent : 0
                                )
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal)
                        
                        // --- 第三部分：设置区域 (重置 + 语言) ---
                        VStack(spacing: 10) {
                            // 3.1 重置按钮
                            Button(action: { showResetAlert = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reset Review History".localized) // 国际化
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        // 复杂的动态文本国际化建议只做简单处理，或者在 LocalizationManager 增加带参数方法
                                        // 这里简单拼接
                                        let reviewedText = "Viewed".localized + " \(viewModel.totalReviewedCount), "
                                        let deletedText = "Deleted".localized + " \(viewModel.totalDeletedCount)."
                                        
                                        Text(reviewedText + deletedText)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            
                            // 3.2 [NEW] 语言切换按钮
                            Button(action: {
                                languageManager.toggleLanguage()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Switch Language".localized)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Text(languageManager.currentLanguage.displayName)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    // 简单的语言图标
                                    Image(systemName: "globe")
                                        .foregroundColor(.secondary)
                                        .font(.body)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // 底部垫高
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .onAppear {
            viewModel.loadStats()
        }
        // 4. 监听语言变化，重新加载 VM 以刷新卡片标题 (因为卡片标题存储在 VM struct 中)
        .onChange(of: languageManager.currentLanguage) { _ in
            viewModel.loadStats()
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset Confirm".localized),
                message: Text("This will make all previously reviewed photos appear again.".localized),
                primaryButton: .destructive(Text("Reset".localized), action: { viewModel.resetHistory() }),
                secondaryButton: .cancel(Text("Cancel".localized))
            )
        }
    }
}

// MARK: - Subviews
// 注意：Subviews 中的 Label 也要国际化

struct StatRowCard: View {
    let data: CategoryStatData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: data.icon)
                    .foregroundColor(data.color)
                    .font(.body)
                Text(data.typeName) // 这里已经由 VM 传入了国际化后的字符串
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                // Label 国际化
                DataColumn(icon: "eye.fill", value: "\(data.viewedCount)", label: "Viewed".localized, color: .blue)
                Spacer()
                DataColumn(icon: "trash.fill", value: "\(data.deletedCount)", label: "Deleted".localized, color: .red)
                Spacer()
                DataColumn(icon: "paintbrush.fill", value: data.savedSpace, label: "Cleaned".localized, color: .green)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// DataColumn, StorageBarChart 保持不变
// LegendItem 不需要改动，因为 StatsView 传参时已经加了 .localized
struct DataColumn: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(minWidth: 70, alignment: .leading)
    }
}

struct StorageBarChart: View {
    let blueRatio: Double
    let redRatio: Double
    let greenRatio: Double
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue.opacity(0.9))
                    .frame(width: totalWidth * CGFloat(blueRatio))
                
                Rectangle()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: totalWidth * CGFloat(redRatio))
                
                Rectangle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: totalWidth * CGFloat(greenRatio))
                
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
            }
        }
        .clipShape(Capsule())
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    let ratio: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(ratio * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary.opacity(0.8))
        }
    }
}
