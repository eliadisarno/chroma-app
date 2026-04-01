// MainView.swift

import SwiftUI
import UIKit

// struttura che definisce un outfit con i dati di analisi colore
struct Outfit: Codable, Identifiable {
    let id = UUID()
    let imageFileName1: String
    let imageFileName2: String
    var name: String = "Untitled Outfit"
    
    var colorName1: String = "N/A"
    var colorName2: String = "N/A"
    var matchPercentage: String = "N/A"
}

struct MainView: View {
     
    @State private var selectedTab = 0
    @State private var outfits: [Outfit] = []
    private let userDefaultsKey = "SavedOutfits"
     
    // configurazione dell'aspetto della Tab Bar
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
         
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
         
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
     
    var body: some View {
         
        TabView(selection: $selectedTab) {
             
            // PRIMO TAB: Fotocamera
            ContentView(
                outfits: $outfits,
                savePairAction: {(image1, image2, name, color1, color2, percentage) in
                    self.saveOutfit(image1: image1,
                                    image2: image2,
                                    name: name,
                                    colorName1: color1,
                                    colorName2: color2,
                                    matchPercentage: percentage)
                }
            )
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Camera")
            }
            .tag(0)
             
            // SECONDO TAB: Guardaroba
            GuardarobaView(
                outfits: $outfits,
                deleteAction: deleteOutfit,
                renameAction: renameOutfit
            )
            .tabItem {
                Image(systemName: "tshirt")
                Text("Wardrobe")
            }
            .tag(1)
        }
        .tint(.white)
         
        .onAppear {
            self.loadOutfits() // carica i dati all'avvio
        }
    }
     
     
    // LOGICA DI GESTIONE DEI DATI
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // Salva un'immagine sul disco e restituisce il nome del file
    private func saveImageAndGetName(image: UIImage) -> String? {
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                return fileName
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        return nil
    }

    private func saveOutfit(image1: UIImage, image2: UIImage, name: String, colorName1: String, colorName2: String, matchPercentage: String) {
        guard let fileName1 = saveImageAndGetName(image: image1),
              let fileName2 = saveImageAndGetName(image: image2) else {
            return
        }
        
        // crea il nuovo Outfit con i dati completi
        let newOutfit = Outfit(imageFileName1: fileName1,
                               imageFileName2: fileName2,
                               name: name,
                               colorName1: colorName1,
                               colorName2: colorName2,
                               matchPercentage: matchPercentage)
        
        var savedOutfits = self.outfits
        savedOutfits.append(newOutfit)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedOutfits)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            
            self.outfits = savedOutfits
        } catch {
            print("Error encoding outfits: \(error)")
        }
    }
    
    // carica gli Outfit salvati
    private func loadOutfits() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let loadedOutfits = try decoder.decode([Outfit].self, from: data)
            self.outfits = loadedOutfits
        } catch {
            print("Errore nella decodifica degli outfit: \(error)")
        }
    }
    
    // elimina un Outfit
    func deleteOutfit(outfitToDelete: Outfit) {
        if let index = outfits.firstIndex(where: { $0.id == outfitToDelete.id }) {
            self.outfits.remove(at: index)
        }
        
        let fm = FileManager.default
        let directory = getDocumentsDirectory()
        
        let fileURL1 = directory.appendingPathComponent(outfitToDelete.imageFileName1)
        let fileURL2 = directory.appendingPathComponent(outfitToDelete.imageFileName2)
        
        try? fm.removeItem(at: fileURL1)
        try? fm.removeItem(at: fileURL2)

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.outfits)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Encoding error after deletion: \(error)")
        }
    }
    
    // rinomina un Outfit 
    func renameOutfit(outfitToRename: Outfit, newName: String) {
        guard let index = outfits.firstIndex(where: { $0.id == outfitToRename.id }) else { return }
        
        self.outfits[index].name = newName
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.outfits)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Encoding error after renaming: \(error)")
        }
    }
}


// PREVIEW
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
