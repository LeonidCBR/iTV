//
//  ApiClient.swift
//  iTV
//
//  Created by Яна Латышева on 24.11.2022.
//

import Foundation

final class ApiClient {
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func downloadData(withUrl url: URL,
                      completionHandler: @escaping (Result<Data, NetworkError>) -> Void) {
        let request = URLRequest(url: url)
        downloadData(with: request, completionHandler: completionHandler)
    }

    func downloadData(with request: URLRequest,
                      completionHandler: @escaping (Result<Data, NetworkError>) -> Void) {
        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completionHandler(.failure(.urlSessionError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completionHandler(.failure(.noResponse))
                return
            }

            if !(200...299).contains(httpResponse.statusCode) {
                let code = httpResponse.statusCode
                if code == 401 {
                    completionHandler(.failure(.unauthorized))
                } else {
                    completionHandler(.failure(.unhandledError(code)))
                }
                return
            }

            guard let mimeType = httpResponse.mimeType,
                  (mimeType == "application/json") || ( mimeType.hasPrefix("image") ),
                  let data = data else {
                      completionHandler(.failure(.unexpectedData))
                      return
                  }
            completionHandler(.success(data))
        }
        dataTask.resume()
    }
}
