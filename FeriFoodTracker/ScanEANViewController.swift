//
//  ScanEANViewController.swift
//  CitrusNutrition
//
//  Created by Assistant on 9. 10. 25.
//

import UIKit
import AVFoundation

protocol ScanEANViewControllerDelegate: AnyObject {
    func scanEANViewController(_ viewController: ScanEANViewController, didDetectEAN code: String)
}

final class ScanEANViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    public weak var delegate: ScanEANViewControllerDelegate?

    // Camera
    private let session = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private let metadataOutput = AVCaptureMetadataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let overlayView = ShadedRoundedFrameOverlayView()

    // UI
    private var didSendResult = false

    // Viewfinder config: wide landscape box (≈ 5:3)
    private let guideAspectRatio: CGFloat = 5.0 / 3.0   // width : height
    private let guideHorizontalInset: CGFloat = 32

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        self.title = "Scan barcode"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(onClose))

        // Make this screen modal for VoiceOver focus
        view.accessibilityViewIsModal = true
        // Let VoiceOver know we’re on the scan screen
        UIAccessibility.post(notification: .screenChanged,
                             argument: "Scan barcode")

        // Camera preview
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Overlay (rounded rect with outside shade)
        overlayView.backgroundColor = .clear
        overlayView.isAccessibilityElement = false      // purely decorative
        view.addSubview(overlayView)

        // Give an explanation for VoiceOver users
        view.accessibilityLabel = "Barcode scanner"
        view.accessibilityHint = "Point the barcode inside the box on the screen. It will be scanned automatically."

        // Try to give the close button a clearer label
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Close"
        navigationItem.rightBarButtonItem?.accessibilityHint = "Dismisses the barcode scanner."

        configureCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        previewLayer.frame = view.bounds

        // Compute the guide rect
        let safe = view.safeAreaInsets
        let available = view.bounds.inset(by: UIEdgeInsets(top: safe.top + 8,
                                                           left: guideHorizontalInset,
                                                           bottom: safe.bottom + 160,
                                                           right: guideHorizontalInset))

        var guideW = available.width
        var guideH = guideW / guideAspectRatio
        if guideH > available.height {
            guideH = available.height
            guideW = guideH * guideAspectRatio
        }

        let guideX = (view.bounds.width - guideW) / 2.0
        let guideY = safe.top + (available.height - guideH) / 2.0 + 12 // small downward nudge
        let guideRect = CGRect(x: guideX, y: guideY, width: guideW, height: guideH)

        overlayView.frame = view.bounds
        overlayView.cropRect = guideRect
        overlayView.setNeedsDisplay()

        // Update rectOfInterest to match the rounded frame
        let normalized = previewLayer.metadataOutputRectConverted(fromLayerRect: guideRect)
        metadataOutput.rectOfInterest = normalized
    }

    @objc
    func onClose() {
        self.dismiss(animated: true)
    }

    // MARK: - Camera Setup
    private func configureCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { granted ? self?.setupSession() : self?.showCameraDenied() }
            }
        default:
            showCameraDenied()
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Input
        if let input = deviceInput { session.removeInput(input) }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        deviceInput = input

        // Metadata output
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            let supported = metadataOutput.availableMetadataObjectTypes
            var desired: [AVMetadataObject.ObjectType] = []
            if supported.contains(.ean13)  { desired.append(.ean13)  }
            if supported.contains(.ean8)   { desired.append(.ean8)   }
            if supported.contains(.upce)   { desired.append(.upce)   }
            if supported.contains(.code128){ desired.append(.code128) }
            metadataOutput.metadataObjectTypes = desired
        }

        session.commitConfiguration()
        session.startRunning()

        // Inform VoiceOver that scanning is active
        UIAccessibility.post(notification: .announcement,
                             argument: "Camera active. Point the barcode inside the box to scan.")

        // Ensure rectOfInterest is set after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let normalized = self.previewLayer.metadataOutputRectConverted(fromLayerRect: self.overlayView.cropRect)
            self.metadataOutput.rectOfInterest = normalized
        }
    }

    private func showCameraDenied() {
        let alert = UIAlertController(
            title: "Camera Access Needed",
            message: "Enable camera access in Settings to scan barcodes.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Done", style: .default))
        present(alert, animated: true)
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !didSendResult else { return }
        for obj in metadataObjects {
            guard let readable = obj as? AVMetadataMachineReadableCodeObject,
                  let type = readable.type as AVMetadataObject.ObjectType?,
                  (type == .ean13 || type == .ean8 || type == .upce || type == .code128),
                  let value = readable.stringValue, !value.isEmpty else { continue }

            didSendResult = true
            if session.isRunning { session.stopRunning() }
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // VoiceOver feedback on success
            UIAccessibility.post(notification: .announcement,
                                 argument: String(format: "Barcode %@ scanned successfully.", value))

            delegate?.scanEANViewController(self, didDetectEAN: value)
            break
        }
    }
}

// MARK: - Overlay: rounded rectangle with shaded outside
fileprivate final class ShadedRoundedFrameOverlayView: UIView {
    var cropRect: CGRect = .zero {
        didSet { setNeedsDisplay() }
    }

    // Style
    var lineWidth: CGFloat = 5
    var cornerRadius: CGFloat = 26
    var strokeColor: UIColor = .white
    var shadeAlpha: CGFloat = 0.45

    override func draw(_ rect: CGRect) {
        guard !cropRect.isEmpty else { return }

        // 1) Dim everything except the rounded cutout
        let overlay = UIBezierPath(rect: bounds)
        let cutout = UIBezierPath(roundedRect: cropRect, cornerRadius: cornerRadius).reversing()
        overlay.append(cutout)
        UIColor.black.withAlphaComponent(shadeAlpha).setFill()
        overlay.fill()

        // 2) Draw the rounded border
        let border = UIBezierPath(roundedRect: cropRect, cornerRadius: cornerRadius)
        border.lineWidth = lineWidth
        strokeColor.setStroke()
        border.stroke()
    }
}
