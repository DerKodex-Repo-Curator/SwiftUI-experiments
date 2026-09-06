import SwiftUI
import SceneKit

/// A real, locally constructed 3D model. Only the CRT material receives picker updates.
struct RetroComputerView: UIViewRepresentable {
    var screenColor: UIColor

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.camera
        view.autoenablesDefaultLighting = false
        view.addGestureRecognizer(UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.rotate(_:))))
        context.coordinator.setScreenColor(screenColor)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.setScreenColor(screenColor)
    }

    final class Coordinator: NSObject {
        let scene = SCNScene()
        let camera = SCNNode()
        private let computer = SCNNode()
        private let screenMaterial = SCNMaterial()
        private var lastColor: UIColor?
        private var startAngle: Float = 0

        override init() {
            super.init()
            scene.rootNode.addChildNode(computer)
            buildComputer()
            buildStudio()
        }

        func setScreenColor(_ color: UIColor) {
            guard lastColor != color else { return }
            lastColor = color
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0
            screenMaterial.multiply.contents = color
            SCNTransaction.commit()
        }

        @objc func rotate(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began { startAngle = computer.eulerAngles.y }
            let delta = Float(gesture.translation(in: gesture.view).x) * 0.006
            computer.eulerAngles.y = min(0.42, max(-0.28, startAngle + delta))
        }

        private func material(_ color: UIColor, roughness: CGFloat = 0.7) -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            material.roughness.contents = roughness
            material.metalness.contents = 0
            return material
        }

        @discardableResult
        private func box(_ width: CGFloat, _ height: CGFloat, _ depth: CGFloat,
                         radius: CGFloat, at position: SCNVector3, material: SCNMaterial,
                         parent: SCNNode? = nil) -> SCNNode {
            let geometry = SCNBox(width: width, height: height, length: depth, chamferRadius: radius)
            geometry.chamferSegmentCount = 5
            geometry.materials = [material]
            let node = SCNNode(geometry: geometry)
            node.position = position
            (parent ?? computer).addChildNode(node)
            return node
        }

        private func buildComputer() {
            let shell = material(UIColor(red: 0.66, green: 0.64, blue: 0.55, alpha: 1))
            let front = material(UIColor(red: 0.79, green: 0.77, blue: 0.67, alpha: 1))
            let edge = material(UIColor(red: 0.39, green: 0.39, blue: 0.33, alpha: 1))
            let dark = material(UIColor(red: 0.055, green: 0.065, blue: 0.058, alpha: 1))

            // Deep enclosure, case seam, and a separate molded front panel.
            box(2.90, 2.16, 1.58, radius: 0.13, at: SCNVector3(0, 1.47, -0.05), material: shell)
            box(2.92, 2.15, 0.035, radius: 0.11, at: SCNVector3(0, 1.47, 0.69), material: edge)
            box(2.94, 2.18, 0.19, radius: 0.12, at: SCNVector3(0, 1.47, 0.79), material: front)
            box(2.66, 0.17, 1.40, radius: 0.045, at: SCNVector3(0, 0.41, -0.02), material: edge)
            box(2.74, 0.23, 1.48, radius: 0.05, at: SCNVector3(0, 0.29, 0), material: shell)

            // Recessed bezel and softly rounded CRT glass.
            box(2.62, 1.76, 0.085, radius: 0.12, at: SCNVector3(0, 1.57, 0.899), material: edge)
            box(2.49, 1.63, 0.10, radius: 0.11, at: SCNVector3(0, 1.57, 0.935), material: dark)
            let display = SCNPlane(width: 2.33, height: 1.49)
            display.cornerRadius = 0.095
            screenMaterial.lightingModel = .constant
            screenMaterial.diffuse.contents = makeScreenTexture()
            screenMaterial.isDoubleSided = false
            display.materials = [screenMaterial]
            let screen = SCNNode(geometry: display)
            screen.position = SCNVector3(0, 1.57, 0.992)
            computer.addChildNode(screen)

            // Compact details sit in a shallow chin beneath the larger display.
            box(0.77, 0.058, 0.025, radius: 0.014, at: SCNVector3(0.77, 0.55, 0.895), material: dark)
            box(0.13, 0.042, 0.035, radius: 0.008, at: SCNVector3(1.09, 0.46, 0.91), material: edge)
            for index in 0..<4 {
                box(0.40, 0.022, 0.017, radius: 0.006, at: SCNVector3(-1.00, 0.46 + Float(index) * 0.044, 0.895), material: edge)
            }
            addLabel("PERSONAL COMPUTER", size: 0.045, at: SCNVector3(-0.58, 0.52, 0.909), color: UIColor(white: 0.32, alpha: 1))
            for index in 0..<10 {
                box(0.012, 0.43, 0.037, radius: 0.004, at: SCNVector3(1.451, 1.95, -0.49 + Float(index) * 0.105), material: edge)
            }

        }

        private func addLabel(_ text: String, size: Float, at position: SCNVector3, color: UIColor) {
            let geometry = SCNText(string: text, extrusionDepth: 0)
            geometry.font = .monospacedSystemFont(ofSize: 1, weight: .medium)
            geometry.materials = [material(color)]
            let node = SCNNode(geometry: geometry)
            node.scale = SCNVector3(size, size, size)
            node.position = position
            computer.addChildNode(node)
        }

        private func buildStudio() {
            camera.camera = SCNCamera()
            camera.camera?.usesOrthographicProjection = true
            camera.camera?.orthographicScale = 1.82
            camera.camera?.zNear = 0.1
            camera.camera?.zFar = 100
            camera.position = SCNVector3(3.1, 2.65, 8.0)
            camera.look(at: SCNVector3(-0.04, 1.52, 0.12))
            scene.rootNode.addChildNode(camera)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 155
            ambient.light?.color = UIColor(red: 0.90, green: 0.94, blue: 1, alpha: 1)
            scene.rootNode.addChildNode(ambient)
            addLight(at: SCNVector3(-3, 6, 5), intensity: 560, color: UIColor(red: 1, green: 0.94, blue: 0.82, alpha: 1))
            addLight(at: SCNVector3(4, 4, -3), intensity: 345, color: UIColor(red: 0.81, green: 0.89, blue: 1, alpha: 1))

            // A soft contact shadow keeps the model grounded without a visible floor edge.
            let shadow = SCNPlane(width: 4.4, height: 2.8)
            let shadowMaterial = SCNMaterial()
            shadowMaterial.lightingModel = .constant
            shadowMaterial.diffuse.contents = makeShadowTexture()
            shadowMaterial.writesToDepthBuffer = false
            shadow.materials = [shadowMaterial]
            let shadowNode = SCNNode(geometry: shadow)
            shadowNode.eulerAngles.x = -.pi / 2
            shadowNode.position = SCNVector3(0, -0.04, 0)
            scene.rootNode.addChildNode(shadowNode)
        }

        private func addLight(at position: SCNVector3, intensity: CGFloat, color: UIColor) {
            let node = SCNNode()
            node.light = SCNLight()
            node.light?.type = .omni
            node.light?.intensity = intensity
            node.light?.color = color
            node.position = position
            scene.rootNode.addChildNode(node)
        }

        private func makeShadowTexture() -> UIImage {
            UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256)).image { renderer in
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [UIColor.black.withAlphaComponent(0.7).cgColor, UIColor.clear.cgColor] as CFArray, locations: [0, 1])!
                renderer.cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: 128, y: 128), startRadius: 12, endCenter: CGPoint(x: 128, y: 128), endRadius: 128, options: [])
            }
        }

        private func makeScreenTexture() -> UIImage {
            let size = CGSize(width: 720, height: 548)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
                let context = renderer.cgContext
                UIColor(white: 0.68, alpha: 1).setFill()
                context.fill(CGRect(origin: .zero, size: size))
                let vignette = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [UIColor.white.withAlphaComponent(0.16).cgColor, UIColor.black.withAlphaComponent(0.45).cgColor] as CFArray, locations: [0, 1])!
                context.drawRadialGradient(vignette, startCenter: CGPoint(x: 360, y: 274), startRadius: 0, endCenter: CGPoint(x: 360, y: 274), endRadius: 450, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                context.setFillColor(UIColor.black.withAlphaComponent(0.07).cgColor)
                for y in stride(from: 0, to: 548, by: 4) { context.fill(CGRect(x: 0, y: y, width: 720, height: 1)) }
                // A broad, faint reflection across the top edge of the glass.
                context.setFillColor(UIColor.white.withAlphaComponent(0.07).cgColor)
                context.fillEllipse(in: CGRect(x: -80, y: -115, width: 850, height: 220))
            }
        }
    }
}
