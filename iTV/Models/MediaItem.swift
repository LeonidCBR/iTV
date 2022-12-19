//
//  MediaItem.swift
//  iTV
//
//  Created by Яна Латышева on 28.11.2022.
//

import Foundation

// TODO: Use BitRateOption instead of MediaItem

/*
enum BitRateOption: CaseIterable {
    case p240
    case p360
    case p480
    case p720
    case p1080
    case k2
    case k4
    case Auto
}

extension BitRateOption: CustomStringConvertible {
    var description: String {
        switch self {
        case .p240: return "240p"
        case .p360: return "360p"
        case .p480: return "480p"
        case .p720: return "720p"
        case .p1080: return "1080p"
        case .k2: return "2k"
        case .k4: return "4k"
        case .Auto: return "Auto"
        }
    }
}
*/

struct MediaItem {
    let title: String?
    let urlString: String?
    let bitRateString: String?
    var bitrate: Double {
        switch bitRateString {
        case "240p": return 700000
        case "360p": return 1500000
        case "480p": return 2000000
        case "720p": return 4000000
        case "1080p": return 6000000
        case "2k": return 16000000
        case "4k": return 45000000
        case "Auto": return 0
        default: return 0
        }
    }
}
