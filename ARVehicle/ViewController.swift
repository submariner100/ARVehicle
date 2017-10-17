//
//  ViewController.swift
//  ARVehicle
//
//  Created by Macbook on 10/10/2017.
//  Copyright © 2017 Lodge Farm Apps. All rights reserved.
//

// 15/10/2017 - notes The wheels have disappeared from the sceneView so
// we need to recap the section on physics.



import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

	
	@IBOutlet weak var sceneView: ARSCNView!
	
	let configuration = ARWorldTrackingConfiguration()
	let motionManager = CMMotionManager()
	var vehicle = SCNPhysicsVehicle()
	var orientation: CGFloat = 0
	var touched: Int = 0
	var accelerationValues = [UIAccelerationValue(0), UIAccelerationValue(0)]
	
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.sceneView.autoenablesDefaultLighting = true
		self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
		self.configuration.planeDetection = .horizontal
		self.sceneView.session.run(configuration)
		self.sceneView.delegate = self
		self.setUpAccelerometer()
		self.sceneView.showsStatistics = true
		
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let _ = touches.first else {return}
		self.touched += touches.count
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.touched = 0
	}
	
	func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
		let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
		concreteNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "concrete")
		concreteNode.geometry?.firstMaterial?.isDoubleSided = true
		concreteNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
		concreteNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
		let staticBody = SCNPhysicsBody.static()
		concreteNode.physicsBody = staticBody
		return concreteNode
		
	}

	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
		let concreteNode = createConcrete(planeAnchor: planeAnchor)
		node.addChildNode(concreteNode)
		
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
		node.enumerateChildNodes { (childNode, _) in
			childNode.removeFromParentNode()
		}
		let concreteNode = createConcrete(planeAnchor: planeAnchor)
		node.addChildNode(concreteNode)
		
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
		guard let _ = anchor as? ARPlaneAnchor else {return}
		node.enumerateChildNodes { (childNode, _) in
			childNode.removeFromParentNode()
		}
	}

	@IBAction func addCar(_ sender: Any) {
		guard let pointOfView = sceneView.pointOfView else {return}
		let transform = pointOfView.transform
		let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
		let location = SCNVector3(transform.m41,transform.m42,transform.m43)
		let currentPositionOfCamera = orientation + location
		
		let scene = SCNScene(named: "Car-Scene.scn")
		
		let chassis = (scene?.rootNode.childNode(withName: "chassis", recursively: false))!
		let frontLeftWheel = chassis.childNode(withName: "frontLeftParent", recursively: false)!
		let frontRightWheel = chassis.childNode(withName: "frontRightParent", recursively: false)!
		let rearLeftWheel = chassis.childNode(withName: "rearLeftParent", recursively: false)!
		let rearRightWheel = chassis.childNode(withName: "rearRightParent", recursively: false)!
		
		let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeftWheel)
		let v_frontRightWheel = SCNPhysicsVehicleWheel(node: frontRightWheel)
		let v_rearLeftWheel = SCNPhysicsVehicleWheel(node: rearLeftWheel)
		let v_rearRightWheel = SCNPhysicsVehicleWheel(node: rearRightWheel)
		
		chassis.position = currentPositionOfCamera
		let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassis, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
		body.mass = 1
		chassis.physicsBody = body
		self.vehicle = SCNPhysicsVehicle(chassisBody: chassis.physicsBody!, wheels: [v_rearRightWheel, v_rearLeftWheel, v_frontRightWheel, v_frontLeftWheel])
		self.sceneView.scene.physicsWorld.addBehavior(self.vehicle)
		self.sceneView.scene.rootNode.addChildNode(chassis)
		}
	
	
	func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
		//print("simulating physics")
		var engineForce: CGFloat = 0
		var brakingForce: CGFloat = 0
		self.vehicle.setSteeringAngle(-orientation, forWheelAt: 2)
		self.vehicle.setSteeringAngle(-orientation, forWheelAt: 3)
		if self.touched ==  1 {
			engineForce = 5
		} else if self.touched == 2 {
			engineForce = -5
		} else if self.touched == 3 {
			brakingForce = 100
		} else {
			engineForce = 0
		}
		self.vehicle.applyEngineForce(engineForce, forWheelAt: 0)
		self.vehicle.applyEngineForce(engineForce, forWheelAt: 1)
		self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 0)
		self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 1)
		
		
		
		
		
		
	}
	
	func setUpAccelerometer() {
		if motionManager.isAccelerometerAvailable {
			motionManager.accelerometerUpdateInterval = 1/60
			motionManager.startAccelerometerUpdates(to: .main, withHandler:
				{ (accelerometerData, error) in
					if let error = error {
						print(error.localizedDescription)
						return
					}
					self.accelerometerDidChange(acceleration: accelerometerData!.acceleration)
		
			})
		} else {
			print("accelerometer not available")
		}
	}
	
	func accelerometerDidChange(acceleration: CMAcceleration) {
		accelerationValues[1] = filtered(currentAcceleration: accelerationValues[1], UpdatedAcceleration: acceleration.y)
		accelerationValues[0] = filtered(currentAcceleration: accelerationValues[0], UpdatedAcceleration: acceleration.x)
		
		if accelerationValues[0] > 0 {
			self.orientation = -CGFloat(accelerationValues[1])
			
		} else {
			
			self.orientation = CGFloat(accelerationValues[1])
		}
	}
	
	func filtered(currentAcceleration: Double, UpdatedAcceleration: Double) -> Double {
		let kfilteringFactor = 0.5
		return UpdatedAcceleration * kfilteringFactor + currentAcceleration * (1-kfilteringFactor)
	}
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

extension Int {
	var degreesToRadians: Double { return Double(self) * .pi/180}
	
}

