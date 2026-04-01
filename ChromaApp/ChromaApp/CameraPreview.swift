// In CameraPreview.swift

import SwiftUI
import AVFoundation
import UIKit

struct CameraPreview: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    // crea la vista
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black // sfondo nero
        
        // creiamo il livello video
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // configuriamo come il video deve riempire lo spazio
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        
        // aggiungiamo il livello video sopra la vista
        view.layer.addSublayer(previewLayer)
        
        // livello riempe sempre la vista
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // frame corretto
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
