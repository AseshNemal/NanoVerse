//
//  Models.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import Foundation
import RealityKit
import SwiftUI

/// Wrapper for a loaded model entity and its metadata
struct ModelEntityWrapper: Identifiable, Equatable {
    let id: UUID
    var name: String
    var url: URL?
    var entity: ModelEntity
    var position: SIMD3<Float>
    var scale: SIMD3<Float>
    var rotation: SIMD3<Float> // Euler angles in radians
    var isSelected: Bool
    
    static func == (lhs: ModelEntityWrapper, rhs: ModelEntityWrapper) -> Bool {
        lhs.id == rhs.id
    }
}

/// ObservableObject to manage all models in the scene
class NanoVerseModelManager: ObservableObject {
    @Published var models: [ModelEntityWrapper] = []
    @Published var selectedModelID: UUID?
    @Published var errorMessage: String? = nil
    @Published var currentScene: AppModel.MicroWorldScene = .cell
    
    // Callback for when models change
    var onModelsChanged: (() -> Void)?
    
    // Default model names in the app bundle
    let defaultModelNames = ["whiteBloodCell", "dnaStrand", "virus"]
    
    init() {
        loadDefaultModels()
        loadPersistedModels()
    }
    
    /// Load default models from the app bundle
    func loadDefaultModels() {
        for name in defaultModelNames {
            if let entity = try? ModelEntity.load(named: name) {
                // Try to use as ModelEntity, or search children
                let modelEntity: ModelEntity?
                if let asModel = entity as? ModelEntity {
                    modelEntity = asModel
                } else {
                    modelEntity = entity.findModelEntity()
                }
                if let modelEntity = modelEntity {
                    let wrapper = ModelEntityWrapper(
                        id: UUID(),
                        name: name,
                        url: nil,
                        entity: modelEntity,
                        position: [Float.random(in: -0.2...0.2), 0, -0.5],
                        scale: [0.5, 0.5, 0.5],
                        rotation: [0, 0, 0],
                        isSelected: false
                    )
                    models.append(wrapper)
                } else {
                    print("❌ Could not find ModelEntity in \(name)")
                }
            } else {
                print("❌ Could not load model named: \(name)")
            }
        }
        if let first = models.first { selectedModelID = first.id }
    }
    
    /// Load persisted model URLs (not implemented in this stub)
    func loadPersistedModels() {
        // TODO: Load from UserDefaults/FileManager
    }
    
    /// Add a new model from a local file URL with improved error handling
    func addModel(from url: URL) async {
        do {
            print("📦 Loading model from: \(url)")
            
            // Basic file existence check only
            guard FileManager.default.fileExists(atPath: url.path) else {
                await MainActor.run { self.errorMessage = "File does not exist at the specified path." }
                return
            }
            
            // Try to load the entity without strict validation
            print("🔄 Attempting to load entity...")
            let entity = try await Entity.load(contentsOf: url)
            print("✅ Entity loaded successfully: \(entity.name)")
            print("📋 Entity type: \(type(of: entity))")
            print("📋 Entity children count: \(entity.children.count)")
            
            // Log entity hierarchy for debugging
            if entity.children.count > 0 {
                print("🔍 Entity hierarchy:")
                for (index, child) in entity.children.enumerated() {
                    print("  Child \(index): \(type(of: child)) - \(child.name)")
                    if child.children.count > 0 {
                        for (subIndex, subChild) in child.children.enumerated() {
                            print("    Sub-child \(subIndex): \(type(of: subChild)) - \(subChild.name)")
                        }
                    }
                }
            }
            
            // Create a ModelEntity wrapper for any type of entity
            print("🔄 Creating ModelEntity wrapper...")
            let wrapperEntity = ModelEntity()
            wrapperEntity.name = "ImportedModel_\(url.lastPathComponent)"
            
            // Add the loaded entity as a child
            wrapperEntity.addChild(entity)
            
            print("✅ Created wrapper entity: \(wrapperEntity.name)")
            
            // Create wrapper
            let wrapper = ModelEntityWrapper(
                id: UUID(),
                name: url.lastPathComponent,
                url: url,
                entity: wrapperEntity,
                position: [0, 0, -0.5],
                scale: [0.5, 0.5, 0.5],
                rotation: [0, 0, 0],
                isSelected: false
            )
            
            await MainActor.run { 
                self.models.append(wrapper)
                self.selectedModelID = wrapper.id
                print("✅ Model added successfully: \(wrapper.name)")
                
                // Notify that models have changed
                self.onModelsChanged?()
            }
            
        } catch {
            print("❌ Failed to load model: \(error)")
            print("📋 Error details: \(error.localizedDescription)")
            
            // Try to provide more helpful error messages
            let errorMessage: String
            if error.localizedDescription.contains("not found") {
                errorMessage = "File not found or corrupted. Please check the file."
            } else if error.localizedDescription.contains("format") {
                errorMessage = "Unsupported file format. Try a different 3D model file."
            } else if error.localizedDescription.contains("permission") {
                errorMessage = "Permission denied. Please check file access."
            } else {
                errorMessage = "Failed to load model: \(error.localizedDescription)"
            }
            
            await MainActor.run { 
                self.errorMessage = errorMessage
            }
        }
    }
    
