//
//  DynamicNanoVerseView.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI
import UniformTypeIdentifiers

struct DynamicNanoVerseView: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    @State private var showDocumentPicker = false
    @State private var remoteURLString = ""
    @State private var showImmersive = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Button(action: {
                        showImmersive = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 36))
                            Text("Start Immersive")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(18)
                        .shadow(radius: 8)
                    }
                    .padding(.top, 16)
                    Text("NanoVerse")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Import, manage, and interact with 3D models in visionOS")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    ModelImportControls(modelManager: modelManager, showDocumentPicker: $showDocumentPicker, remoteURLString: $remoteURLString)
                    
                    ModelListView(modelManager: modelManager)
                    
                    if let selected = modelManager.models.first(where: { $0.id == modelManager.selectedModelID }) {
                        ModelTransformControls(selected: selected, modelManager: modelManager)
                    }
                    
                    // Remove all models
                    Button(role: .destructive) {
                        modelManager.removeAllModels()
                    } label: {
                        Label("Remove All Models", systemImage: "trash.slash")
                    }
                    .padding(.top, 8)
                    
                    // Error message
                    if let error = modelManager.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Enter immersive space
                    Button {
                        showImmersive = true
                    } label: {
                        Label("Enter Immersive Space", systemImage: "arkit")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .navigationTitle("NanoVerse")
            .sheet(isPresented: $showImmersive) {
                DynamicNanoVerseImmersiveView(modelManager: modelManager)
            }
        }
    }
}

struct ModelImportControls: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    @Binding var showDocumentPicker: Bool
    @Binding var remoteURLString: String
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                showDocumentPicker = true
            } label: {
                Label("Select USDZ Model", systemImage: "plus.square.on.square")
            }
            .buttonStyle(.borderedProminent)
            .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.usdz]) { result in
                switch result {
                case .success(let url):
                    Task { await modelManager.addModel(from: url) }
                case .failure(let error):
                    modelManager.errorMessage = "Failed to import: \(error.localizedDescription)"
                }
            }
            
            TextField("Remote .usdz URL", text: $remoteURLString)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
            Button {
                guard let url = URL(string: remoteURLString), url.scheme == "https" else {
                    modelManager.errorMessage = "Enter a valid HTTPS URL."
                    return
                }
                Task { await modelManager.addModel(fromRemote: url) }
            } label: {
                Label("Import from URL", systemImage: "icloud.and.arrow.down")
            }
            .buttonStyle(.bordered)
        }
    }
}

struct ModelListView: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(modelManager.models) { model in
                    Button {
                        modelManager.selectModel(id: model.id)
                    } label: {
                        VStack {
                            Image(systemName: modelManager.selectedModelID == model.id ? "cube.fill" : "cube")
                                .font(.largeTitle)
                                .foregroundStyle(modelManager.selectedModelID == model.id ? .blue : .gray)
                            Text(model.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .padding(8)
                        .background(modelManager.selectedModelID == model.id ? .blue.opacity(0.15) : .clear)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ModelTransformControls: View {
    let selected: ModelEntityWrapper
    let modelManager: NanoVerseModelManager

    var body: some View {
        let scaleBinding = Binding<Double>(
            get: { Double(selected.scale.x) },
            set: { new in modelManager.updateTransform(id: selected.id, scale: [Float(new), Float(new), Float(new)]) }
        )
        let xBinding = Binding<Double>(
            get: { Double(selected.position.x) },
            set: { new in modelManager.updateTransform(id: selected.id, position: [Float(new), selected.position.y, selected.position.z]) }
        )
        let yBinding = Binding<Double>(
            get: { Double(selected.position.y) },
            set: { new in modelManager.updateTransform(id: selected.id, position: [selected.position.x, Float(new), selected.position.z]) }
        )
        let zBinding = Binding<Double>(
            get: { Double(selected.position.z) },
            set: { new in modelManager.updateTransform(id: selected.id, position: [selected.position.x, selected.position.y, Float(new)]) }
        )
        let rotYBinding = Binding<Double>(
            get: { Double(selected.rotation.y) },
            set: { new in modelManager.updateTransform(id: selected.id, rotation: [selected.rotation.x, Float(new), selected.rotation.z]) }
        )
        return VStack(spacing: 12) {
            Text("Transform: \(selected.name)")
                .font(.headline)
            HStack {
                Text("Scale")
                Slider(value: scaleBinding, in: 0.1...2.0)
                Text(String(format: "%.2f", selected.scale.x))
            }
            HStack {
                Text("X")
                Slider(value: xBinding, in: -1.0...1.0)
                Text(String(format: "%.2f", selected.position.x))
            }
            HStack {
                Text("Y")
                Slider(value: yBinding, in: -1.0...1.0)
                Text(String(format: "%.2f", selected.position.y))
            }
            HStack {
                Text("Z")
                Slider(value: zBinding, in: -2.0...0.0)
                Text(String(format: "%.2f", selected.position.z))
            }
            HStack {
                Text("Rotate Y")
                Slider(value: rotYBinding, in: 0...(.pi*2))
                Text(String(format: "%.2f", selected.rotation.y))
            }
            Button(role: .destructive) {
                modelManager.removeModel(id: selected.id)
            } label: {
                Label("Remove Model", systemImage: "trash")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
} 