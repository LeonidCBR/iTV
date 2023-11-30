//
//  PersistentError.swift
//  iTV
//
//  Created by Яна Латышева on 16.05.2023.
//

import Foundation

/// Persistent errors
enum PersistentError: Error {
    case batchInsertError
    case persistentHistoryChangeError
    case persistentStoreDescriptionError
    case unexpectedError(error: Error)
}

extension PersistentError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .batchInsertError:
            return NSLocalizedString("Failed to execute a batch insert request.",
                                     comment: "")
        case .persistentHistoryChangeError:
            return NSLocalizedString("Failed to execute a persistent history change request.",
                                     comment: "")
        case .persistentStoreDescriptionError:
            return NSLocalizedString("Failed to retrieve a persistent store description.",
                                     comment: "")
        case .unexpectedError(let error):
            return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
        }
    }
}
