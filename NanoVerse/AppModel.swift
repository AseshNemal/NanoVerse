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
        case imported = "Imported Model"
        
        var description: String {
            switch self {
            case .cell:
                return "Welcome to the White Blood Cell scene. You're observing a neutrophil, your immune system's first responder. This 12-15 micrometer cell has three hunting strategies: chasing invaders at high speed, casting DNA nets to trap bacteria, and releasing chemical signals called cytokines. As you rotate the model, notice its unique multi-lobed nucleus that helps it squeeze through tiny blood vessels. The surface is covered with receptors that can detect over 1,000 different types of pathogens. During infections, your body can produce up to 500 billion of these defenders per day. Look closely to spot the tiny granules inside - they contain powerful antimicrobial weapons."

            case .dna:
                return "Welcome to the DNA scene. This double helix, just 2 nanometers wide, carries your genetic code in an elegant spiral. Each turn contains 10.5 base pairs and stretches 3.4 nanometers. As you rotate the model, notice the alternating major and minor grooves - these are where proteins dock to read the genetic code. The sugar-phosphate backbone on the outside protects the vital base pairs inside: adenine with thymine, and guanine with cytosine. If stretched out, the DNA from just one of your cells would reach 2 meters in length. Scientists recently discovered this molecule can even conduct electricity, leading to exciting possibilities in nano-electronics."

            case .virus:
                return "Welcome to the Virus scene. You're examining a virus particle measuring 100 nanometers - so tiny that 500 could fit across a human hair. Its protein shell uses perfect geometric symmetry: 20 triangular faces and 12 vertices. Count the spike proteins as you rotate - there are 50-70 of them, each able to unlock and enter specific cells. Inside, its genetic material is packed so tightly it experiences 20 times the pressure of a champagne bottle! This precise structure is now inspiring new medical technologies and drug delivery systems."

            case .imported:
                return "Welcome to NanoVerse. This is an imported 3D model."
            }
        }
    }
    
    var immersiveSpaceState = ImmersiveSpaceState.closed
    var currentScene: MicroWorldScene = .dna
    var selectedImportedModelID: UUID?
    var voiceEnabled: Bool = true
    var customVoiceMessages: [MicroWorldScene: String] = [:]
    var sharedCoordinator: MicroWorldCoordinator?
    
    /// Get the voice message for the current scene
    var currentVoiceMessage: String {
        if let customMessage = customVoiceMessages[currentScene], !customMessage.isEmpty {
            return customMessage
        } else {
            switch currentScene {
            case .imported:
                return "Welcome to NanoVerse. This is an imported 3D model."
            default:
                return currentScene.description
            }
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
