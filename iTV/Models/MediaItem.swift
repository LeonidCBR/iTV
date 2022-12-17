//
//  MediaItem.swift
//  iTV
//
//  Created by Яна Латышева on 28.11.2022.
//

import Foundation

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
