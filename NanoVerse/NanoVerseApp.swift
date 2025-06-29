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
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            DynamicNanoVerseView(modelManager: modelManager)
                .environment(appModel)
        }

        ImmersiveSpace(id: "NanoVerseImmersiveSpace") {
            DynamicNanoVerseImmersiveView(modelManager: modelManager)
                .environment(appModel)
                .environment(\.colorScheme, .dark)
        }
    }
}
