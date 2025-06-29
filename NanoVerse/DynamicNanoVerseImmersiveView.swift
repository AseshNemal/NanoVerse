//
//  DynamicNanoVerseImmersiveView.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI
import RealityKit

struct DynamicNanoVerseImmersiveView: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    
    var body: some View {
        MicroWorldView(modelManager: modelManager)
            .ignoresSafeArea()
            .environment(\.colorScheme, .dark)
    }
} 