//
//  TestingAppDelegate.swift
//  iTVTests
//
//  Created by Яна Латышева on 17.12.2022.
//

import UIKit

@objc(TestingAppDelegate)
class TestingAppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        /**
         In order to get this method be invoked, we have to delete from Info.plist
                $(PRODUCT_MODULE_NAME).SceneDelegate
         as a value of
                Delegate Class Name
         Just set "Delegate Class Name" = ""
         */

        let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = TestingSceneDelegate.self
        sceneConfiguration.storyboard = nil
        return sceneConfiguration
    }

}
