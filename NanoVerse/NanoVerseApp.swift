//
//  NanoVerseApp.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI

@main
struct NanoVerseApp: App {
    @StateObject private var modelManager = NanoVerseModelManager()
    
    var body: some Scene {
        // Main window for app controls and navigation
        WindowGroup {
            DynamicNanoVerseView(modelManager: modelManager)
        }
        
        // Immersive space for the 3D microscopic world
        ImmersiveSpace(id: "NanoVerseImmersiveSpace") {
            DynamicNanoVerseImmersiveView(modelManager: modelManager)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
