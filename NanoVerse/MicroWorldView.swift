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
import RealityKitContent

/// Main 3D scene coordinator for the microscopic world
class MicroWorldCoordinator: ObservableObject {
    @Published var isSpeaking = false
    @Published var isLoading = false
    @Published var isPaused = false
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var cancellable: EventSubscription?
    private var currentModelEntity: ModelEntity?
    private var modelManager: NanoVerseModelManager?
    
    /// Set the model manager reference
    func setModelManager(_ manager: NanoVerseModelManager) {
        self.modelManager = manager
    }
    
    /// Reusable function to speak any text using text-to-speech
    func speak(_ text: String, isImmersiveSpaceOpen: Bool, voiceEnabled: Bool = true) {
        // Only speak if the immersive space is open and voice is enabled
        guard isImmersiveSpaceOpen && voiceEnabled else {
            print("🔇 Speech disabled - immersive space not open or voice disabled")
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
            do {
                print("📦 Loading \(modelName) model...")
                let entity = try await Entity(named: modelName, in: Bundle.main)
                print("📦 Entity loaded: \(entity.name)")
                
                // Set the entity name and position
                entity.name = modelName
                entity.position = [0, 0, -1.5] // Move further back but still visible
                entity.transform.scale = [0.01, 0.01, 0.01] // Make it larger
                
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
                
                // Find the actual ModelEntity for transform controls
                if let modelEntity = entity as? ModelEntity {
                    currentModelEntity = modelEntity
                } else if let foundModelEntity = entity.findModelEntity() {
                    currentModelEntity = foundModelEntity
                } else {
                    print("⚠️ Could not find ModelEntity for transform controls")
                }
                
                // Update the model manager wrapper data to reflect the actual model state
                if let modelManager = modelManager {
                    updateModelManagerData(modelManager: modelManager)
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
            currentModelEntity = cellEntity
            
            // Update the model manager wrapper data to reflect the actual model state
            if let modelManager = modelManager {
                updateModelManagerData(modelManager: modelManager)
            }
        }
    }
    
    /// Apply transform to the current model
    func applyTransform(position: SIMD3<Float>? = nil, scale: SIMD3<Float>? = nil, rotation: SIMD3<Float>? = nil) {
        guard let entity = currentModelEntity else {
            print("❌ No current model entity to transform")
            return
        }
        
        if let position = position {
            entity.position = position
            print("🔄 Applied position: \(position)")
        }
        
        if let scale = scale {
            entity.transform.scale = scale
            print("🔄 Applied scale: \(scale)")
        }
        
        if let rotation = rotation {
            // Convert Euler angles to quaternion
            let quaternion = simd_quatf(
                angle: rotation.y,
                axis: [0, 1, 0]
            ) * simd_quatf(
                angle: rotation.x,
                axis: [1, 0, 0]
            ) * simd_quatf(
                angle: rotation.z,
                axis: [0, 0, 1]
            )
            entity.transform.rotation = quaternion
            print("🔄 Applied rotation: \(rotation)")
        }
        
        // Update the model manager wrapper data to reflect the actual model state
        if let modelManager = modelManager {
            updateModelManagerData(modelManager: modelManager)
        }
    }
    
    /// Update the model manager wrapper data to match the actual model
    private func updateModelManagerData(modelManager: NanoVerseModelManager) {
        guard let entity = currentModelEntity else { 
            print("❌ No current model entity to update wrapper data")
            return 
        }
        
        print("🔍 Looking for wrapper with name: \(entity.name)")
        print("📋 Available models in manager: \(modelManager.models.map { $0.name })")
        
        // Find the corresponding wrapper in the model manager
        if let wrapperIndex = modelManager.models.firstIndex(where: { $0.name == entity.name }) {
            print("✅ Found wrapper at index \(wrapperIndex) for model: \(entity.name)")
            
            // Update the wrapper with the actual model's transform
            modelManager.models[wrapperIndex].position = entity.position
            modelManager.models[wrapperIndex].scale = entity.transform.scale
            
            // Convert quaternion back to Euler angles for the wrapper
            let quaternion = entity.transform.rotation
            // Extract Y rotation (simplified - you might want more complex conversion)
            let w = quaternion.vector.w
            let y = quaternion.vector.y
            let x = quaternion.vector.x
            let z = quaternion.vector.z
            
            let numerator = 2 * (w * y + x * z)
            let denominator = 1 - 2 * (y * y + z * z)
            let yRotation = atan2(numerator, denominator)
            
            modelManager.models[wrapperIndex].rotation = [0, yRotation, 0]
            
            // Ensure the current scene model is selected for transform controls
            modelManager.selectedModelID = modelManager.models[wrapperIndex].id
            
            print("📊 Updated wrapper data: pos=\(entity.position), scale=\(entity.transform.scale)")
            print("🎯 Set selected model ID to: \(modelManager.models[wrapperIndex].id)")
        } else {
            print("❌ No wrapper found for model: \(entity.name)")
            print("💡 Creating a new wrapper for the current scene model...")
            
            // Create a new wrapper for the current scene model if it doesn't exist
            let newWrapper = ModelEntityWrapper(
                id: UUID(),
                name: entity.name,
                url: nil,
                entity: entity,
                position: entity.position,
                scale: entity.transform.scale,
                rotation: [0, 0, 0], // Will be updated below
                isSelected: false
            )
            
            // Convert quaternion to Euler angles
            let quaternion = entity.transform.rotation
            let w = quaternion.vector.w
            let y = quaternion.vector.y
            let x = quaternion.vector.x
            let z = quaternion.vector.z
            
            let numerator = 2 * (w * y + x * z)
            let denominator = 1 - 2 * (y * y + z * z)
            let yRotation = atan2(numerator, denominator)
            
            var updatedWrapper = newWrapper
            updatedWrapper.rotation = [0, yRotation, 0]
            
            modelManager.models.append(updatedWrapper)
            modelManager.selectedModelID = updatedWrapper.id
            
            print("✅ Created new wrapper for \(entity.name) with ID: \(updatedWrapper.id)")
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
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var showDashboard = false
    
    var body: some View {
        ZStack {
            // Use RealityView with custom scene setup
            RealityView { content in
                print("🎬 RealityView content closure called!")
                
                // Create a completely isolated environment
                createIsolatedEnvironment(content: content)
                
                // Load the model
                coordinator.setup(content: content, scene: appModel.currentScene)
            } update: { content in
                // Handle updates if needed
                print("🔄 RealityView update called!")
            }
            .id(appModel.currentScene)
            .environment(\.colorScheme, .dark) // Force dark environment

            // Overlay UI
            VStack {
                // Floating Dashboard Toggle Button
                HStack {
                    Spacer()
                    
                    Button {
                        showDashboard.toggle()
                    } label: {
                        Image(systemName: showDashboard ? "xmark.circle.fill" : "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
            }
            
            // Dashboard Overlay
            if showDashboard {
                DashboardOverlay(
                    appModel: appModel,
                    coordinator: coordinator,
                    modelManager: modelManager,
                    dismissImmersiveSpace: dismissImmersiveSpace
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            appModel.immersiveSpaceState = .open
            appModel.sharedCoordinator = coordinator
            coordinator.setModelManager(modelManager)
            print("🎬 MicroWorldView appeared with scene: \(appModel.currentScene.rawValue)")
            print("🎤 Current voice message: \(appModel.currentVoiceMessage)")
            // Only play narration if immersive space is open
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let voiceMessage = appModel.currentVoiceMessage
                coordinator.speak(voiceMessage, isImmersiveSpaceOpen: appModel.immersiveSpaceState == .open, voiceEnabled: appModel.voiceEnabled)
            }
        }
        .onChange(of: appModel.currentScene) { oldScene, newScene in
            print("🔄 Scene changed from \(oldScene.rawValue) to \(newScene.rawValue)")
            print("🎤 New voice message: \(appModel.currentVoiceMessage)")
        }
        .onDisappear {
            appModel.immersiveSpaceState = .closed
        }
    }
    
    /// Create a completely isolated environment that blocks the room
    private func createIsolatedEnvironment(content: RealityViewContent) {
        print("🌑 Creating isolated environment with black background...")
        Task { @MainActor in
            // Method 1: Create a large black sphere to block the room view
            let blackSphereMesh = MeshResource.generateSphere(radius: 100.0)
            let blackMaterial = SimpleMaterial(color: .black, isMetallic: false)
            let blackSphere = ModelEntity(mesh: blackSphereMesh, materials: [blackMaterial])
            blackSphere.name = "BlackBackground"
            
            // Add the black sphere to the scene
            content.add(blackSphere)
            print("✅ Black background sphere created and added to scene")
            
            // Method 2: Try to load the SkyDome from RealityKitContent bundle
            if let skyDome = try? await Entity(named: "SkyDome", in: realityKitContentBundle) {
               
                print("✅ SkyDome.usdz loaded from RealityKitContent bundle")
            } else {
                print("ℹ️ SkyDome.usdz not found in RealityKitContent bundle")
                
                // Fallback: try to load from main bundle
                if let skyDome = try? await Entity(named: "SkyDome", in: .main) {
                    
                    
                    print("✅ SkyDome.usdz loaded from main bundle")
                } else {
                    print("ℹ️ SkyDome.usdz not found in main bundle either")
                }
            }
            
            // Method 3: Create additional black walls to ensure complete room blocking
            let wallMaterial = SimpleMaterial(color: .black, isMetallic: false)
            
            // Create floor
            let floorMesh = MeshResource.generatePlane(width: 200, depth: 200)
            let floor = ModelEntity(mesh: floorMesh, materials: [wallMaterial])
            floor.position = [0, -50, 0]
            content.add(floor)
            
            // Create ceiling
            let ceiling = ModelEntity(mesh: floorMesh, materials: [wallMaterial])
            ceiling.position = [0, 50, 0]
            ceiling.transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
            content.add(ceiling)
            
            // Create walls (4 walls around the user)
            let wallMesh = MeshResource.generatePlane(width: 200, height: 100)
            
            // Front wall
            let frontWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
            frontWall.position = [0, 0, -50]
            content.add(frontWall)
            
            // Back wall
            let backWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
            backWall.position = [0, 0, 50]
            backWall.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            content.add(backWall)
            
            // Left wall
            let leftWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
            leftWall.position = [-50, 0, 0]
            leftWall.transform.rotation = simd_quatf(angle: .pi/2, axis: [0, 1, 0])
            content.add(leftWall)
            
            // Right wall
            let rightWall = ModelEntity(mesh: wallMesh, materials: [wallMaterial])
            rightWall.position = [50, 0, 0]
            rightWall.transform.rotation = simd_quatf(angle: -.pi/2, axis: [0, 1, 0])
            content.add(rightWall)
            
            print("✅ Additional black walls created for complete environment isolation")
        }
    }
}

// Dashboard Overlay for Immersive View
struct DashboardOverlay: View {
    let appModel: AppModel
    let coordinator: MicroWorldCoordinator
    let modelManager: NanoVerseModelManager
    let dismissImmersiveSpace: DismissImmersiveSpaceAction
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("NanoVerse Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 12) {
                    if coordinator.isLoading {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            Text("Loading")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    if coordinator.isSpeaking {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.green)
                            Text("Speaking")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    if coordinator.isPaused {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Paused")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(.black.opacity(0.8))
            .cornerRadius(16)
            
            // Quick Actions
            VStack(spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Exit Scene Button
                    Button {
                        Task { @MainActor in
                            appModel.immersiveSpaceState = .inTransition
                            await dismissImmersiveSpace()
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            Text("Exit Scene")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(.red.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Change Scene Button
                    Button {
                        // Dismiss the dashboard to allow access to scene selection from main dashboard
                        // Users can then use the main dashboard's scene selection
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "cube.transparent.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("Change Scene")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(.blue.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Pause/Resume Button
                    Button {
                        coordinator.isPaused.toggle()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: coordinator.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text(coordinator.isPaused ? "Resume" : "Pause")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(.orange.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Narrate Button
                    Button {
                        let voiceMessage = appModel.currentVoiceMessage
                        coordinator.speak(voiceMessage, isImmersiveSpaceOpen: appModel.immersiveSpaceState == .open, voiceEnabled: appModel.voiceEnabled)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                            Text("Narrate")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(.green.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .disabled(coordinator.isSpeaking)
                }
            }
            .padding()
            .background(.black.opacity(0.8))
            .cornerRadius(16)
            
            // Current Scene Info
            VStack(spacing: 8) {
                Text("Current Scene: \(appModel.currentScene.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text(appModel.hasCustomVoiceMessage(for: appModel.currentScene) ? "Custom Voice Active" : "Default Voice")
                    .font(.caption)
                    .foregroundStyle(appModel.hasCustomVoiceMessage(for: appModel.currentScene) ? .green : .gray)
            }
            .padding()
            .background(.black.opacity(0.8))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
        .background(.black.opacity(0.9))
        .animation(.easeInOut(duration: 0.3), value: coordinator.isLoading)
        .animation(.easeInOut(duration: 0.3), value: coordinator.isSpeaking)
        .animation(.easeInOut(duration: 0.3), value: coordinator.isPaused)
    }
}

#Preview(immersionStyle: .full) {
    MicroWorldView(modelManager: NanoVerseModelManager())
} 
