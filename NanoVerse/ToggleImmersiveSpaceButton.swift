//
//  ToggleImmersiveSpaceButton.swift
//  NanoVerse
//
//  Created by Asesh Nemal on 2025-06-27.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        Button {
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                    case .open:
                        appModel.immersiveSpaceState = .inTransition
                        await dismissImmersiveSpace()
                        // Don't set immersiveSpaceState to .closed because there
                        // are multiple paths to MicroWorldView.onDisappear().
                        // Only set .closed in MicroWorldView.onDisappear().

                    case .closed:
                        appModel.immersiveSpaceState = .inTransition
                        switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                            case .opened:
                                // Don't set immersiveSpaceState to .open because there
                                // may be multiple paths to MicroWorldView.onAppear().
                                // Only set .open in MicroWorldView.onAppear().
                                break

                            case .userCancelled, .error:
                                // On error, we need to mark the immersive space
                                // as closed because it failed to open.
                                fallthrough
                            @unknown default:
                                // On unknown response, assume space did not open.
                                appModel.immersiveSpaceState = .closed
                        }

                    case .inTransition:
                        // This case should not ever happen because button is disabled for this case.
                        break
                }
            }
        } label: {
            HStack {
                Image(systemName: appModel.immersiveSpaceState == .open ? "eye.slash.fill" : "eye.fill")
                Text(appModel.immersiveSpaceState == .open ? "Exit NanoVerse" : "Enter NanoVerse")
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(appModel.immersiveSpaceState == .open ? .red : .blue)
            .cornerRadius(12)
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .animation(.easeInOut, value: appModel.immersiveSpaceState)
    }
}
