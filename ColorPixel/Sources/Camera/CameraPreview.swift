//
//  CameraPreview.swift
//  ColorPixel
//
//  Created by Vladislav on 25.06.23.
//

import UIKit
import AVFoundation

final class CameraPreview: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    var session: AVCaptureSession? {
        get { videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }

}
