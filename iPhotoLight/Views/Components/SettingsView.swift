import SwiftUI

struct SettingsView: View {
    // [逻辑优化] 内部直接读取设置，调用时无需传参
    @AppStorage("organizeBatchSize") var batchSize: Int = 50
    
    // [新增] 弹窗状态
    @State private var showResetStatsAlert = false
    @State private var textInput: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    let presets = [10, 20, 30, 40, 50, 100]
    
    // [新增] 只有这里为了显示文字用了下 unitName，也可以写死 "Items"
    var unitName: String = "Items"
    
    var body: some View {
        NavigationView {
            Form {
                // --- 原有功能：手动输入 ---
                Section {
                    HStack {
                        Text("Custom Amount")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("Enter number", text: $textInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .onChange(of: textInput) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue { textInput = filtered }
                                if let val = Int(filtered) { batchSize = val }
                            }
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("Manual Input")
                } footer: {
                    Text("Enter 0 or select 'Unlimited' to load all items.")
                }
                
                // --- 原有功能：快捷选项 ---
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            PresetButton(title: "Unlimited", isSelected: batchSize == 0) {
                                batchSize = 0
                                textInput = ""
                            }
                            ForEach(presets, id: \.self) { num in
                                PresetButton(title: "\(num)", isSelected: batchSize == num) {
                                    batchSize = num
                                    textInput = "\(num)"
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
                } header: {
                    Text("Quick Select")
                }
                
                // --- 原有功能：当前状态 ---
                Section {
                    HStack {
                        Text("Current Limit")
                        Spacer()
                        if batchSize == 0 {
                            Text("Unlimited")
                                .bold()
                                .foregroundColor(.green)
                        } else {
                            Text("\(batchSize) \(unitName)")
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // --- 【新增功能】数据管理 (Data Management) ---
                // 保持原生风格，添加一个红色按钮 Section
                Section {
                    Button(role: .destructive) {
                        showResetStatsAlert = true
                    } label: {
                        HStack {
                            Text("Reset All Statistics")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("This will clear 'Cleaned Space' counter and 'Deleted' count.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let val = Int(textInput), val > 0 { batchSize = val }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if batchSize > 0 { textInput = String(batchSize) }
            }
            // 确认弹窗
            .alert(isPresented: $showResetStatsAlert) {
                Alert(
                    title: Text("Reset All Stats?"),
                    message: Text("This will clear your 'Cleaned Space' achievement and deleted counts. This cannot be undone."),
                    primaryButton: .destructive(Text("Reset All"), action: {
                        performFullReset()
                    }),
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // 执行重置逻辑
    private func performFullReset() {
        ReviewHistoryManager.shared.clearHistory()
        TrashManager.shared.resetStatistics()
        
        // 简单的触感反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// 辅助组件保持不变
struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
