//
//  ImageProvider.swift
//  iTV
//
//  Created by Яна Латышева on 24.11.2022.
//

import UIKit

final class ImageProvider {

    // MARK: - Properties
    
    private let apiClient: NetworkProvider
    private let cacheImages = NSCache<NSString, UIImage>()


    // MARK: - Lifecycle

    init(with apiClient: NetworkProvider) {
        self.apiClient = apiClient
    }


    // MARK: - Methods
    
    func clearCache() {
        cacheImages.removeAllObjects()
    }

    func downloadImage(with imagePath: String,
                       completionHandler: @escaping (Result<UIImage, ChannelError>, String) -> Void) {

        // Check cache
        if let cachedImage = cacheImages.object(forKey: imagePath as NSString) {
            completionHandler(.success(cachedImage), imagePath)
            return
        }

        // Download image
        guard let imageUrl = URL(string: imagePath) else {
            completionHandler(.failure(.unexpectedURL), imagePath)
            return
        }

        apiClient.downloadData(withUrl: imageUrl) { [weak self] result in

            // TODO: use async/await

            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let image = UIImage(data: data) {
                        // Add image to cache
                        self?.cacheImages.setObject(image, forKey: imagePath as NSString)
                        completionHandler(.success(image), imagePath)
                    } else {
                        completionHandler(.failure(.unexpectedData), imagePath)
                    }
                case .failure(let error):
                    completionHandler(.failure(error), imagePath)
                }
            }
        }
    }

}
