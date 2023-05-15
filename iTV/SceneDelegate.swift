//
//  SceneDelegate.swift
//  iTV
//
//  Created by Яна Латышева on 23.11.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var coreDataStack: CoreDataStack?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let networkProvider = NetworkProvider()
        let imageProvider = ImageProvider(with: networkProvider)
        do {
            let coreDataStack = try CoreDataStack()
            self.coreDataStack = coreDataStack
            let channelsProvider = ChannelsProvider(with: coreDataStack)
            window?.rootViewController = HomeController(with: imageProvider,
                                                        and: channelsProvider,
                                                        and: networkProvider)
            window?.makeKeyAndVisible()
        } catch {
            let blankViewController = UIViewController()
            window?.rootViewController = blankViewController
            window?.makeKeyAndVisible()
            blankViewController.showErrorMessage(error.localizedDescription)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        Task {
            do {
                try await coreDataStack?.saveContext()
            } catch {
                window?.rootViewController?.showErrorMessage(error.localizedDescription)
            }
        }
    }

}
