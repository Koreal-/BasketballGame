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
        
        //Add physics body
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
        
        // Calculate force for pushing the ball
        let power = Float(10)
        let x = -matrixCameraTransform.m31 * power
        let y = -matrixCameraTransform.m32 * power
        let z = -matrixCameraTransform.m33 * power
        let forceDirection = SCNVector3(x,y,z)
        
        //Apply force
        ballNode.physicsBody?.applyForce(forceDirection, asImpulse: true)
        
        
        // Assign camera position to ball
        ballNode.simdTransform = cameraTransform
        
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
    
    func getFloorNode(for anchor: ARPlaneAnchor) -> SCNNode {
        let extent = anchor.extent
        let floor = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.y))
        floor.firstMaterial?.diffuse.contents = UIColor.yellow
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.opacity = 0.75
        
        return floorNode
    }
    
    func updateFloorNode(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        guard let floorNode = node.childNodes.first, let floor = floorNode.geometry as? SCNPlane else {
            return
        }
        
        //Change plane node center
        floorNode.simdPosition = anchor.center
        
        //Change plane size
        let extent = anchor.extent
        floor.width = CGFloat(extent.x)
        floor.height = CGFloat(extent.y)
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor//, planeAnchor.alignment == .vertical
        else {
            return
        }
        let width1 = CGFloat(planeAnchor.extent.x)
        let height1 = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width1, height: height1)
        
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        // Create 25% transparent
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.25
        
        let x1 = CGFloat(planeAnchor.center.x)
        let y1 = CGFloat(planeAnchor.center.y)
        let z1 = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x1,y1,z1)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(planeNode)
        /*guard let floorAnchor = anchor as? ARPlaneAnchor, floorAnchor.alignment == .horizontal else {
         return
         }*/
        // Add the hoop to the center of detected vertical plane
        //node.addChildNode(getPlaneNode(for: planeAnchor))
        
        //node.addChildNode(getFloorNode(for: floorAnchor))
        //guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let floor = SCNPlane(width: width, height: height)
        
        // 3
        floor.materials.first?.diffuse.contents = UIColor.blue
        
        // 4
        let floorNode = SCNNode(geometry: floor)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        floorNode.position = SCNVector3(x,y,z)
        floorNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(floorNode)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        /*guard let floorAnchor = anchor as? ARPlaneAnchor, floorAnchor.alignment == .horizontal else {
         return
         }*/
        
        //Update plane node
        updatePlaneNode(node, for: planeAnchor)
        
        //updateFloorNode(node, for: floorAnchor)
    }
    
    //MARK: - ACTIONS
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        
        if isHoopAdded {
            //Add balls
            guard let ballNode = getBall() else { return }
            
            sceneView.scene.rootNode.addChildNode(ballNode)
        } else {
            let location = sender.location(in: sceneView)
            
            guard let result = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else {
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
            isHoopAdded = true
            sceneView.scene.rootNode.addChildNode(hoopNode)
        }
        
        
    }
    
}
