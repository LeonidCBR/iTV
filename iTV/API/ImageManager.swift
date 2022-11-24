//
//  ImageManager.swift
//  iTV
//
//  Created by Яна Латышева on 24.11.2022.
//

import UIKit

final class ImageManager {

    private let cacheImages = NSCache<NSString, UIImage>()

    func clearCache() {
        cacheImages.removeAllObjects()
    }

    func downloadImage(with imagePath: String,
                       completionHandler: @escaping (Result<UIImage, NetworkError>, String) -> Void) {

        // Check cache
        if let cachedImage = cacheImages.object(forKey: imagePath as NSString) {
            print("DEBUG: Fetching from cache - \(imagePath)")
            completionHandler(.success(cachedImage), imagePath)
            return
        }

        // Download image

        guard let imageUrl = URL(string: imagePath) else {
            completionHandler(.failure(.unexpectedURL), imagePath)
            return
        }

        ApiClient().downloadData(withUrl: imageUrl) { [weak self] result in
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
