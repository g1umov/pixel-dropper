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
    private lazy var topColorLabel = PixelDropperView()
    private lazy var bottomColorLabel = PixelDropperView()

    private lazy var sizeSider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(changeSize(_:)), for: .valueChanged)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = sizeStore
        slider.isHidden = !showingMenu

        return slider
    }()

    private lazy var topColorLabelCenterX: NSLayoutConstraint = {
        topColorLabel.colorView.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor)
    }()

    private lazy var topColorLabelCenterY: NSLayoutConstraint = {
        topColorLabel.centerYAnchor.constraint(equalTo: cameraPreview.centerYAnchor, constant: -50)
    }()

    private lazy var bottomColorLabelCenterX: NSLayoutConstraint = {
        bottomColorLabel.colorView.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor)
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

    private var showingMenu = false

    private var sizeStore: Float {
        get { UserDefaults.standard.float(forKey: "dropper_size") }
        set { UserDefaults.standard.setValue(newValue, forKey: "dropper_size") }
    }

    override func loadView() {
        super.loadView()

        setupView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraPreview.session = captureSession
        cameraPreview.videoPreviewLayer.videoGravity = .resizeAspectFill

        Task {
            await setupCaptureSession()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        serialQueue.async {
            self.captureSession.startRunning()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        serialQueue.async {
            self.captureSession.stopRunning()
        }

        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)

        super.viewWillDisappear(animated)
    }

    private func setupView() {
        changeDroppersSize(CGFloat(sizeStore))

        let tap = UITapGestureRecognizer(target: self, action: #selector(showOrHideMenu))
        view.addGestureRecognizer(tap)

        view.addSubview(cameraPreview)
        view.addSubview(sizeSider)
        cameraPreview.addSubview(topColorLabel)
        cameraPreview.addSubview(bottomColorLabel)

        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        topColorLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomColorLabel.translatesAutoresizingMaskIntoConstraints = false
        sizeSider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cameraPreview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraPreview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cameraPreview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            cameraPreview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            sizeSider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sizeSider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sizeSider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 48),

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
        guard let _ = gestureRecognizer.view as? PixelDropperView else { return }

        let translation = gestureRecognizer.translation(in: cameraPreview)
//        topColorLabelCenterX.constant += translation.x
        topColorLabelCenterY.constant += translation.y
        gestureRecognizer.setTranslation(CGPoint.zero, in: cameraPreview)
    }

    @objc func handlePanForBottomColorLabel(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let _ = gestureRecognizer.view as? PixelDropperView else { return }

        let translation = gestureRecognizer.translation(in: cameraPreview)
//        bottomColorLabelCenterX.constant += translation.x
        bottomColorLabelCenterY.constant += translation.y
        gestureRecognizer.setTranslation(CGPoint.zero, in: cameraPreview)
    }
}

// MARK: - View actions

private extension CameraViewController {

    @objc func showOrHideMenu() {
        showingMenu.toggle()
        sizeSider.isHidden = !showingMenu
    }
}

// MARK: - Slider action

private extension CameraViewController {

    @objc func changeSize(_ sender: UISlider) {
        let changedValue = CGFloat(sender.value)

        changeDroppersSize(changedValue)
        sizeStore = sender.value
    }

    func changeDroppersSize(_ value: CGFloat) {
        topColorLabel.size = value
        bottomColorLabel.size = value
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        DispatchQueue.main.async {
            let topPixelColor = self.findColor(pixelBuffer, offsetX: 0.5, offsetY: 0.25)
            self.topColorLabel.color = topPixelColor
            self.topColorLabel.text = self.getNearestColor(topPixelColor) ?? "Unknown"

            let bottomPixelColor = self.findColor(pixelBuffer, offsetX: 0.5, offsetY: 0.75)
            self.bottomColorLabel.color = bottomPixelColor
            self.bottomColorLabel.text = self.getNearestColor(bottomPixelColor) ?? "Unknown"
        }
    }
}

// MARK: - Pixel Buffer handlers

extension CameraViewController {

    // x: 0...1, y: 0...1
    func findColor(_ pixelBuffer: CVPixelBuffer, offsetX: CGFloat, offsetY: CGFloat) -> UIColor {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        let bytesPerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let bytesPerRowCbCr = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)

        let baseAddressY = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)!
        let baseAddressCbCr = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)!

        let x = Int(CGFloat(width) * offsetX)
        let y = Int(CGFloat(height) * offsetY)

        let byteOffsetY = (y * bytesPerRowY) + x
        let byteOffsetCbCr = ((y / 2) * bytesPerRowCbCr) + (x / 2) * 2

        let pixelPtrY = baseAddressY.assumingMemoryBound(to: UInt8.self)
        let pixelPtrCbCr = baseAddressCbCr.assumingMemoryBound(to: UInt8.self)

        let yValue = CGFloat(pixelPtrY[byteOffsetY])
        let cbValue = CGFloat(pixelPtrCbCr[byteOffsetCbCr])
        let crValue = CGFloat(pixelPtrCbCr[byteOffsetCbCr + 1])

        // Convert YCbCr to RGB
        let redValue = yValue + 1.402 * (crValue - 128)
        let greenValue = yValue - 0.344136 * (cbValue - 128) - 0.714136 * (crValue - 128)
        let blueValue = yValue + 1.772 * (cbValue - 128)

        let red = redValue / 255
        let green = greenValue / 255
        let blue = blueValue / 255

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

// MARK: - Color handlers

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

// MARK: - Device orientation

fileprivate extension CameraViewController {

    @objc func deviceOrientationDidChange() {
        let deviceOrientation = UIDevice.current.orientation

        switch deviceOrientation {
        case .portrait:
            updateVideoOrientation(.portrait)
        case .landscapeLeft:
            updateVideoOrientation(.landscapeRight)
        case .landscapeRight:
            updateVideoOrientation(.landscapeLeft)
        default:
            break
        }
    }

    func updateVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        guard let connection = cameraPreview.videoPreviewLayer.connection else {
            return
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
    }
}
