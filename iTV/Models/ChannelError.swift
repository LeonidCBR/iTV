//
//  ChannelError.swift
//  iTV
//
//  Created by Яна Латышева on 24.11.2022.
//

import Foundation

enum ChannelError: Error {
    case urlSessionError(_ error: Error)
    case noResponse
    case unauthorized
    case unhandledError(_ statusCode: Int)
    case unexpectedData
    case unexpectedJSON
    case unexpectedURL
    case missingData
    case wrongDataFormat(error: Error)
    case creationError
    case batchInsertError
    case batchDeleteError
    case persistentHistoryChangeError
    case unexpectedError(error: Error)
}

extension ChannelError: LocalizedError {
    public var errorDescription: String? {
          switch self {
          case .urlSessionError(let sessionError):
            return NSLocalizedString("Ошибка сети. \(sessionError.localizedDescription)", comment: "")
          case .noResponse:
            return NSLocalizedString("Нет ответа от сервера.", comment: "")
          case .unauthorized:
            return NSLocalizedString("Не верные имя пользователя или пароль.", comment: "")
          case .unhandledError(let status):
            return NSLocalizedString("Неизвестная ошибка сети. Код ошибки: \(status)", comment: "")
          case .unexpectedData:
            return NSLocalizedString("Полученные данные от сервера не возможно прочитать.", comment: "")
          case .unexpectedJSON:
            return NSLocalizedString("Полученные данные от сервера не возможно обработать.", comment: "")
          case .unexpectedURL:
              return NSLocalizedString("Не верная строка адреса для запроса.", comment: "")
          case .missingData:
              return NSLocalizedString("Нет данных", comment: "")
          case .wrongDataFormat(let error):
              return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
          case .creationError:
              return NSLocalizedString("Failed to create a new Quake object.", comment: "")
          case .batchInsertError:
              return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
          case .batchDeleteError:
              return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
          case .persistentHistoryChangeError:
              return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
          case .unexpectedError(let error):
              return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
          }
      }
}
