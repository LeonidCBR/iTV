//
//  NetworkError.swift
//  iTV
//
//  Created by Яна Латышева on 24.11.2022.
//

import Foundation

enum NetworkError: Error, LocalizedError {

    case urlSessionError(_ error: Error)
    case noResponse
    case unauthorized
    case unhandledError(_ status: Int)
    case unexpectedData
    case unexpectedJSON
    case unexpectedURL

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
          }
      }
}
