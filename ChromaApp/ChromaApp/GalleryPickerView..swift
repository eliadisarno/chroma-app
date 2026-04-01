// In GalleryPickerView.swift

import SwiftUI
import PhotosUI //framework moderno per le foto

struct GalleryPickerView: UIViewControllerRepresentable {
    
    // binding per "restituire" l'immagine scelta
    @Binding var selectedImage: UIImage?
    
    // per chiudere la vista
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images //  solo immagini
        config.selectionLimit = 1 // una foto alla volta
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: GalleryPickerView

        init(parent: GalleryPickerView) {
            self.parent = parent
        }

        // questa funzione viene chiamata quando l'utente sceglie una foto
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            // chiudi la galleria
            parent.presentationMode.wrappedValue.dismiss()

            // prendi il primo risultato (e unico)
            guard let provider = results.first?.itemProvider else { return }

            // chiedi i dati dell'immagine
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { (image, error) in
                    // passa l'immagine al @Binding
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}
