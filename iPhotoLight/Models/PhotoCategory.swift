import Foundation
internal import Photos
import PhotosUI

enum PhotoCategory: String, CaseIterable, Identifiable {
    case all = "Recent"
    case favorites = "Favorites"
    case screenshots = "Screenshots"
    case selfies = "Selfies"
    case live = "Live" // 【新增】实况
    
    var id: String { rawValue }
    
    // 【核心修复】添加 predicate 属性，解决编译报错
    var predicate: NSPredicate? {
        switch self {
        case .all:
            // "Recent" 不做筛选，返回所有
            return nil
            
        case .favorites:
            // 筛选收藏
            return NSPredicate(format: "isFavorite == YES")
            
        case .screenshots:
            // 筛选截屏 (通过 mediaSubtypes 位掩码)
            return NSPredicate(format: "(mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            
        case .live:
            // 【新增】筛选实况照片
            return NSPredicate(format: "(mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
            
        case .selfies:
            // 注意：PhotoKit 的纯谓词查询(NSPredicate)很难直接筛选"自拍"。
            // "自拍"通常属于系统智能相册(SmartAlbum)。
            // 为了防止报错，这里暂时返回 nil (显示所有)，或者你可以选择移除这个选项。
            // 如果必须筛选自拍，需要修改 Manager 改用 fetchAssetCollections 逻辑。
            return nil
        }
    }
    
    // 图标配置 (保持你原有的代码)
    var systemIconName: String {
        switch self {
        case .all: return "photo.on.rectangle"
        case .favorites: return "heart.fill"
        case .screenshots: return "camera.viewfinder"
        case .selfies: return "person.crop.square"
        case .live: return "livephoto" // 【新增】实况图标
        }
    }
}
