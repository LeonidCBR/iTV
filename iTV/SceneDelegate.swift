//
//  SceneDelegate.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let apiClient = NetworkProvider()
        let imageManager = ImageProvider(with: apiClient)
        window?.rootViewController = HomeController(with: imageManager)
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        ChannelsProvider.shared.saveContext()
    }

}

