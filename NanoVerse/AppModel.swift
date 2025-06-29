//
//  AppModel.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI

/// Maintains app-wide state and scene management
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "NanoVerseImmersiveSpace"
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    enum MicroWorldScene: String, CaseIterable {
        case cell = "Cell Scene"
        case dna = "DNA Scene"
        case virus = "Virus Scene"
        
        var description: String {
            switch self {
            case .cell:
                return "Welcome to NanoVerse. This is a white blood cell."
            case .dna:
                return "Welcome to NanoVerse. This is a DNA strand."
            case .virus:
                return "Welcome to NanoVerse. This is a virus particle."
            }
        }
    }
    
    var immersiveSpaceState = ImmersiveSpaceState.closed
    var currentScene: MicroWorldScene = .dna
    var voiceEnabled: Bool = true
    var customVoiceMessages: [MicroWorldScene: String] = [:]
    var sharedCoordinator: MicroWorldCoordinator?
    
    /// Get the voice message for the current scene
    var currentVoiceMessage: String {
        if let customMessage = customVoiceMessages[currentScene], !customMessage.isEmpty {
            return customMessage
        } else {
            return currentScene.description
        }
    }
    
    /// Add or update a custom voice message for a scene
    func setCustomVoiceMessage(_ message: String, for scene: MicroWorldScene) {
        customVoiceMessages[scene] = message
        print("🎤 Added custom voice for \(scene.rawValue): \(message)")
    }
    
    /// Remove custom voice message for a scene
    func removeCustomVoiceMessage(for scene: MicroWorldScene) {
        customVoiceMessages.removeValue(forKey: scene)
        print("🗑️ Removed custom voice for \(scene.rawValue)")
    }
    
    /// Check if a scene has a custom voice message
    func hasCustomVoiceMessage(for scene: MicroWorldScene) -> Bool {
        return customVoiceMessages[scene] != nil && !(customVoiceMessages[scene]?.isEmpty ?? true)
    }
}
