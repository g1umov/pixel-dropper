//
//  SplashViewController.swift
//  ColorPixel
//
//  Created by Vladislav Glumov on 28.12.23.
//

import UIKit
import AVFoundation

final class SplashViewController: UIViewController {

    var onCompleted: (() -> Void)?

    override func loadView() {
        super.loadView()

        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkAuthorizationStatus()
    }
}

// MARK: - View Setup

private extension SplashViewController {

    func setupView() {
        view.backgroundColor = UIColor(named: "BackgroundColor")
    }
}

// MARK: - Authorization Status

private extension SplashViewController {

    func checkAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            requestCameraAccess()

        case .authorized:
            onCompleted?()

        case .denied, .restricted:
            showAlertCameraAccessNeeded()

        @unknown default:
            fatalError("Unknown authorization status for video source")
        }
    }

    func requestCameraAccess() {
        Task {
            let isAuthorized = await AVCaptureDevice.requestAccess(for: .video)

            DispatchQueue.main.async {
                if isAuthorized {
                    self.onCompleted?()
                } else {
                    self.showAlertCameraAccessNeeded()
                }
            }
        }
    }

    func showAlertCameraAccessNeeded() {
        let alert = UIAlertController(
            title: "Need Camera Access",
            message: "Camera access is required to make full use of this app.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                fatalError("Unable to initialize settings URL")
            }

            UIApplication.shared.open(settingsURL)
        })

        present(alert, animated: true)
    }
}
