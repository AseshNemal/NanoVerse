# NanoVerse

NanoVerse is an immersive 3D educational app for visionOS, designed to let users explore microscopic biological worlds (like cells, DNA, viruses) and import their own 3D models. The app leverages Apple's latest spatial computing technologies to provide interactive, narrated, and visually rich experiences.

---

## Features

- **Immersive 3D Scenes**: Explore built-in biological models (White Blood Cell, DNA, Virus) in a fully immersive environment.
- **Model Import**: Import your own `.usdz` 3D models from local files or HTTPS URLs.
- **Scene & Model Management**: Switch between built-in and imported models. Only one imported model is shown at a time in the immersive view, but you can switch instantly.
- **Custom Voice Narration**: Add, edit, or delete custom narration for each scene. Narration is played using AVSpeechSynthesizer.
- **Dashboard & Controls**: Quick actions for entering/exiting immersive space, changing scenes, importing models, and resetting models. Transform controls for scale, position, and rotation.
- **Error Handling**: User-friendly error messages for model import failures, unsupported formats, and network issues.

---

## Technologies Used

- **Swift & SwiftUI**: Main programming language and UI framework.
- **RealityKit**: 3D rendering, animation, and interaction.
- **AVFoundation**: Text-to-speech narration.
- **Combine**: State and event management.
- **visionOS APIs**: Immersive space, spatial navigation, and 3D interaction.

---

## Folder Structure

```
NanoVerse/
  - NanoVerse/
    - AppModel.swift           // App-wide state and scene management
    - ContentView.swift        // Main entry view
    - DynamicNanoVerseView.swift // Main dashboard, model import, and controls
    - MicroWorldView.swift     // Immersive 3D scene and coordinator
    - Models.swift             // Model management and wrappers
    - NanoVerseApp.swift       // App entry point
    - ToggleImmersiveSpaceButton.swift // UI for entering/exiting immersive space
    - Models/                  // Built-in 3D models (.usdz)
    - Audio/                   // (Reserved for sound effects)
    - Assets.xcassets/         // App icons and colors
    - Textures/                // (Reserved for 3D textures)
  - NanoVerseTests/            // Unit tests
  - Packages/
    - RealityKitContent/       // RealityKit asset package
```

---

## Getting Started

### Prerequisites
- **Xcode 15+**
- **visionOS SDK**
- Apple Vision Pro or visionOS Simulator

### Setup
1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd NanoVerse
   ```
2. **Open in Xcode:**
   - Open `NanoVerse.xcodeproj` in Xcode.
3. **Build & Run:**
   - Select a visionOS target (Vision Pro or Simulator).
   - Press `Run` (⌘R).

### Usage
- Use the dashboard to select a scene or import your own 3D models.
- Enter the immersive space to explore models in 3D.
- Use the dashboard overlay for quick actions and narration.
- Add custom voice messages for each scene.

---

## Credits
- **Developer:** Asesh Nemal
- **Technologies:** Apple Swift, SwiftUI, RealityKit, AVFoundation, visionOS

---

## License
This project is for educational and demonstration purposes. For commercial or redistribution use, please contact the author. 