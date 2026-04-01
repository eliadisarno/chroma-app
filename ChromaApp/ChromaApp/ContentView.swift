// ContentView.swift

import SwiftUI
import UIKit

struct ContentView: View {
    
    @State private var isAnimating: Bool = false
    @State private var showingCustomCamera: Bool = false
    
    // dati ricavati da MainView
    @Binding var outfits: [Outfit]
    var savePairAction: (UIImage, UIImage, String, String, String, String) -> Void

    private var instructionText: String {
         return "Tap to start color matching"
    }

    var body: some View {
        ZStack {
            // sfondo
            Color.black.opacity(0.93)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                // scritta
                Text(instructionText)
                    .font(.system(size:20))
                    .fontWeight(.regular)
                    .foregroundColor(.white)
                    .offset(x:0, y:300)
                
                // pulsante
                Button(action: {
                    self.showingCustomCamera = true
                }) {
                    Image("Cerchio Foto") // immagine
                        .resizable()
                        .scaledToFit()
                        .frame(width: 190, height: 250)
                        .padding(45)
                        .clipShape(Circle())
                        .shadow(color: .gray, radius:40)
                        .offset(x:0, y:-110)
                }
                .scaleEffect(isAnimating ? 1.15 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    self.isAnimating = true
                }
            }
            
            .fullScreenCover(isPresented: $showingCustomCamera) {
                
                CustomCameraView(
                    savePairAction: self.savePairAction,
                    onCancel: {
                        self.showingCustomCamera = false
                    }
                )
            }
            
        }
    }
}


// PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            outfits: .constant([]),
            savePairAction: { _, _, _, _, _, _ in
                print("Preview: saving outfit...")
            }
        )
    }
}
