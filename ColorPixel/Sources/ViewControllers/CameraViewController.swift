//
//  CameraViewController.swift
//  ColorPixel
//
//  Created by Vladislav on 25.06.23.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {

    private lazy var cameraPreview = CameraPreview()
    private lazy var topColorLabel = ColorLabel()
    private lazy var bottomColorLabel = ColorLabel()

    private lazy var topColorLabelCenterX: NSLayoutConstraint = {
        topColorLabel.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor)
    }()

    private lazy var topColorLabelCenterY: NSLayoutConstraint = {
        topColorLabel.centerYAnchor.constraint(equalTo: cameraPreview.centerYAnchor, constant: -50)
    }()

    private lazy var bottomColorLabelCenterX: NSLayoutConstraint = {
        bottomColorLabel.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor)
    }()

    private lazy var bottomColorLabelCenterY: NSLayoutConstraint = {
        bottomColorLabel.centerYAnchor.constraint(equalTo: cameraPreview.centerYAnchor, constant: 50)
    }()

    private let captureSession = AVCaptureSession()
    private let serialQueue = DispatchQueue(label: "AVCaptureSession.global_queue.com")

    private let colorDict: [UIColor: String] = {
        let url = Bundle.main.url(forResource: "Colors", withExtension: ".json")!
        let data = try! Data(contentsOf: url)
        let colorModels = try! JSONDecoder().decode([ColorModel].self, from: data)

        var dict = [UIColor : String]()

        colorModels.forEach {
            dict[UIColor(hex: $0.hex)!] = $0.name
        }

        return dict
    }()

    private var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)

            var isAuthorized = status == .authorized

            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }

            return isAuthorized
        }
    }

    override func loadView() {
        super.loadView()

        setupView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraPreview.session = captureSession

        Task {
            await setupCaptureSession()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        serialQueue.async {
            self.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        serialQueue.async {
            self.captureSession.stopRunning()
        }

        super.viewWillDisappear(animated)
    }

    private func setupView() {
        view.addSubview(cameraPreview)
        cameraPreview.addSubview(topColorLabel)
        cameraPreview.addSubview(bottomColorLabel)

        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        topColorLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomColorLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cameraPreview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraPreview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cameraPreview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            cameraPreview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            topColorLabelCenterX,
            topColorLabelCenterY,

            bottomColorLabelCenterX,
            bottomColorLabelCenterY
        ])

        let topColorLabelPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanForTopColorLabel(_:)))
        topColorLabel.addGestureRecognizer(topColorLabelPanGesture)

        let bottomColorLabelPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanForBottomColorLabel(_:)))
        bottomColorLabel.addGestureRecognizer(bottomColorLabelPanGesture)
    }

    private func setupCaptureSession() async {
        guard await isAuthorized else { return }

        captureSession.beginConfiguration()

        // Setup Input
        guard
            let videoDevice = AVCaptureDevice.default(for: .video)
        else {
            return
        }

        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
        else {
            return
        }

        captureSession.addInput(videoDeviceInput)

        // Setup Output
        let photoOutput = AVCapturePhotoOutput()
        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.sessionPreset = .photo

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: .global(qos: .userInteractive))

        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()
    }
}

extension CameraViewController {

    @objc func handlePanForTopColorLabel(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let _ = gestureRecognizer.view as? ColorLabel else { return }

        let translation = gestureRecognizer.translation(in: cameraPreview)
        topColorLabelCenterX.constant += translation.x
        topColorLabelCenterY.constant += translation.y
        gestureRecognizer.setTranslation(CGPoint.zero, in: cameraPreview)
    }

    @objc func handlePanForBottomColorLabel(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let _ = gestureRecognizer.view as? ColorLabel else { return }

        let translation = gestureRecognizer.translation(in: cameraPreview)
        bottomColorLabelCenterX.constant += translation.x
        bottomColorLabelCenterY.constant += translation.y
        gestureRecognizer.setTranslation(CGPoint.zero, in: cameraPreview)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)

        DispatchQueue.main.async {
            let xk = self.topColorLabel.center.x / self.cameraPreview.bounds.width
            let yk = self.topColorLabel.center.y / self.cameraPreview.bounds.height
            let pixelX = Int(CGFloat(width) * xk)
            let pixelY = Int(CGFloat(height) * yk)

            let bytesPerPixel = 4
            let byteIndex = (pixelX * bytesPerPixel) + (pixelY * bytesPerRow)

            if let baseAddress = baseAddress?.assumingMemoryBound(to: UInt8.self) {
                let pixelAddress = baseAddress + byteIndex
                let red = CGFloat(pixelAddress[2]) / 255
                let green = CGFloat(pixelAddress[1]) / 255
                let blue = CGFloat(pixelAddress[0]) / 255

                let pixelColor = UIColor(red: red, green: green, blue: blue, alpha: 1)

                self.topColorLabel.text = self.getNearestColor(pixelColor) ?? "Unknown"
                self.topColorLabel.color = pixelColor
            }
        }

        DispatchQueue.main.async {
            let xk = self.bottomColorLabel.center.x / self.cameraPreview.bounds.width
            let yk = self.bottomColorLabel.center.y / self.cameraPreview.bounds.height
            let pixelX = Int(CGFloat(width) * xk)
            let pixelY = Int(CGFloat(height) * yk)

            let bytesPerPixel = 4
            let byteIndex = (pixelX * bytesPerPixel) + (pixelY * bytesPerRow)

            if let baseAddress = baseAddress?.assumingMemoryBound(to: UInt8.self) {
                let pixelAddress = baseAddress + byteIndex
                let red = CGFloat(pixelAddress[2]) / 255
                let green = CGFloat(pixelAddress[1]) / 255
                let blue = CGFloat(pixelAddress[0]) / 255

                let pixelColor = UIColor(red: red, green: green, blue: blue, alpha: 1)

                self.bottomColorLabel.text = self.getNearestColor(pixelColor) ?? "Unknown"
                self.bottomColorLabel.color = pixelColor
            }
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
}

extension CameraViewController {

    func getNearestColor(_ inputValue: UIColor) -> String? {
        var minDistance: CGFloat = CGFloat.infinity
        var nearestColor: String?

        for (color, name) in colorDict {
            let distance = colorDistance(color1: inputValue, color2: color)
            if distance < minDistance {
                minDistance = distance
                nearestColor = name
            }
        }

        return nearestColor
    }

    func colorDistance(color1: UIColor, color2: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return sqrt(pow(r2 - r1, 2) + pow(g2 - g1, 2) + pow(b2 - b1, 2))
    }
}
