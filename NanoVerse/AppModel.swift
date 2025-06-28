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
}
