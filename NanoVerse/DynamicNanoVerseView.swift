//
//  DynamicNanoVerseView.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct DynamicNanoVerseView: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    @State private var showDocumentPicker = false
    @State private var remoteURLString = ""
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var showAbout = false
    @State private var showSceneSelection = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(AppModel.self) private var appModel
    
    /// Test speech synthesis for custom voice messages
    private func testSpeech(_ text: String) {
        guard appModel.voiceEnabled else {
            print("🔇 Voice is disabled")
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        speechSynthesizer.speak(utterance)
        print("🎤 Testing speech: \(text)")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                mainContent
            }
            .navigationTitle("NanoVerse")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showSceneSelection) {
                SceneSelectionView(modelManager: modelManager)
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 40) {
            topDashboardBar
            mainEnterButton
            appDescription
            quickActionsSection
            modelImportControls
            modelListView
            customVoiceSection
            modelTransformControls
            removeAllButton
            errorMessage
            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
    
    @ViewBuilder
    private var topDashboardBar: some View {
        HStack {
            // App Logo/Title
            HStack(spacing: 12) {
                Image(systemName: "atom")
                    .font(.title)
                    .foregroundStyle(.blue)
                Text("NanoVerse")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Dashboard Buttons
            HStack(spacing: 16) {
                voiceToggleButton
                settingsButton
                helpButton
                aboutButton
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    @ViewBuilder
    private var voiceToggleButton: some View {
        Button {
            appModel.voiceEnabled.toggle()
        } label: {
            Image(systemName: appModel.voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.title3)
                .foregroundStyle(appModel.voiceEnabled ? .green : .red)
                .padding(8)
                .background(appModel.voiceEnabled ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .padding(8)
                .background(.blue.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var helpButton: some View {
        Button {
            showHelp = true
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .padding(8)
                .background(.green.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var aboutButton: some View {
        Button {
            showAbout = true
        } label: {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .padding(8)
                .background(.orange.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var mainEnterButton: some View {
        Button(action: {
            Task {
                await openImmersiveSpace(id: "NanoVerseImmersiveSpace")
            }
        }) {
            HStack {
                Image(systemName: "arkit")
                    .font(.system(size: 48))
                Text("Enter 3D Immersive Space")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(.blue)
            .foregroundStyle(.white)
            .cornerRadius(24)
            .shadow(radius: 12)
        }
        .padding(.top, 32)
    }
    
    @ViewBuilder
    private var appDescription: some View {
        VStack(spacing: 16) {
            Text("NanoVerse")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Import, manage, and interact with 3D models in visionOS")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(spacing: 24) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if appModel.immersiveSpaceState == .open {
                quickActionsGrid
            } else {
                startModelButton
            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    @ViewBuilder
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            exitSceneButton
            changeSceneButton
            resetSceneButton
            importModelButton
        }
    }
    
    @ViewBuilder
    private var exitSceneButton: some View {
        Button {
            Task { @MainActor in
                appModel.immersiveSpaceState = .inTransition
                await dismissImmersiveSpace()
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                Text("Exit Scene")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.red.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var changeSceneButton: some View {
        Button {
            showSceneSelection = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "cube.transparent.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                Text("Change Scene")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.blue.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var resetSceneButton: some View {
        Button {
            modelManager.removeAllModels()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text("Reset")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.orange.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var importModelButton: some View {
        Button {
            showDocumentPicker = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.square.on.square")
                    .font(.title)
                    .foregroundStyle(.green)
                Text("Import")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.green.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var startModelButton: some View {
        Button(action: {
            Task {
                await openImmersiveSpace(id: "NanoVerseImmersiveSpace")
            }
        }) {
            HStack(spacing: 24) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Model")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Begin your microscopic exploration")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
            }
            .padding(32)
            .background(.green.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.green.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var modelImportControls: some View {
        ModelImportControls(modelManager: modelManager, showDocumentPicker: $showDocumentPicker, remoteURLString: $remoteURLString)
            .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private var modelListView: some View {
        ModelListView(modelManager: modelManager)
            .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private var customVoiceSection: some View {
        VStack(spacing: 16) {
            Text("Custom Voice Messages")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(AppModel.MicroWorldScene.allCases, id: \.self) { scene in
                CustomVoiceRow(scene: scene, testSpeech: testSpeech)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var modelTransformControls: some View {
        if let selected = modelManager.models.first(where: { $0.id == modelManager.selectedModelID }) {
            ModelTransformControls(selected: selected, modelManager: modelManager, coordinator: appModel.sharedCoordinator)
                .padding(.vertical, 20)
        }
    }
    
    @ViewBuilder
    private var removeAllButton: some View {
        Button(role: .destructive) {
            modelManager.removeAllModels()
        } label: {
            Label("Remove All Models", systemImage: "trash.slash")
                .font(.body)
                .padding(16)
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if let error = modelManager.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .padding(24)
        }
    }
}

// Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        NavigationStack {
            List {
                Section("Scene Settings") {
                    Picker("Default Scene", selection: Binding(
                        get: { appModel.currentScene },
                        set: { appModel.currentScene = $0 }
                    )) {
                        ForEach(AppModel.MicroWorldScene.allCases, id: \.self) { scene in
                            Text(scene.rawValue).tag(scene)
                        }
                    }
                }
                
                Section("Audio Settings") {
                    Toggle("Enable Voice Narration", isOn: Binding(
                        get: { appModel.voiceEnabled },
                        set: { appModel.voiceEnabled = $0 }
                    ))
                    Toggle("Sound Effects", isOn: .constant(true))
                }
                
                Section("Display Settings") {
                    Toggle("Auto-rotate Models", isOn: .constant(true))
                    Toggle("Show Debug Info", isOn: .constant(false))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Help View
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Getting Started")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Choose a scene from the Quick Actions")
                            Text("2. Tap 'Enter 3D Immersive Space' to begin")
                            Text("3. Use hand gestures to interact with models")
                            Text("4. Tap 'Narrate' to hear descriptions")
                        }
                        .font(.body)
                    }
                    
                    Group {
                        Text("Controls")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Pinch to scale models")
                            Text("• Drag to rotate models")
                            Text("• Tap to select models")
                            Text("• Use voice commands for navigation")
                        }
                        .font(.body)
                    }
                    
                    Group {
                        Text("Supported Formats")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("• USDZ files (recommended)")
                        Text("• Remote HTTPS URLs")
                        Text("• Built-in biological models")
                    }
                    .font(.body)
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "atom")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("NanoVerse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Text("Explore the microscopic world in immersive 3D. NanoVerse brings biological models to life in visionOS, allowing you to interact with cells, DNA, and viruses in an unprecedented way.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("• Interactive 3D biological models")
                    Text("• Immersive spatial computing experience")
                    Text("• Audio narration and descriptions")
                    Text("• Custom model import support")
                    Text("• Real-time model manipulation")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModelImportControls: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    @Binding var showDocumentPicker: Bool
    @Binding var remoteURLString: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Error message display
            if let errorMessage = modelManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundStyle(.red)
                    Spacer()
                    Button {
                        modelManager.clearErrorMessage()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                .padding(12)
                .background(.red.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    modelManager.clearErrorMessageAfterDelay(8.0)
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    showDocumentPicker = true
                } label: {
                    Label("Select USDZ Model", systemImage: "plus.square.on.square")
                }
                .buttonStyle(.borderedProminent)
                .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.usdz, .data]) { result in
                    switch result {
                    case .success(let url):
                        Task { await modelManager.addModel(from: url) }
                    case .failure(let error):
                        modelManager.errorMessage = "Failed to import: \(error.localizedDescription)"
                    }
                }
                
                TextField("Remote .usdz URL", text: $remoteURLString)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                Button {
                    guard let url = URL(string: remoteURLString), url.scheme == "https" else {
                        modelManager.errorMessage = "Enter a valid HTTPS URL."
                        return
                    }
                    Task { await modelManager.addModel(fromRemote: url) }
                } label: {
                    Label("Import from URL", systemImage: "icloud.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct ModelListView: View {
    @ObservedObject var modelManager: NanoVerseModelManager
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(modelManager.models) { model in
                    Button {
                        modelManager.selectModel(id: model.id)
                    } label: {
                        VStack {
                            Image(systemName: modelManager.selectedModelID == model.id ? "cube.fill" : "cube")
                                .font(.largeTitle)
                                .foregroundStyle(modelManager.selectedModelID == model.id ? .blue : .gray)
                            Text(model.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .padding(8)
                        .background(modelManager.selectedModelID == model.id ? .blue.opacity(0.15) : .clear)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ModelTransformControls: View {
    let selected: ModelEntityWrapper
    let modelManager: NanoVerseModelManager
    let coordinator: MicroWorldCoordinator?

    var body: some View {
        let scaleBinding = Binding<Double>(
            get: { Double(selected.scale.x) },
            set: { new in 
                coordinator?.applyTransform(scale: [Float(new), Float(new), Float(new)])
            }
        )
        let xBinding = Binding<Double>(
            get: { Double(selected.position.x) },
            set: { new in 
                coordinator?.applyTransform(position: [Float(new), selected.position.y, selected.position.z])
            }
        )
        let yBinding = Binding<Double>(
            get: { Double(selected.position.y) },
            set: { new in 
                coordinator?.applyTransform(position: [selected.position.x, Float(new), selected.position.z])
            }
        )
        let zBinding = Binding<Double>(
            get: { Double(selected.position.z) },
            set: { new in 
                coordinator?.applyTransform(position: [selected.position.x, selected.position.y, Float(new)])
            }
        )
        let rotYBinding = Binding<Double>(
            get: { Double(selected.rotation.y) },
            set: { new in 
                coordinator?.applyTransform(rotation: [selected.rotation.x, Float(new), selected.rotation.z])
            }
        )
        
        return VStack(spacing: 16) {
            Text("Transform: \(selected.name)")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Scale Control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .foregroundStyle(.blue)
                        Text("Scale")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.2f", selected.scale.x))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: scaleBinding, in: 0.1...2.0, step: 0.01)
                        .accentColor(.blue)
                }
                
                // Position Controls
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "location")
                            .foregroundStyle(.green)
                        Text("Position")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("X")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 20)
                        Slider(value: xBinding, in: -2.0...2.0, step: 0.01)
                            .accentColor(.red)
                        Text(String(format: "%.2f", selected.position.x))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50)
                    }
                    
                    HStack {
                        Text("Y")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 20)
                        Slider(value: yBinding, in: -2.0...2.0, step: 0.01)
                            .accentColor(.green)
                        Text(String(format: "%.2f", selected.position.y))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50)
                    }
                    
                    HStack {
                        Text("Z")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 20)
                        Slider(value: zBinding, in: -3.0...0.0, step: 0.01)
                            .accentColor(.blue)
                        Text(String(format: "%.2f", selected.position.z))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50)
                    }
                }
                
                // Rotation Control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "rotate.3d")
                            .foregroundStyle(.orange)
                        Text("Rotation Y")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "%.1f°", selected.rotation.y * 180 / .pi))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: rotYBinding, in: 0...(.pi*2), step: 0.01)
                        .accentColor(.orange)
                }
            }
            
            // Reset Button
            Button {
                coordinator?.applyTransform(
                    position: [0, 0, -0.5],
                    scale: [0.5, 0.5, 0.5],
                    rotation: [0, 0, 0]
                )
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset Transform")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.orange)
                .cornerRadius(8)
            }
            
            // Remove Button
            Button(role: .destructive) {
                modelManager.removeModel(id: selected.id)
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove Model")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.red)
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// Scene Selection View
struct SceneSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    @ObservedObject var modelManager: NanoVerseModelManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose Your Scene")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Select a microscopic world to explore")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        // Default Scenes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Default Scenes")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                            
                            ForEach(AppModel.MicroWorldScene.allCases.filter { $0 != .imported }, id: \.self) { scene in
                                DefaultSceneButton(scene: scene, appModel: appModel, dismiss: dismiss)
                            }
                        }
                        
                        // Imported Models Section
                        if !modelManager.models.filter({ $0.url != nil }).isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Imported Models")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal)
                                
                                ForEach(modelManager.models.filter { $0.url != nil }) { model in
                                    ImportedModelButton(model: model, appModel: appModel, modelManager: modelManager, dismiss: dismiss)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Scene Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DefaultSceneButton: View {
    let scene: AppModel.MicroWorldScene
    let appModel: AppModel
    let dismiss: DismissAction
    
    var body: some View {
        Button {
            appModel.currentScene = scene
            appModel.selectedImportedModelID = nil // Clear imported model selection
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(scene.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if appModel.currentScene == scene && appModel.selectedImportedModelID == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background((appModel.currentScene == scene && appModel.selectedImportedModelID == nil) ? .blue.opacity(0.1) : .gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((appModel.currentScene == scene && appModel.selectedImportedModelID == nil) ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ImportedModelButton: View {
    let model: ModelEntityWrapper
    let appModel: AppModel
    let modelManager: NanoVerseModelManager
    let dismiss: DismissAction
    
    var body: some View {
        Button {
            appModel.currentScene = .imported
            appModel.selectedImportedModelID = model.id
            modelManager.selectModel(id: model.id)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Imported 3D Model")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if appModel.currentScene == .imported && appModel.selectedImportedModelID == model.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                }
            }
            .padding()
            .background((appModel.currentScene == .imported && appModel.selectedImportedModelID == model.id) ? .green.opacity(0.1) : .gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((appModel.currentScene == .imported && appModel.selectedImportedModelID == model.id) ? .green : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomVoiceRow: View {
    let scene: AppModel.MicroWorldScene
    @State private var customVoiceMessage = ""
    @State private var isEditing = false
    @Environment(AppModel.self) private var appModel
    let testSpeech: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if appModel.hasCustomVoiceMessage(for: scene) {
                        Text("Custom: \(appModel.customVoiceMessages[scene] ?? "")")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Default: \(scene.description)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Test Voice Button
                Button {
                    let message = appModel.hasCustomVoiceMessage(for: scene) 
                        ? (appModel.customVoiceMessages[scene] ?? "") 
                        : scene.description
                    testSpeech(message)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            if isEditing {
                HStack(spacing: 12) {
                    TextField("Enter custom voice message...", text: $customVoiceMessage)
                        .textFieldStyle(.roundedBorder)
                    
                    // Save Button
                    Button {
                        if !customVoiceMessage.isEmpty {
                            appModel.setCustomVoiceMessage(customVoiceMessage, for: scene)
                        }
                        isEditing = false
                        customVoiceMessage = ""
                    } label: {
                        Text("Save")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.green)
                            .cornerRadius(8)
                    }
                    .disabled(customVoiceMessage.isEmpty)
                    
                    // Cancel Button
                    Button {
                        isEditing = false
                        customVoiceMessage = ""
                    } label: {
                        Text("Cancel")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.gray)
                            .cornerRadius(8)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    // Add/Edit Button
                    Button {
                        isEditing = true
                        customVoiceMessage = appModel.customVoiceMessages[scene] ?? ""
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: appModel.hasCustomVoiceMessage(for: scene) ? "pencil" : "plus")
                            Text(appModel.hasCustomVoiceMessage(for: scene) ? "Edit" : "Add Custom")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue)
                        .cornerRadius(8)
                    }
                    
                    // Delete Button (only show if custom message exists)
                    if appModel.hasCustomVoiceMessage(for: scene) {
                        Button {
                            appModel.removeCustomVoiceMessage(for: scene)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.red)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 

