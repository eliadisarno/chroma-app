// ColorAnalysisView.swift

import SwiftUI
import UIKit
import CoreImage

struct ColorAnalysisView: View {
    
    @Binding var image1: UIImage?
    @Binding var image2: UIImage?
    
    var saveAction: (UIImage, UIImage, String, String, String, String) -> Void
    var cancelAction: () -> Void

    // stati della Vista
    @State private var color1: UIColor?
    @State private var colorName1: String = "Analyzing..."
    @State private var color2: UIColor?
    @State private var colorName2: String = "Analyzing..."
    @State private var outfitName: String = ""
    @State private var nameError: Bool = false
    
    // stato per la percentuale di abbinamento
    @State private var matchPercentage: String = "N/A"
    
    @State private var showingError: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    // per prevenire crash con immagini nil
    private var safeImage1: UIImage { image1 ?? UIImage() }
    private var safeImage2: UIImage { image2 ?? UIImage() }
    
    var body: some View {
        NavigationView {
            VStack {
                
                VStack(alignment: .leading, spacing: 5) {
                    
                    if showingError {
                        Text("Outfit name is required.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .transition(.opacity)
                            .padding(.leading, 10)
                    }
                    
                    TextField("", text: $outfitName, prompt: Text("Name your outfit").foregroundColor(.gray))
                            .padding(11)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(45)
                            .foregroundColor(.white.opacity(0.93))
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                withAnimation(.spring(duration: 0.3)) {
                                    isTextFieldFocused = false
                                }
                            }
                            .onChange(of: outfitName) {
                                withAnimation {
                                    if showingError && !outfitName.isEmpty {
                                        self.showingError = false
                                        self.nameError = false
                                    }
                                }
                            }
                }
                .padding([.horizontal, .top])
                
                Spacer()

                // visualizza le immagini caricate (con mirino 50x50)
                HStack(spacing: 10) {
                    ImageDisplayView(image: safeImage1)
                    ImageDisplayView(image: safeImage2)
                }
                .padding(.vertical)

                // visualizza i colori analizzati
                HStack(spacing: 20) {
                    // colore 1
                    VStack {
                        Color(color1 ?? .clear)
                            .frame(width: 80, height: 80)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        Text(colorName1)
                            .foregroundColor(.white)
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: 100)

                    // colore 2
                    VStack {
                        Color(color2 ?? .clear)
                            .frame(width: 80, height: 80)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        Text(colorName2)
                            .foregroundColor(.white)
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: 100)
                }
                
                // mostra la percentuale di abbinamento
                Text("Match: \(matchPercentage)")
                    .font(.title2.weight(.heavy))
                    .foregroundColor(colorName1 == "Analizyng..." ? .gray : .white)
                    .padding(.top, 10)

                Spacer()
            }
            .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    isTextFieldFocused = false
                }
            }
            .navigationTitle("Color Analysis")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .destructive) {
                        // Chiude la tastiera (animato) e annulla
                        withAnimation(.spring(duration: 0.3)) {
                            isTextFieldFocused = false
                        }
                        cancelAction()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let trimmedName = outfitName.trimmingCharacters(in: .whitespacesAndNewlines)

                        if trimmedName.isEmpty {
                            // Errore: mostra l'alert ma NON chiudere la tastiera
                            withAnimation {
                                self.nameError = true
                                self.showingError = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation {
                                    self.showingError = false
                                }
                            }
                            return // <-- Esce senza chiudere la tastiera
                        }

                        // Successo: chiudi la tastiera (animato) e salva
                        withAnimation(.spring(duration: 0.3)) {
                            isTextFieldFocused = false
                        }
                        
                        if let img1 = image1, let img2 = image2 {
                            let name = trimmedName
                            saveAction(img1, img2, name, colorName1, colorName2, matchPercentage)
                        }
                    }
                    .disabled(colorName1 == "Analyzing...")
                    .fontWeight(.bold)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onAppear {
                analyzeColors()
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    // converte RGB in Int 0-255
    private func getRGBInt(from color: UIColor) -> (r: Int, g: Int, b: Int)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (Int(r * 255), Int(g * 255), Int(b * 255))
        }
        return nil
    }

    // MARK: Logica di Classificazione RGB
    
    func findClosestColor(to color: UIColor) -> String {
        guard let (r, g, b) = getRGBInt(from: color) else { return "Unknown" }
        
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let diff = maxVal - minVal // indice di saturazione/tinta
        let avg = (r + g + b) / 3 // luminosità media
        
        let dominanceThreshold = 30 // riconoscimento di base della tinta
        
        
        // se c'è sufficiente saturazione (diff > 25) e una chiara dominanza, è un colore scuro, NON NERO.
        if diff >= 25 {
            
            // ROSSO
            if r > g + dominanceThreshold && r > b + dominanceThreshold {
                return "RED"
            }
            
            // VERDE
            if g > r + dominanceThreshold && g > b + dominanceThreshold {
                return "GREEN"
            }
            
            // BLU
            if b > r + dominanceThreshold && b > g + dominanceThreshold {
                return "BLUE"
            }
            
            // fallback se saturo ma non primario (es. viola scuro, marrone)
            if maxVal >= 80 {
                // passa al fallback distance per classificare i secondari scuri
                // salta i controlli NERO/GRIGIO se la diff è alta.
            } else {
                 // se saturo ma comunque molto scuro (maxVal < 80), lo consideriamo NERO
            }
        }
            
        // BIANCO
        if avg >= 160 && diff < 50 {
            return "WHITE"
        }
        
        // GRIGIO
        if avg > 45 && avg < 170 && diff < 15 {
            return "GRAY"
        }
        
        // NERO
        if avg <= 45 && diff < 15 {
            return "BLACK"
        }
        
        var closest = "UNKNOWN"
        var minDistSq: CGFloat = .greatestFiniteMagnitude

        let target = color.rgba()
        
        let fallbackColors: [String: UIColor] = [
            "WHITE": .white, "BLACK": .black, "GRAY": .gray,
            "RED": .red, "BLUE": .blue, "BROWN": .brown,
            "ORANGE": .orange, "YELLOW": .yellow, "GREEN": .green,
            "PURPLE": UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1.0)
        ]
        
        for (name, refColor) in fallbackColors {
            let ref = refColor.rgba()
            let distSq = pow(target.r - ref.r, 2) + pow(target.g - ref.g, 2) + pow(target.b - ref.b, 2)
            
            if distSq < minDistSq {
                minDistSq = distSq
                closest = name
            }
        }
        
        // fe il fallback trova Nero ma il colore iniziale aveva sufficiente tinta (diff > 15),
        // potremmo voler forzare un secondario scuro (es. MARRONE) al posto di NERO.
        if closest == "BLACK" && diff > 15 && avg > 30 {
            return "BROWN"
        }
        
        return closest
    }

     /* versione 2 ... */
    
    
    // MARK: campiona il colore medio della zona centrale (50x50 pixel)
    private func getCentralAverageColor(image: UIImage) -> UIColor {
        guard let cgImage = image.cgImage else { return UIColor.clear }
        let width = cgImage.width
        let height = cgImage.height

        // dimensione del mirino/campionamento 50x50
        let sampleSize: Int = 50
        let rectWidth = sampleSize
        let rectHeight = sampleSize
        
        let rect = CGRect(x: (width / 2) - (rectWidth / 2),
                          y: (height / 2) - (rectHeight / 2),
                          width: rectWidth,
                          height: rectHeight)

        guard let croppedCG = cgImage.cropping(to: rect) else { return UIColor.clear }
        let croppedImage = UIImage(cgImage: croppedCG)
        return getAverageColor(image: croppedImage) ?? UIColor.clear
    }

    // MARK: funzione per ottenere il colore medio
    private func getAverageColor(image: UIImage?) -> UIColor? {
        guard let input = image, let ciImage = CIImage(image: input) else { return nil }
        
        let params = [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: ciImage.extent)]
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: params),
              let outputImage = filter.outputImage else { return nil }
              
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: nil)
        context.render(outputImage, toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8, colorSpace: nil)
                       
        return UIColor(red: CGFloat(bitmap[0])/255,
                       green: CGFloat(bitmap[1])/255,
                       blue: CGFloat(bitmap[2])/255,
                       alpha: CGFloat(bitmap[3])/255)
    }
    
    // MARK: algoritmo di calcolo della percentuale di abbinamento basato sulla teoria del colore
    private func calculateMatchPercentage(color1: UIColor, color2: UIColor, name1: String, name2: String) -> String {
        
        let NEUTRALS: Set<String> = ["WHITE", "BLACK", "GRAY"]
        let isNeutral1 = NEUTRALS.contains(name1)
        let isNeutral2 = NEUTRALS.contains(name2)
        
        
        if isNeutral1 && isNeutral2 {
            return "100%"
        }
        
        if isNeutral1 || isNeutral2 {
            return "95%"
        }
        
        let hsba1 = color1.hsba()
        let hsba2 = color2.hsba()
        
        let hue1 = hsba1.h * 360
        let hue2 = hsba2.h * 360
        
        var hueDistance = abs(hue1 - hue2)
        if hueDistance > 180 {
            hueDistance = 360 - hueDistance
        }
        
        // monocromatico e analogo (vicini sulla ruota: 0° a 30°)
        if hueDistance <= 30 {
            return "90%"
        }
        
        // complementare (opposti sulla ruota: 150° a 180°)
        if hueDistance >= 150 && hueDistance <= 180 {
            return "85%"
        }
        
        // schema triade (distanza 120° +/- 15°)
        if hueDistance >= 105 && hueDistance <= 135 {
            return "80%"
        }
        
        let brightnessDifference = abs(hsba1.b - hsba2.b)
        
        if brightnessDifference > 0.20 {
            return "65%"
        }
        
 
        
        if hueDistance > 30 && hueDistance < 105 && brightnessDifference < 0.15 {
             return "45%"
        }
        
        return "55%"
    }

    
    // funzione che utilizza un'interfIA SwiftUI per mostrare l'immagine con il mirino
    struct ImageDisplayView: View {
        let image: UIImage
        // Mirino 50x50
        let mirinoSize: CGFloat = 50
        
        var body: some View {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                
                // visualizzazione del mirino 50x50px
                Rectangle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: mirinoSize, height: mirinoSize)
            }
        }
    }
    
    // MARK: analizza le immagini e trova il colore più vicino
    private func analyzeColors() {
        DispatchQueue.global(qos: .userInitiated).async {
            
            let c1 = self.getCentralAverageColor(image: self.safeImage1)
            let c2 = self.getCentralAverageColor(image: self.safeImage2)

            let name1 = self.findClosestColor(to: c1)
            let name2 = self.findClosestColor(to: c2)
            
            // calcola la percentuale con i nomi dei colori neutri
            let percentage = self.calculateMatchPercentage(color1: c1, color2: c2, name1: name1, name2: name2)

            DispatchQueue.main.async {
                self.color1 = c1
                self.colorName1 = name1
                self.color2 = c2
                self.colorName2 = name2
                self.matchPercentage = percentage // aggiorna lo stato
            }
        }
    }
}

// MARK: estensione UIColor per ottenere i componenti RGB e HSL
extension UIColor {
    
    func rgba() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
    
    // ottiene tonalità, saturazione e luminosità HSL
    func hsba() -> (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b, a)
    }
}
