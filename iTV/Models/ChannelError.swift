//
//  ChannelError.swift
//  iTV
//
//  Created by Яна Латышева on 24.11.2022.
//

import Foundation

/// Decoding data errors
enum ChannelError: Error {
    case missingData
    case wrongDataFormat(error: Error)
}

extension ChannelError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingData:
            return NSLocalizedString("There is no data", comment: "")
        case .wrongDataFormat(let error):
            return NSLocalizedString(
                "Could not digest the fetched data. \(error.localizedDescription)",
                comment: "")
        }
    }
}
