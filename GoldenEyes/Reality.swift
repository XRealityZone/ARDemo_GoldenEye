//
//  ContentView.swift
//  GoldenEyes
//
//  Created by Yang Xu on 2023/5/27.
//

import ARKit
import RealityKit
import SwiftUI

struct RealityFileView: View {
    @State var show = true
    var body: some View {
        ZStack(alignment: .bottom) {
            RealityFileContainer(show: $show).edgesIgnoringSafeArea(.all)
            Button {
                show.toggle()
            } label: {
                Text(show ? "Hide" : "Show").padding(.horizontal, 20)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
        }
    }
}

struct RealityFileContainer: UIViewRepresentable {
    @Binding var show: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let arConfiguration = ARFaceTrackingConfiguration()
        arView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = context.coordinator
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if show {
            let arAnchor = try! Eyes.load_Eyes()
            uiView.scene.anchors.append(arAnchor)
            context.coordinator.face = arAnchor
        } else {
            context.coordinator.face = nil
            uiView.scene.anchors.removeAll()
        }
    }

    func makeCoordinator() -> Coordiantor {
        Coordiantor(arViewContainer: self)
    }

    class Coordiantor: NSObject, ARSessionDelegate {
        var arViewContainer: RealityFileContainer
        var face: Eyes._Eyes!
        init(arViewContainer: RealityFileContainer) {
            self.arViewContainer = arViewContainer
            super.init()
        }

        func session(_: ARSession,
                     didUpdate anchors: [ARAnchor])
        {
            guard let face else { return }
            var faceAnchor: ARFaceAnchor?
            for anchor in anchors {
                if let a = anchor as? ARFaceAnchor {
                    faceAnchor = a
                }
            }

            let blendShapes = faceAnchor?.blendShapes
            if let jawOpen = blendShapes?[.jawOpen]?.floatValue {
                // control face.eyeL's scale by jawOpen
                face.eyeL?.scale = SIMD3<Float>(1, 1, 1) * (0.3 + jawOpen / 2)
                face.eyeR?.scale = SIMD3<Float>(1, 1, 1) * (0.3 + jawOpen / 2)
            }
        }

        func session(_: ARSession, didRemove _: [ARAnchor]) {
            print("didRemove")
        }

        func session(_: ARSession, didAdd _: [ARAnchor]) {
            print("didAdd")
        }
    }
}
