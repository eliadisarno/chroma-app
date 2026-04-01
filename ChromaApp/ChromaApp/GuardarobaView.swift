// GuardarobaView.swift

import SwiftUI
import UIKit

struct GuardarobaView: View {
    
    // dati e azioni da MainView
    @Binding var outfits: [Outfit]              // array di outfit
    let deleteAction: (Outfit) -> Void          // funzione per eliminare
    let renameAction: (Outfit, String) -> Void  // funzione per rinominare
    
    // stati interni della Vista
    @State private var showingDetailSheet = false
    @State private var selectedOutfit: Outfit?
    @State private var showingDeleteAlert = false
    @State private var showingRenameAlert = false
    @State private var newOutfitName: String = ""
    
    // funzione helper per caricare l'immagine dal nome del file
    private func loadImage(fileName: String) -> UIImage? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = paths[0]
        let fileURL = directory.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            
            List {
                
                Section {
                    // titolo fisso
                    Text("Wardrobe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .listRowBackground(Color.clear) // Rendi trasparente lo sfondo della riga
                        .padding(.top, 10)
                        
                    
                    // etichetta fissa outfit + contatore
                    HStack {
                        Text("Outfits")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(outfits.count) saved combination")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 5)
                    .listRowBackground(Color.clear)
                }
                .listRowSeparator(.hidden) // nasconde il separatore per la sezione titolo
                
                // sezione lista con gli outfit
                Section {
                    ForEach(outfits) { outfit in
                        OutfitListRow(outfit: outfit, loadImage: loadImage)
                            .contentShape(Rectangle()) // rende l'intera riga cliccabile
                            .onTapGesture {
                                self.selectedOutfit = outfit
                                self.showingDetailSheet = true
                            }
                    }
                }
                .listStyle(.plain)
            }
            // sfondo scuro per l'intera vista
            .background(Color.black.opacity(0.93).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
        }
       
        .sheet(isPresented: $showingDetailSheet) {
            if let outfit = selectedOutfit {
                OutfitDetailSheet(
                    outfit: outfit,
                    loadImage: loadImage,
                    onDelete: {
                        self.showingDetailSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.showingDeleteAlert = true }
                    },
                    onRename: {
                        self.newOutfitName = outfit.name
                        self.showingDetailSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.showingRenameAlert = true }
                    },
                    onClose: {
                        self.showingDetailSheet = false
                    }
                )
            }
        }
        // alert per eliminazione
        .alert(isPresented: $showingDeleteAlert) {
            let outfit = selectedOutfit ?? outfits.first!
            return Alert(
                title: Text("Delete Outfit"),
                message: Text("Are you sure you want to delete '\(outfit.name)'?"),
                primaryButton: .destructive(Text("Delete")) {
                    self.deleteAction(outfit)
                    self.selectedOutfit = nil
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        // alert per rinomina
        .alert("Rename Outfit", isPresented: $showingRenameAlert) {
            TextField("New name", text: $newOutfitName)
            Button("Rename") {
                if let outfit = selectedOutfit {
                    self.renameAction(outfit, newOutfitName)
                }
                self.selectedOutfit = nil
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a new name for '\(selectedOutfit?.name ?? "this outfit")'.")
        }
    }
}

struct OutfitListRow: View {
    let outfit: Outfit
    let loadImage: (String) -> UIImage?
    
    var body: some View {
        HStack(spacing: 15) {
            
            // thumbnail del primo capo
            Group {
                if let uiImage = loadImage(outfit.imageFileName1) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(Image(systemName: "hanger").foregroundColor(.gray))
                }
            }
            .frame(width: 45, height: 45) // dimensione piccola e fissa
            .clipShape(Circle()) // forma circolare
            
            // nome dell'outfit
            Text(outfit.name)
                .font(.body)
                .lineLimit(1)
            
            Spacer()
            
            // indicatore
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .listRowBackground(Color.white.opacity(0.1))
        .foregroundColor(.white) // rende il testo bianco su sfondo scuro
    }
}

struct OutfitDetailSheet: View {
    let outfit: Outfit
    let loadImage: (String) -> UIImage?
    let onDelete: () -> Void
    let onRename: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(outfit.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // immagini dell'outfit
                HStack(spacing: 10) {
                    if let uiImage1 = loadImage(outfit.imageFileName1) {
                        Image(uiImage: uiImage1)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(15)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 200).cornerRadius(15)
                    }
                    if let uiImage2 = loadImage(outfit.imageFileName2) {
                        Image(uiImage: uiImage2)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(15)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 200).cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                
                // Sezione Dettagli Analisi
                List {
                    Section("Analysis Details") {
                        // Nome dell'Outfit
                        HStack {
                            Image(systemName: "tag.fill").foregroundColor(.orange)
                            Text("Outfit name:")
                            Spacer()
                            Text(outfit.name)
                        }
                        // Dettagli Colore
                        HStack {
                            Image(systemName: "circle.fill").foregroundColor(.blue)
                            Text("Item 1 (Color):")
                            Spacer()
                            Text(outfit.colorName1)
                        }
                        HStack {
                            Image(systemName: "circle.fill").foregroundColor(.blue)
                            Text("Item 2 (Color):")
                            Spacer()
                            Text(outfit.colorName2)
                        }
                        
                        // Percentuale Abbinamento
                        HStack {
                            Image(systemName: "heart.fill").foregroundColor(.red)
                            Text("Matching percentage:")
                            Spacer()
                            // Mostra la percentuale salvata
                            Text(outfit.matchPercentage)
                                .fontWeight(.bold)
                                .foregroundColor(outfit.matchPercentage == "N/A" ? .gray : .blue)
                        }
                    }
                    
                    Section {
                        Button(action: onRename) {
                            HStack {
                                Text("Rename Outfit")
                                Spacer()
                            }
                        }
                        
                        // elimina (testo rosso)
                        Button(role: .destructive, action: onDelete) {
                            HStack {
                                Text("Delete Outfit")
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
            }
            .navigationTitle("Outfit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onClose()
                    }
                }
            }
        }
    }
}
