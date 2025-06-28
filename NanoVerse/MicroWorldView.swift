//
//  MicroWorldView.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI
import RealityKit
import AVFoundation
import Combine

/// Main 3D scene coordinator for the microscopic world
class MicroWorldCoordinator: ObservableObject {
    @Published var isSpeaking = false
    @Published var isLoading = false
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var cancellable: EventSubscription?
    
    /// Reusable function to speak any text using text-to-speech
    func speak(_ text: String, isImmersiveSpaceOpen: Bool) {
        // Only speak if the immersive space is open
        guard isImmersiveSpaceOpen else {
            print("🔇 Speech disabled - immersive space not open")
            return
        }
        
        // Safety check for empty text
        guard !text.isEmpty else {
            print("🔇 Speech disabled - empty text")
            return
        }
        
        do {
            // Stop any current speech
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
            
            // Create speech utterance
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 0.8
            
            // Speak the text
            isSpeaking = true
            speechSynthesizer.speak(utterance)
            
            // Reset speaking state when finished
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.isSpeaking = false
            }
            
            print("🔊 Speaking: \(text)")
        } catch {
            print("❌ Speech synthesis error: \(error)")
            isSpeaking = false
        }
    }
    
    /// Setup the 3D scene with biological model
    func setup(content: RealityViewContent, scene: AppModel.MicroWorldScene) {
        print("🚀 RealityView setup started for scene: \(scene.rawValue)")
        
        // Choose model name based on current scene
        let modelName: String
        switch scene {
        case .cell:
            modelName = "whiteBloodCell"
        case .dna:
            modelName = "dnaStrand"
        case .virus:
            modelName = "virus"
        }

        print("🔍 Attempting to load model: \(modelName)")
        
        // Set loading state
        isLoading = true
        
        // Check if the model file exists in the bundle
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "usdz") {
            print("✅ Found model file at: \(modelURL)")
        } else {
            print("❌ Model file not found in bundle: \(modelName).usdz")
        }
        
        // Load the actual model
        Task { @MainActor in
            // Add a large black sphere as background
            let backgroundMesh = MeshResource.generateSphere(radius: 5)
            let blackMaterial = SimpleMaterial(color: .black, isMetallic: false)
            let backgroundEntity = ModelEntity(mesh: backgroundMesh, materials: [blackMaterial])
            backgroundEntity.name = "blackBackgroundSphere"
            backgroundEntity.position = [0, 0, 0]
            
            let backgroundAnchor = AnchorEntity(world: .zero)
            backgroundAnchor.addChild(backgroundEntity)
            content.add(backgroundAnchor)
            
            do {
                print("📦 Loading \(modelName) model...")
                let entity = try await Entity(named: modelName, in: Bundle.main)
                print("📦 Entity loaded: \(entity.name)")
                
                // Set the entity name and position
                entity.name = modelName
                entity.position = [0, 0, -1.5] // Move further back but still visible
                entity.transform.scale = [0.5, 0.5, 0.5] // Make it larger
                
                // Create an anchor and add the entity
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(entity)
                content.add(anchor)
                
                print("✅ \(modelName) model added to scene at position: \(entity.position) with scale: \(entity.transform.scale)")

                // Set up rotation animation
                cancellable = content.subscribe(to: SceneEvents.Update.self) { [weak entity] event in
                    guard let entity = entity else { return }
                    let rotationSpeed = Float(0.2)
                    let deltaTime = Float(event.deltaTime)
                    let angle = rotationSpeed * deltaTime
                    entity.transform.rotation *= simd_quatf(angle: angle, axis: [0, 1, 0])
                }
                
                print("✅ \(modelName) model loaded successfully and rotating!")
                isLoading = false
            } catch {
                print("❌ Failed to load \(modelName) model: \(error)")
                print("📝 Falling back to sphere model...")
                createFallbackSphere(content: content)
                isLoading = false
            }
        }
    }
    
    /// Fallback function to create a sphere if model loading fails
    private func createFallbackSphere(content: RealityViewContent) {
        print("🔧 Creating fallback sphere...")
        
        Task { @MainActor in
            // Create a smaller sphere to represent a white blood cell
            let cellMesh = MeshResource.generateSphere(radius: 0.1)
            
            // Create a subtle white material for the cell
            let cellMaterial = SimpleMaterial(color: .white, isMetallic: false)
            
            // Create the cell entity
            let cellEntity = ModelEntity(mesh: cellMesh, materials: [cellMaterial])
            cellEntity.name = "fallbackSphere"
            
            // Position the cell 1 meter in front of the user
            cellEntity.position = [0, 0, -1.0]
            
            // Create an anchor and add the cell
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(cellEntity)
            content.add(anchor)
            
            print("✅ Fallback sphere created at position: \(cellEntity.position)")
            
            // Subscribe to scene updates for continuous rotation
            cancellable = content.subscribe(to: SceneEvents.Update.self) { [weak cellEntity] event in
                guard let cellEntity = cellEntity else { return }
                
                // Rotate the cell around the Y-axis
                let rotationSpeed = Float(0.3) // radians per second
                let deltaTime = Float(event.deltaTime)
                let angle = rotationSpeed * deltaTime
                
                // Apply rotation
                cellEntity.transform.rotation *= simd_quatf(angle: angle, axis: [0, 1, 0])
            }
            
            isLoading = false
        }
    }
    
    deinit {
        cancellable?.cancel()
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

/// Main view for the microscopic world immersive scene
struct MicroWorldView: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    @StateObject private var coordinator = MicroWorldCoordinator()
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        ZStack {
            // 3D RealityKit scene: Minimal test
            RealityView { content in
                print("🎬 RealityView content closure called!")
                
                coordinator.setup(content: content, scene: appModel.currentScene)
            }
            .id(appModel.currentScene)

            // Overlay UI
            VStack {
                // Debug info at the top
                VStack(spacing: 4) {
                    Text("Debug Info")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                    
                    Text("Scene: \(appModel.currentScene.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.white)
                    
                    Text("Loading: \(coordinator.isLoading ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundStyle(.white)
                    
                    Text("Speaking: \(coordinator.isSpeaking ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundStyle(.white)
                    
                    Text("Immersive Space: \(appModel.immersiveSpaceState == .open ? "Open" : "Closed")")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                .padding(8)
                .background(.black.opacity(0.7))
                .cornerRadius(8)
                .padding(.top, 50)
                
                Spacer()
                
                // Top status bar
                HStack {
                    Text(appModel.currentScene.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Loading indicator
                    if coordinator.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("Loading...")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.6))
                        .cornerRadius(16)
                    }
                    
                    // Speaking indicator
                    if coordinator.isSpeaking {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.green)
                            Text("Speaking...")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.6))
                        .cornerRadius(16)
                    }
                }
                .padding()
                
                Spacer()
                
                // Scene switching buttons
                HStack(spacing: 12) {
                    ForEach(AppModel.MicroWorldScene.allCases, id: \.self) { scene in
                        Button {
                            appModel.currentScene = scene
                        } label: {
                            Text(scene.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(appModel.currentScene == scene ? .white : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(appModel.currentScene == scene ? .blue : .black.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Bottom controls
                HStack {
                    Button {
                        // Safety check to ensure we have a valid scene
                        let sceneDescription = appModel.currentScene.description
                        coordinator.speak(sceneDescription, isImmersiveSpaceOpen: appModel.immersiveSpaceState == .open)
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Narrate")
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.blue)
                        .cornerRadius(12)
                    }
                    .disabled(coordinator.isSpeaking)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            appModel.immersiveSpaceState = .open
            // Only play narration if immersive space is open
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let sceneDescription = appModel.currentScene.description
                coordinator.speak(sceneDescription, isImmersiveSpaceOpen: appModel.immersiveSpaceState == .open)
            }
        }
        .onDisappear {
            appModel.immersiveSpaceState = .closed
        }
    }
}

#Preview(immersionStyle: .full) {
    MicroWorldView(modelManager: NanoVerseModelManager())
} 