//
//  ImageProvider.swift
//  iTV
//
//  Created by Яна Латышева on 24.11.2022.
//

import UIKit

final class ImageProvider {

    // MARK: - Properties

    private let networkProvider: NetworkProvider
    private let cacheImages = NSCache<NSString, UIImage>()

    // MARK: - Lifecycle

    init(with networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
    }

    // MARK: - Methods

//    func clearCache() {
//        cacheImages.removeAllObjects()
//    }

    func fetchImage(withPath imagePath: String) async throws -> UIImage {
        // Check if image exists in cache
        if let cachedImage = cacheImages.object(forKey: imagePath as NSString) {
            return cachedImage
        }

        // Check image path
        guard let imageUrl = URL(string: imagePath) else {
            throw ChannelError.unexpectedURL
        }

        // Download image
        let imageData = try await networkProvider.downloadData(withUrl: imageUrl)
        if let image = UIImage(data: imageData) {
            // Add image to cache
            cacheImages.setObject(image, forKey: imagePath as NSString)
            return image
        } else {
            throw ChannelError.unexpectedData
        }

    }

}