    /// Add a new model from a remote HTTPS URL
    func addModel(fromRemote url: URL) async {
        do {
            print("📥 Starting download from: \(url)")
            
            // Download the file
            let (tempURL, response) = try await URLSession.shared.download(from: url)
            
            // Validate the response
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run { self.errorMessage = "Invalid response from server." }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                await MainActor.run { self.errorMessage = "Server returned error: \(httpResponse.statusCode)" }
                return
            }
            
            print("✅ Download completed. Temp file: \(tempURL)")
            
            // Basic file existence check
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                await MainActor.run { self.errorMessage = "Downloaded file not found." }
                return
            }
            
            // Create a permanent copy in the app's documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = "imported_\(UUID().uuidString).usdz"
            let permanentURL = documentsDirectory.appendingPathComponent(fileName)
            
            try FileManager.default.copyItem(at: tempURL, to: permanentURL)
            print("💾 File copied to permanent location: \(permanentURL)")
            
            // Now try to load the model from the permanent location
            await addModel(from: permanentURL)
            
        } catch {
            print("❌ Download/import failed: \(error)")
            print("📋 Error details: \(error.localizedDescription)")
            
            // Try to provide more helpful error messages
            let errorMessage: String
            if error.localizedDescription.contains("network") {
                errorMessage = "Network error. Please check your internet connection."
            } else if error.localizedDescription.contains("timeout") {
                errorMessage = "Download timeout. Please try again."
            } else if error.localizedDescription.contains("not found") {
                errorMessage = "File not found on server. Please check the URL."
            } else {
                errorMessage = "Failed to download or import model: \(error.localizedDescription)"
            }
            
            await MainActor.run { 
                self.errorMessage = errorMessage
            }
        }
    }
    
    /// Remove a model by ID
    func removeModel(id: UUID) {
        models.removeAll { $0.id == id }
        if selectedModelID == id { selectedModelID = models.first?.id }
        
        // Notify that models have changed
        onModelsChanged?()
    }
    
    /// Remove all models
    func removeAllModels() {
        models.removeAll()
        selectedModelID = nil
        
        // Notify that models have changed
        onModelsChanged?()
    }
    
    /// Select a model by ID
    func selectModel(id: UUID) {
        selectedModelID = id
    }
    
    /// Update transform for a model
    func updateTransform(id: UUID, position: SIMD3<Float>? = nil, scale: SIMD3<Float>? = nil, rotation: SIMD3<Float>? = nil) {
        guard let idx = models.firstIndex(where: { $0.id == id }) else { return }
        
        // Update wrapper properties
        if let position = position { 
            models[idx].position = position 
        }
        if let scale = scale { 
            models[idx].scale = scale 
        }
        if let rotation = rotation { 
            models[idx].rotation = rotation 
        }
        
        // Apply changes to the actual ModelEntity
        let model = models[idx]
        model.entity.position = model.position
        model.entity.transform.scale = model.scale
        
        // Convert Euler angles to quaternion for rotation
        // Create quaternion from Euler angles (X, Y, Z order)
        let quaternion = simd_quatf(
            angle: model.rotation.y,
            axis: [0, 1, 0]
        ) * simd_quatf(
            angle: model.rotation.x,
            axis: [1, 0, 0]
        ) * simd_quatf(
            angle: model.rotation.z,
            axis: [0, 0, 1]
        )
        model.entity.transform.rotation = quaternion
        
        print("🔄 Updated transform for \(model.name): pos=\(model.position), scale=\(model.scale), rot=\(model.rotation)")
    }
    
    /// Validate if a file is a valid USDZ file
    private func validateUSDZFile(at url: URL) -> Bool {
        print("🔍 Validating file: \(url)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File does not exist at path: \(url.path)")
            return false
        }
        
        // Check file size (USDZ files should be at least a few KB)
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            print("📊 File size: \(fileSize) bytes")
            
            if fileSize == 0 {
                print("❌ File is empty")
                return false
            }
            
            if fileSize < 50 { // Very small files are likely not valid
                print("❌ File too small: \(fileSize) bytes")
                return false
            }
            
        } catch {
            print("❌ Error reading file attributes: \(error)")
            return false
        }
        
        // Check file extension (be more lenient)
        let fileExtension = url.pathExtension.lowercased()
        print("📄 File extension: \(fileExtension)")
        
        // Accept common 3D file extensions
        let validExtensions = ["usdz", "usd", "usda", "usdc"]
        if !validExtensions.contains(fileExtension) {
            print("❌ Invalid file extension: \(fileExtension)")
            return false
        }
        
        print("✅ File validation passed")
        return true
    }
    
    /// Clear the current error message
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    /// Clear error message after a delay
    func clearErrorMessageAfterDelay(_ delay: TimeInterval = 5.0) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await MainActor.run {
                self.errorMessage = nil
            }
        }
    }
}

extension Entity {
    /// Recursively search for a ModelEntity in the entity hierarchy
    func findModelEntity() -> ModelEntity? {
        if let model = self as? ModelEntity { return model }
        for child in children {
            if let found = child.findModelEntity() { return found }
        }
        return nil
    }
} 
