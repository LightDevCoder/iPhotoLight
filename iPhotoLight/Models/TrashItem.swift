import Foundation

enum TrashItemType: Int, Codable {
    case photo
    case screenshot
    case video
}

struct TrashItem: Codable, Hashable, Identifiable {
    let id: String
    let type: TrashItemType
    let size: Int64
    let deleteDate: Date
    
    // 修复：优化显示逻辑，0 直接显示 "0 KB"
    var formattedSize: String {
        if size == 0 { return "0 KB" } // 直接返回简洁的 0
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB, .useKB]
        formatter.countStyle = .file
        formatter.includesUnit = true // 确保带单位 (MB/GB)
        return formatter.string(fromByteCount: size)
    }
}
