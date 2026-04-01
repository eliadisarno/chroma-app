// In CustomCameraView.swift

import SwiftUI
import AVFoundation

struct CustomCameraView: View {
   
    @StateObject private var cameraService = CameraService()
    @State private var currentZoom: CGFloat = 1.0
    @State private var photo1: UIImage?
    @State private var photo2: UIImage?
    @State private var showingComparisonSheet = false
    @State private var showingGalleryPicker = false
    @State private var imageFromGallery: UIImage?
    
    // funzioni di uscita
    var savePairAction: (UIImage, UIImage, String, String, String, String) -> Void
    var onCancel: () -> Void
    
    private var overlayText: String {
        if photo1 == nil { return "Take first photo" }
        else { return "Take second photo" }
    }
    
    // zoom
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value - 1.0
                let newZoom = currentZoom + delta
                cameraService.setZoom(factor: newZoom)
            }
            .onEnded { value in
                currentZoom = cameraService.currentZoom
            }
    }
    
    // funzione helper per l'icona del flash
    private func flashIconName(for mode: AVCaptureDevice.FlashMode) -> String {
        switch mode {
        case .on:
            return "bolt.fill"          // flash acceso
        case .off:
            return "bolt.slash.fill"    // flash spento
        case .auto:
            return "bolt.badge.a.fill"  // flash automatico
        default:
            return "bolt.slash.fill"
        }
    }
    
    // funzione helper per passare al flash mode successivo
    private func nextFlashMode(current: AVCaptureDevice.FlashMode) -> AVCaptureDevice.FlashMode {
        switch current {
        case .off:
            return .on
        case .on:
            return .auto
        case .auto:
            return .off
        default:
            return .off
        }
    }
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraService.session)
                .ignoresSafeArea()
                .gesture(zoomGesture)
            
            //MIRINO
            Image(systemName: "plus")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.white.opacity(0.7))

            VStack {
                HStack {
                    // pulsante xmark chiudi
                    Button(action: { onCancel() }) {
                        Image(systemName: "xmark")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white).padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding([.leading, .top])
                    
                    Spacer()
                    
                    // pulsante flash
                    Button(action: {
                        cameraService.flashMode = nextFlashMode(current: cameraService.flashMode)
                    }) {
                        Image(systemName: flashIconName(for: cameraService.flashMode))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white).padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding([.trailing, .top])
                    
                }
                Text(overlayText)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white).padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding(.top, 10)
                Spacer()
            }

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    Button(action: { showingGalleryPicker = true }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title.weight(.semibold))
                            .foregroundColor(.white).padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 40)
                    Spacer()
                    Button(action: { cameraService.capturePhoto() }) {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 70, height: 70)
                            Circle().stroke(Color.white, lineWidth: 4).frame(width: 80, height: 80)
                        }
                    }
                    Spacer()
                    Color.clear.frame(width: 40, height: 40).padding(.trailing, 40)
                }
                .padding(.bottom, 40)
            }
            
        }
        
        .onAppear { cameraService.setup() }
        .onDisappear { cameraService.stop() }
        .onReceive(cameraService.$photo) { (newlyTakenPhoto) in
            guard let image = newlyTakenPhoto else { return }
            processImage(image)
        }
        .sheet(isPresented: $showingGalleryPicker) {
            GalleryPickerView(selectedImage: $imageFromGallery)
        }
        .onChange(of: imageFromGallery) { newImage in
            guard let image = newImage else { return }
            processImage(image)
            imageFromGallery = nil
        }
        .sheet(isPresented: $showingComparisonSheet) {
            self.photo1 = nil
            self.photo2 = nil
        } content: {
            ColorAnalysisView(
                image1: $photo1,
                image2: $photo2,
                saveAction: { (img1, img2, name, color1, color2, percentage) in
                    savePairAction(img1, img2, name, color1, color2, percentage)
                    self.showingComparisonSheet = false
                    self.onCancel()
                },
                cancelAction: {
                    self.photo1 = nil
                    self.photo2 = nil
                    self.showingComparisonSheet = false
                }
            )
        }
    }
    
    private func processImage(_ image: UIImage) {
        if photo1 == nil {
            photo1 = image
        } else if photo2 == nil {
            photo2 = image
            self.showingComparisonSheet = true
        }
    }
}
