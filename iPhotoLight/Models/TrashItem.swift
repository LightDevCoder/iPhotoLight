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
    
    var formattedSize: String {
        if size == 0 { return "0 KB" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB, .useKB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: size)
    }
}
