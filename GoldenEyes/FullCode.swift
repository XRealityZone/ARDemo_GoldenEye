import ARKit
import AVFoundation
import RealityKit
import SwiftUI

struct FullCodeDemo: View {
    @State var show = true
    var body: some View {
        ZStack(alignment: .bottom) {
            FullCodeARViewContainer(show: $show).edgesIgnoringSafeArea(.all)
            Button(action: {
                show.toggle()
            }) {
                Text(show ? "Hide" : "Show")
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
        }
    }
}

struct FullCodeARViewContainer: UIViewRepresentable {
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
            let arAnchor = try! makeEyesAnchor(context: context)
            context.coordinator.face = arAnchor
            uiView.scene.anchors.append(arAnchor)

            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
            uiView.addGestureRecognizer(tapGesture)
        } else {
            context.coordinator.face = nil
            uiView.scene.anchors.removeAll()
        }
    }

    func makeCoordinator() -> FullCodeARDelegateHandler {
        FullCodeARDelegateHandler(arViewContainer: self)
    }

    func makeEyesAnchor(context _: Context) throws -> AnchorEntity {
        let eyesAnchor = AnchorEntity()
        let eyeBallSize: Float = 0.015 // 小球的尺寸
        let collisionBoxSize: Float = 0.03 // 碰撞盒的尺寸

        // 创建左眼小球并设置位置
        let leftEyeBall = createEyeBall(scale: eyeBallSize)
        let leftEyeOffset = SIMD3<Float>(0.03, 0.02, 0.05) // 左眼相对于头部的偏移量
        leftEyeBall.name = "leftEye"
        leftEyeBall.position = leftEyeOffset

        // 为左眼小球添加碰撞盒
        let leftEyeCollision = CollisionComponent(shapes: [ShapeResource.generateBox(size: [collisionBoxSize, collisionBoxSize, collisionBoxSize])])
        leftEyeBall.components.set(leftEyeCollision)

        eyesAnchor.addChild(leftEyeBall)

        // 创建右眼小球并设置位置
        let rightEyeBall = createEyeBall(scale: eyeBallSize)
        let rightEyeOffset = SIMD3<Float>(-0.03, 0.02, 0.05) // 右眼相对于头部的偏移量
        rightEyeBall.name = "rightEye"
        rightEyeBall.position = rightEyeOffset

        // 为右眼小球添加碰撞盒
        let rightEyeCollision = CollisionComponent(shapes: [ShapeResource.generateBox(size: [collisionBoxSize, collisionBoxSize, collisionBoxSize])])
        rightEyeBall.components.set(rightEyeCollision)

        eyesAnchor.addChild(rightEyeBall)

        return eyesAnchor
    }

    func createEyeBall(scale: Float) -> ModelEntity {
        let eyeBall = ModelEntity(
            mesh: .generateSphere(radius: scale),
            materials: [SimpleMaterial(color: .yellow, isMetallic: true)]
        )
        return eyeBall
    }
}

class FullCodeARDelegateHandler: NSObject, ARSessionDelegate {
    var arViewContainer: FullCodeARViewContainer
    var face: AnchorEntity?
    var player: AVAudioPlayer?
    init(arViewContainer: FullCodeARViewContainer) {
        self.arViewContainer = arViewContainer
        super.init()
    }

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor,
              let face = face
        else {
            return
        }

        // 更新头部实体的位置和方向
        let facePosition = simd_make_float3(faceAnchor.transform.columns.3)
        let faceOrientation = simd_quatf(faceAnchor.transform)
        face.position = facePosition
        face.orientation = faceOrientation

        // 获取头部节点的旋转值
        let faceRotation = face.orientation

        // 更新左眼小球的旋转
        if let leftEye = face.children.first(where: { $0.name == "leftEye" }) as? ModelEntity {
            let parentRotation = faceOrientation
            let eyeLocalRotation = simd_mul(parentRotation.inverse, faceRotation)
            leftEye.orientation = eyeLocalRotation
        }

        // 更新右眼小球的旋转
        if let rightEye = face.children.first(where: { $0.name == "rightEye" }) as? ModelEntity {
            let parentRotation = faceOrientation
            let eyeLocalRotation = simd_mul(parentRotation.inverse, faceRotation)
            rightEye.orientation = eyeLocalRotation
        }

        let maxScale: Float = 1.6 // 小球的最大缩放倍数

        // 获取张嘴程度
        let blendShapes = faceAnchor.blendShapes

        if let jawOpen = blendShapes[.jawOpen]?.floatValue {
            // 调整小球的缩放倍数
            let scale = 1 + (jawOpen * maxScale)

            face.children.compactMap { $0 as? ModelEntity }.forEach { eyeBall in
                eyeBall.scale = SIMD3<Float>(repeating: scale)
            }
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = gesture.view as? ARView else { return }
        let touchLocation = gesture.location(in: arView)

        if let _ = arView.entity(at: touchLocation) {
            playSound()
        }
    }

    func playSound() {
        if player == nil {
            let fileName = "mixkit-classic-click.wav"
            guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
                print("Sound file '\(fileName)' not found.")
                return
            }
            player = try! AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        }

        player?.play()
    }
}
