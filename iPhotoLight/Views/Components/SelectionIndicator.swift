//
//  SelectionIndicator.swift
//  iPhotoLight
//
//  Path: Views/Components/SelectionIndicator.swift
//

import SwiftUI

struct SelectionIndicator: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // 选中背景
            Circle()
                .fill(isSelected ? Color.red : Color.clear)
                .frame(width: 24, height: 24)
            
            // 白色边框
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            // 选中图标
            if isSelected {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
        .shadow(radius: 2)
    }
}
