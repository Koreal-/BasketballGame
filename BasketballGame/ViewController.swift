//
//  ViewController.swift
//  BasketballGame
//
//  Created by Kartinin Studio on 25.01.2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    //MARK: - OUTLETS
    @IBOutlet var sceneView: ARSCNView!
    
    //MARK: - PROPERTIES
    let configuration = ARWorldTrackingConfiguration()
    
    var isHoopAdded = false {
        didSet {
            configuration.planeDetection = []
            sceneView.session.run(configuration, options: .removeExistingAnchors)
        }
    }
    
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Detect vertical planes
        configuration.planeDetection = [.horizontal,.vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: - METHODS
    func getBall() -> SCNNode? {
        // Get current frame
        guard let frame = sceneView.session.currentFrame else { return nil }
        
        // Get camera transform
        let cameraTransform = frame.camera.transform
        let matrixCameraTransform = SCNMatrix4(cameraTransform)
        // Ball geometry
        let ball = SCNSphere(radius: 0.125)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "basketball")
        
        // Ball node
        let ballNode = SCNNode(geometry: ball)
        
        // Calculate force for pushing the ball
        let power = Float(5)
        let x = -matrixCameraTransform.m31 * power
        let y = -matrixCameraTransform.m32 * power
        let z = -matrixCameraTransform.m33 * power
        let forceDirection = SCNVector3(x,y,z)
        
        //Add physics body
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
        
        //Apply force
        ballNode.physicsBody?.applyForce(forceDirection, asImpulse: true)
        
        
        // Assign camera position to ball
        ballNode.simdTransform = frame.camera.transform
        
        return ballNode
    }
    func getHoopNode() -> SCNNode {
        let scene = SCNScene(named: "Hoop.scn", inDirectory: "art.scnassets")!
        
        let hoopNode = scene.rootNode.clone()
        
        //Add physics body
        hoopNode.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(
                node: hoopNode,
                options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
            )
        )
        
        return hoopNode
    }
    
    func getPlaneNode(for anchor: ARPlaneAnchor) -> SCNNode {
        let extent = anchor.extent
        let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        // Create 25% transparent
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.25
        
        
        // Rotate plane node
        planeNode.eulerAngles.x -= .pi/2
        return planeNode
    }
    
    func updatePlaneNode(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        guard let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {
            return
        }
        
        //Change plane node center
        planeNode.simdPosition = anchor.center
        
        //Change plane size
        let extent = anchor.extent
        plane.width = CGFloat(extent.x)
        plane.height = CGFloat(extent.z)
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        // Add the hoop to the center of detected vertical plane
        node.addChildNode(getPlaneNode(for: planeAnchor))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        
        //Update plane node
        updatePlaneNode(node, for: planeAnchor)
    }
    
    //MARK: - ACTIONS
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        if isHoopAdded {
            //Add balls
            guard let ballNode = getBall() else { return }
            
            sceneView.scene.rootNode.addChildNode(ballNode)
        } else {
            let location = sender.location(in: sceneView)
            
            guard let result = sceneView.hitTest(location, types: .estimatedVerticalPlane).first else {
                return
            }
            
            guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical else {
                return
            }
            
            
            //Get hoop node and set its coordinates to the point of point touch
            let hoopNode = getHoopNode()
            hoopNode.simdTransform = result.worldTransform
            
            // Rotate hoop by 90
            hoopNode.eulerAngles.x -= .pi / 2
            
            sceneView.scene.rootNode.addChildNode(hoopNode)
        }
        
        
    }
    
}
