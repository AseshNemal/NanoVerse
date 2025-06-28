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
    func speak(_ text: String) {
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
        
        // First, let's add a simple test sphere to make sure RealityView is working
        Task { @MainActor in
            print("🎯 Creating test sphere...")
            
            // Create a simple red sphere as a test
            let testMesh = MeshResource.generateSphere(radius: 0.1)
            let testMaterial = SimpleMaterial(color: .red, isMetallic: false)
            let testEntity = ModelEntity(mesh: testMesh, materials: [testMaterial])
            testEntity.name = "testSphere"
            testEntity.position = [0, 0, -0.5] // Closer to the user
            
            let testAnchor = AnchorEntity(world: .zero)
            testAnchor.addChild(testEntity)
            content.add(testAnchor)
            
            print("✅ Test sphere added at position: \(testEntity.position)")
            
            // Now try to load the actual model
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
            // Create a sphere to represent a white blood cell
            let cellMesh = MeshResource.generateSphere(radius: 0.2)
            
            // Create a bright cyan material for the cell
            let cellMaterial = SimpleMaterial(color: .cyan, isMetallic: false)
            
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
    
    var body: some View {
        ZStack {
            // 3D RealityKit scene: Minimal test
            RealityView { content in
                print("🎬 RealityView content closure called!")

                // Add a simple red test cube
                let testMesh = MeshResource.generateBox(size: 0.3)
                let testMaterial = SimpleMaterial(color: .red, isMetallic: false)
                let testEntity = ModelEntity(mesh: testMesh, materials: [testMaterial])
                testEntity.position = [0, 0, -1.0]

                let testAnchor = AnchorEntity(world: .zero)
                testAnchor.addChild(testEntity)
                content.add(testAnchor)

                print("✅ Test cube added to RealityView at position: \(testEntity.position)")
            }
            .id(modelManager.currentScene) // Force recreation when scene changes

            // Overlay UI
            VStack {
                // Debug info at the top
                VStack(spacing: 4) {
                    Text("Debug Info")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                    
                    Text("Scene: \(modelManager.currentScene.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.white)
                    
                    Text("Loading: \(coordinator.isLoading ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundStyle(.white)
                    
                    Text("Speaking: \(coordinator.isSpeaking ? "Yes" : "No")")
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
                    Text(modelManager.currentScene.rawValue)
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
                            modelManager.currentScene = scene
                        } label: {
                            Text(scene.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(modelManager.currentScene == scene ? .white : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(modelManager.currentScene == scene ? .blue : .black.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Bottom controls
                HStack {
                    Button {
                        coordinator.speak(modelManager.currentScene.description)
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
            // Optionally, keep the narration logic
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                coordinator.speak(modelManager.currentScene.description)
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    MicroWorldView(modelManager: NanoVerseModelManager())
} 