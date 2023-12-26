//
//  SceneDelegate.swift
//  ColorPixel
//
//  Created by Vladislav on 25.06.23.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let viewController = CameraViewController()

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        self.window = window
    }
}
