//
//  ContentView.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 30) {
            // App title and description
            VStack(spacing: 16) {
                Text("NanoVerse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Explore the microscopic world in immersive 3D")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Scene selection
            VStack(spacing: 16) {
                Text("Choose your microscopic adventure:")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                ForEach(AppModel.MicroWorldScene.allCases, id: \.self) { scene in
                    Button {
                        appModel.currentScene = scene
                    } label: {
                        HStack {
                            Text(scene.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            if appModel.currentScene == scene {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(appModel.currentScene == scene ? .blue.opacity(0.1) : .gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            
            // Enter immersive space button
            ToggleImmersiveSpaceButton()
                .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 400)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
