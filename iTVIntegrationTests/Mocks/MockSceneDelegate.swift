//
//  MockSceneDelegate.swift
//  iTVTests
//
//  Created by Яна Латышева on 17.12.2022.
//

import UIKit

class MockSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MockRootViewController()
        window?.makeKeyAndVisible()
    }

}
