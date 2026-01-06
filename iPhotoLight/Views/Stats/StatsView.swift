import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var showResetAlert = false
    
    var body: some View {
        ZStack {
            // 背景
            LiquidBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Storage Manager")
                        .font(.custom("Bradley Hand", size: 36))
                        .fontWeight(.bold)
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
                                Text("Total Cleaned")
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
                                // 判断是否有真实数据
                                let hasData = viewModel.totalDeletedCount > 0
                                
                                LegendItem(
                                    color: .blue,
                                    text: "Photos",
                                    ratio: hasData ? viewModel.photoPercent : 0
                                )
                                LegendItem(
                                    color: .red,
                                    text: "Screenshots",
                                    ratio: hasData ? viewModel.screenshotPercent : 0
                                )
                                LegendItem(
                                    color: .green,
                                    text: "Videos",
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
                        
                        // --- 第三部分：底部重置区 ---
                        Button(action: { showResetAlert = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reset Review History")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Reviewed \(viewModel.totalReviewedCount) items, \(viewModel.totalDeletedCount) deleted.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .padding(.horizontal)
                        
                        // 底部垫高，防止被 TabBar 遮挡
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .onAppear {
            viewModel.loadStats()
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset History?"),
                message: Text("This will make all previously reviewed photos appear again."),
                primaryButton: .destructive(Text("Reset"), action: { viewModel.resetHistory() }),
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Subviews

// 1. 单行数据卡片
struct StatRowCard: View {
    let data: CategoryStatData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题行
            HStack {
                Image(systemName: data.icon)
                    .foregroundColor(data.color)
                    .font(.body)
                Text(data.typeName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // 数据行
            HStack {
                DataColumn(icon: "eye.fill", value: "\(data.viewedCount)", label: "Viewed", color: .blue)
                Spacer()
                DataColumn(icon: "trash.fill", value: "\(data.deletedCount)", label: "Deleted", color: .red)
                Spacer()
                DataColumn(icon: "paintbrush.fill", value: data.savedSpace, label: "Cleaned", color: .green)
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

// 2. 数据列组件
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

// 3. 条形图组件
struct StorageBarChart: View {
    let blueRatio: Double
    let redRatio: Double
    let greenRatio: Double
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            
            HStack(spacing: 0) {
                // Photos
                Rectangle()
                    .fill(Color.blue.opacity(0.9))
                    .frame(width: totalWidth * CGFloat(blueRatio))
                
                // Screenshots
                Rectangle()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: totalWidth * CGFloat(redRatio))
                
                // Videos
                Rectangle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: totalWidth * CGFloat(greenRatio))
                
                // 剩余
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
            }
        }
        .clipShape(Capsule())
    }
}

// 4. 图例组件 (带百分比)
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
