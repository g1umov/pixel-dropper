//
//  CameraViewController.swift
//  ColorPixel
//
//  Created by Vladislav on 25.06.23.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {

    // MARK: Subviews

    private let cameraPreview = CameraPreview()
    private let topColorInfoView = ColorInfoView()
    private let bottomColorInfoView = ColorInfoView()

    private lazy var sizeSlider = UISlider().apply {
        $0.minimumValue = -0.5
        $0.maximumValue = 1
        $0.value = sizeStore
        $0.isHidden = !showingMenu

        $0.addTarget(self, action: #selector(changeSize(_:)), for: .valueChanged)
    }

    // MARK: Constraints

    private lazy var topColorLabelCenterX: NSLayoutConstraint = {
        topColorInfoView.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor)
    }()

    private lazy var topColorLabelCenterY: NSLayoutConstraint = {
        topColorInfoView.centerYAnchor.constraint(equalTo: cameraPreview.centerYAnchor,
                                               constant: CGFloat(topDropperPositionY))
    }()

    private lazy var bottomColorLabelCenterX: NSLayoutConstraint = {
        bottomColorInfoView.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor)
    }()

    private lazy var bottomColorLabelCenterY: NSLayoutConstraint = {
        bottomColorInfoView.centerYAnchor.constraint(equalTo: cameraPreview.centerYAnchor,
                                                  constant: CGFloat(bottomDropperPositionY))
    }()

    // MARK: Models

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
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    private var showingMenu = false

    // MARK: Properties Storage

    private var sizeStore: Float {
        get {
            UserDefaults.standard.float(forKey: "dropper_size")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "dropper_size")
        }
    }

    private var topDropperPositionY: Float {
        get {
            UserDefaults.standard.value(forKey: "top_dropper_position_y") as? Float ?? -50
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "top_dropper_position_y")
        }
    }

    private var bottomDropperPositionY: Float {
        get {
            UserDefaults.standard.value(forKey: "bottom_dropper_position_y") as? Float ?? 50
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "bottom_dropper_position_y")
        }
    }

    // MARK: View Life-Cycle

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
            cameraPreview.videoPreviewLayer.connection?.videoOrientation = .landscapeRight
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

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - View setup

private extension CameraViewController {

    func setupView() {
        changeDroppersSize(CGFloat(sizeStore))

        view.addSubview(cameraPreview)
        view.addSubview(sizeSlider)
        cameraPreview.addSubview(topColorInfoView)
        cameraPreview.addSubview(bottomColorInfoView)

        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        topColorInfoView.translatesAutoresizingMaskIntoConstraints = false
        bottomColorInfoView.translatesAutoresizingMaskIntoConstraints = false
        sizeSlider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cameraPreview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraPreview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cameraPreview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sizeSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sizeSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sizeSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 48),

            topColorLabelCenterX,
            topColorLabelCenterY,

            bottomColorLabelCenterX,
            bottomColorLabelCenterY
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(showOrHideMenu))
        view.addGestureRecognizer(tap)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(zoomCamera(_:)))
        view.addGestureRecognizer(pinch)

        let topColorLabelPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanForTopColorLabel(_:)))
        topColorInfoView.addGestureRecognizer(topColorLabelPanGesture)

        let bottomColorLabelPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanForBottomColorLabel(_:)))
        bottomColorInfoView.addGestureRecognizer(bottomColorLabelPanGesture)
    }
}

// MARK: - Capture session

private extension CameraViewController {

    func setupCaptureSession() async {
        guard isAuthorized else { return }

        captureSession.beginConfiguration()

        setupDeviceInput()
        setupDataOutput()

        if captureSession.canSetSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = .hd4K3840x2160
        }

        captureSession.commitConfiguration()
    }

    func setupDeviceInput() {
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
    }

    func setupDataOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: .global(qos: .userInteractive))
        captureSession.addOutput(videoOutput)
    }
}

// MARK: - Moving dropper views

private extension CameraViewController {

    @objc func handlePanForTopColorLabel(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let _ = gestureRecognizer.view as? ColorInfoView else { return }

        let translation = gestureRecognizer.translation(in: cameraPreview)
        topColorLabelCenterY.constant += translation.y
        topDropperPositionY = Float(topColorLabelCenterY.constant)
        gestureRecognizer.setTranslation(CGPoint.zero, in: cameraPreview)
    }

    @objc func handlePanForBottomColorLabel(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let _ = gestureRecognizer.view as? ColorInfoView else { return }

        let translation = gestureRecognizer.translation(in: cameraPreview)
        bottomColorLabelCenterY.constant += translation.y
        bottomDropperPositionY = Float(bottomColorLabelCenterY.constant)
        gestureRecognizer.setTranslation(CGPoint.zero, in: cameraPreview)
    }
}

// MARK: - View actions

private extension CameraViewController {

    @objc func showOrHideMenu() {
        showingMenu.toggle()
        sizeSlider.isHidden = !showingMenu
    }

    @objc func zoomCamera(_ gesture: UIPinchGestureRecognizer) {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }

        do {
            try device.lockForConfiguration()

            let desiredZoomFactor = device.videoZoomFactor * gesture.scale
            let minZoomFactor = device.minAvailableVideoZoomFactor
            let maxZoomFactor = device.maxAvailableVideoZoomFactor

            let clampedZoomFactor = max(min(desiredZoomFactor, maxZoomFactor), minZoomFactor)
            device.ramp(toVideoZoomFactor: clampedZoomFactor, withRate: 1.0)

            device.unlockForConfiguration()
        } catch {
            print("Error adjusting zoom factor: \(error)")
        }
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
        topColorInfoView.size = value
        bottomColorInfoView.size = value
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        DispatchQueue.main.async {
            let topPixelColor = self.findColor(pixelBuffer, offsetX: 0.5, offsetY: 0.35)
            self.topColorInfoView.color = topPixelColor
            self.topColorInfoView.text = self.getNearestColor(topPixelColor) ?? "Unknown"

            let bottomPixelColor = self.findColor(pixelBuffer, offsetX: 0.5, offsetY: 0.65)
            self.bottomColorInfoView.color = bottomPixelColor
            self.bottomColorInfoView.text = self.getNearestColor(bottomPixelColor) ?? "Unknown"
        }
    }
}

// MARK: - Pixel Buffer handlers

private extension CameraViewController {

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

private extension CameraViewController {

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

// MARK: - Device orientation triggers

private extension CameraViewController {

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
