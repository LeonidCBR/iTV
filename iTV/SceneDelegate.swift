//
//  SceneDelegate.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var channelsProvider: ChannelsProvider?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let networkProvider = NetworkProvider()
        let imageProvider = ImageProvider(with: networkProvider)
        let channelsProvider = ChannelsProvider()
        self.channelsProvider = channelsProvider
        window?.rootViewController = HomeController(with: imageProvider, and: channelsProvider, and: networkProvider)
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
//        ChannelsProvider.shared.saveContext()
        channelsProvider?.saveContext()
    }

}
