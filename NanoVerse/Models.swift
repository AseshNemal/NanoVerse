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
    
    /// Add a new model from a local file URL
    func addModel(from url: URL) async {
        do {
            let entity = try await Entity.load(contentsOf: url)
            guard let modelEntity = entity.findModelEntity() as? ModelEntity else {
                await MainActor.run { self.errorMessage = "File does not contain a ModelEntity." }
                return
            }
            let wrapper = ModelEntityWrapper(
                id: UUID(),
                name: url.lastPathComponent,
                url: url,
                entity: modelEntity,
                position: [0, 0, -0.5],
                scale: [0.5, 0.5, 0.5],
                rotation: [0, 0, 0],
                isSelected: false
            )
            await MainActor.run { self.models.append(wrapper) }
        } catch {
            await MainActor.run { self.errorMessage = "Failed to load model: \(error.localizedDescription)" }
        }
    }
    
    /// Add a new model from a remote HTTPS URL
    func addModel(fromRemote url: URL) async {
        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)
            await addModel(from: localURL)
        } catch {
            await MainActor.run { self.errorMessage = "Failed to download model: \(error.localizedDescription)" }
        }
    }
    
    /// Remove a model by ID
    func removeModel(id: UUID) {
        models.removeAll { $0.id == id }
        if selectedModelID == id { selectedModelID = models.first?.id }
    }
    
    /// Remove all models
    func removeAllModels() {
        models.removeAll()
        selectedModelID = nil
    }
    
    /// Select a model by ID
    func selectModel(id: UUID) {
        selectedModelID = id
    }
    
    /// Update transform for a model
    func updateTransform(id: UUID, position: SIMD3<Float>? = nil, scale: SIMD3<Float>? = nil, rotation: SIMD3<Float>? = nil) {
        guard let idx = models.firstIndex(where: { $0.id == id }) else { return }
        if let position = position { models[idx].position = position }
        if let scale = scale { models[idx].scale = scale }
        if let rotation = rotation { models[idx].rotation = rotation }
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
