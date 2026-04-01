// In CameraService.swift

import Foundation
import AVFoundation
import UIKit
import Combine

enum CameraError: Error {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case createCaptureInput(Error)
    case deniedAuthorization
    case restrictedAuthorization
    case unknownAuthorization
}

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    @Published var photo: UIImage?
    
    // variabile per lo zoom
    private var videoDevice: AVCaptureDevice?
    private var maxZoom: CGFloat = 1.0
    
    var currentZoom: CGFloat = 1.0
    
    @Published var flashMode: AVCaptureDevice.FlashMode = .off // Off di default
    
    func setup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.configureCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { self?.configureCaptureSession() }
                }
            }
        default:
            print("Camera access denied or restricted.")
        }
    }
    
    private func configureCaptureSession() {
        session.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .back) else {
            print("Error: Back camera not found")
            session.commitConfiguration()
            return
        }
        
        self.videoDevice = videoDevice
        self.maxZoom = videoDevice.maxAvailableVideoZoomFactor
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            session.commitConfiguration()
            return
        }
        session.addInput(videoDeviceInput)
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    // funzioni di controllo (Start/Stop/Capture)
    func start() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
    
    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        if let videoDevice = videoDevice, videoDevice.hasFlash {
             settings.flashMode = flashMode
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = videoDevice else { return }
        
        let clampedZoom = max(1.0, min(factor, maxZoom))
        
        if clampedZoom == currentZoom { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedZoom
            device.unlockForConfiguration()
            self.currentZoom = clampedZoom // Salva il nuovo zoom
        } catch {
            print("Error during zoom lock: \(error)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        DispatchQueue.main.async {
            self.photo = image
        }
    }
}
