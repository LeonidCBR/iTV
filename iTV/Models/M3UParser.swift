//
//  M3UParser.swift
//  iTV
//
//  Created by Яна Латышева on 28.11.2022.
//

import Foundation

// TODO: Get rid of this struct
/*
struct M3UParser {
    let source: URL

    init(withUrl url: URL) {
        source = url
    }

    /**
     Parse playlist and get media assets
     */
    func getMediaItems() throws -> [MediaItem] {

        // TODO: Consider to use AVAsset, AVAssetTrack, AVMetadataItem

        var mediaItems = [MediaItem]()

        
        // TODO: - Use NetworkProvider in order to get source data
        let lines = try String(contentsOf: source)


        var title = ""
        var bitRateString = ""
        lines.enumerateLines { line, _ in
            if line.hasPrefix("#EXTINF:") {
                let infoLine = line.replacingOccurrences(of: "#EXTINF:", with: "")
                title = infoLine.components(separatedBy: ",").last ?? ""
            } else if line.hasPrefix("#EXT") {
                bitRateString = ""
                let chunks = line.components(separatedBy: ",")
                for chunk in chunks {
                    if chunk.hasPrefix("RESOLUTION=") {
                        let bitRate = chunk.replacingOccurrences(of: "RESOLUTION=", with: "")
                        //bitRate = 1280x720
                        if let idx = bitRate.firstIndex(of: "x") {
                            let suffix = bitRate.suffix(from: idx)
                            bitRateString = suffix.replacingOccurrences(of: "x", with: "") + "p"
                        }
                    }
                }
            } else {
                if line.hasPrefix("http") {
                    let currentItem = MediaItem(title: title, urlString: line, bitRateString: bitRateString)
                    mediaItems.append(currentItem)
                }
            }
        }
        return mediaItems
    }
}
*/
