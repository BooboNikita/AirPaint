/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import Foundation
import SceneKit
import UIKit
import Vision
import EFColorPicker
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate, EFColorSelectionViewControllerDelegate, UICollectionViewDelegate,UICollectionViewDataSource, transDelegate, UIGestureRecognizerDelegate {
    
    
    // MARK: - ARKit Config Properties
    
    var screenCenter: CGPoint?
    var trackingFallbackTimer: Timer?
    var jsonSVGInfo:JSON?
    var svgAddress:Array<String>=[]
    var generalColor = UIColor(red: CGFloat(arc4random()%255)/255.0, green: CGFloat(arc4random()%255)/255.0, blue: CGFloat(arc4random()%255)/255.0, alpha: 1)
    
    let session = ARSession()
    
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    // MARK: - Virtual Object Manipulation Properties
    
    var dragOnInfinitePlanesEnabled = false
    var virtualObjectManager: VirtualObjectManager!
    
    // MARK: - Other Properties
    
    var textManager: TextManager!
    var restartExperienceButtonIsEnabled = true
    var svgImageArray:Array<SVGKImage>=[]
    
    // MARK: - UI Elements
    
    var spinner: UIActivityIndicatorView?
    
    var touchPoint: CGPoint = CGPoint(x: 0.0, y: 0.0)
//    var preTouchPoint: CGPoint = CGPoint(x: 0.0, y: 0.0)
    
    let sceneView = MQARSCNController.sharedInstance.sceneView
    
//    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var messagePanel: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var restartExperienceButton: UIButton!
    @IBOutlet weak var colorSelect: UIButton!
    
    @IBOutlet weak var drawButton: UIButton!
    @IBAction func drawAction() {
        
        drawButton.isSelected = !drawButton.isSelected
        inDrawMode = drawButton.isSelected
        in3DMode = false
        
        if(drawButton.isSelected == false){
            MQARSCNController.sharedInstance.stopLines()
        }
    }
    @IBAction func colorSelected(_ sender: UIButton) {
        let colorSelectionController = EFColorSelectionViewController()
        let navCtrl = UINavigationController(rootViewController: colorSelectionController)
        navCtrl.navigationBar.backgroundColor = UIColor.white
        navCtrl.navigationBar.isTranslucent = false
        navCtrl.modalPresentationStyle = UIModalPresentationStyle.popover
        navCtrl.popoverPresentationController?.delegate = self
        navCtrl.popoverPresentationController?.sourceView = sender
        navCtrl.popoverPresentationController?.sourceRect = sender.bounds
        navCtrl.preferredContentSize = colorSelectionController.view.systemLayoutSizeFitting(
            UILayoutFittingCompressedSize
        )
        
        colorSelectionController.delegate = self
        colorSelectionController.color = self.view.backgroundColor ?? UIColor.white
        
        if UIUserInterfaceSizeClass.compact == self.traitCollection.horizontalSizeClass {
            let doneBtn: UIBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Done", comment: ""),
                style: UIBarButtonItemStyle.done,
                target: self,
                action: #selector(ef_dismissViewController(sender:))
            )
            colorSelectionController.navigationItem.rightBarButtonItem = doneBtn
        }
        self.present(navCtrl, animated: true, completion: nil)
    }
    
    @objc func ef_dismissViewController(sender: UIBarButtonItem) {
        self.dismiss(animated: true) {
            [weak self] in
            if let _ = self {
                // TODO: You can do something here when EFColorPicker close.
                print("EFColorPicker closed.")
            }
        }
    }
    
    func colorViewController(colorViewCntroller: EFColorSelectionViewController, didChangeColor color: UIColor) {
        
        generalColor = color
        
        MQARSCNController.sharedInstance.linecolour = generalColor
        colorSelect.backgroundColor = generalColor
        // TODO: You can do something here when color changed.
        print("New color: " + color.debugDescription)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("svgImageArray.count \(svgImageArray.count)")
        return svgImageArray.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "simpleCell", for: indexPath) as! HomeCollectionViewCell
//        cell.backgroundColor = UIColor.red
//        for views in cell.subviews {
//            if views.isMember(of: SVGKLayeredImageView.self){
//                views.removeFromSuperview()
//            }
//        }

//        (cell.contentView.viewWithTag(1) as! UILabel).text = "\(indexPath.row)"


        if indexPath.row<svgImageArray.count{
//        let image = SVGKImage(contentsOf: URL(string: "https://openclipart.org/download/181651/manhammock.svg"))
            let image = svgImageArray[indexPath.row]
            cell.imageView?.image = image
//
            print("refresh")
        }



//        (cell.contentView.viewWithTag(2) as! SVGKLayeredImageView).image = image
//        (cell.contentView.viewWithTag(2) as! SVGKLayeredImageView).transform = transfrom

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        print("indexPath: \(indexPath.row)")
        let image = svgImageArray[indexPath.row]

        let cubeNode = SCNNode(geometry: SCNBox(width: 0.1, height: 0, length: 0.1, chamferRadius: 0))

        let location = UIApplication.shared.keyWindow?.center
        if let planeHitTestPosition = MQARSCNController.sharedInstance.hitTest(location!) {
            cubeNode.position = SCNVector3(planeHitTestPosition.x, planeHitTestPosition.y,planeHitTestPosition.z)
//            cubeNode.geometry?.firstMaterial?.diffuse.contents = image.uiImage.imageWithColor(color: self.generalColor)
            cubeNode.geometry?.firstMaterial?.diffuse.contents = image.uiImage

            DispatchQueue.main.async {
//                self.sceneView.scene.rootNode.addChildNode(cubeNode)
                MQARSCNController.sharedInstance.rootNode.addChildNode(cubeNode)
            }
        }
    }

    
    func readSVGInfo(){
        let path = Bundle.main.path(forResource: "stencils", ofType: "json")
        print(path)
        let url = URL(fileURLWithPath: path!)
        do{
            let data = try Data(contentsOf: url)
            self.jsonSVGInfo = JSON(data: data)
            print("asd\(self.jsonSVGInfo!["balloon"][0]["src"])")
        }
        catch{
            print(error)
        }
    }
    
    func svgList(svgInfo: Array<String>) {
//        print(svgInfo)
        svgImageArray.removeAll()
        DispatchQueue.global().async {
            for i in svgInfo {
                for j in self.jsonSVGInfo![i]{
                    print("hah\(j.1["src"])")
                    //                svgAddress.append(j.1["src"].string!)
                    let url = URL(string: j.1["src"].string!)
//                    let url = URL(string: "https://openclipart.org/download/181651/manhammock.svg")
                    let image = SVGKImage(contentsOf: url)
                    self.self.svgImageArray.append(image!)
                    
                    //                svgAddress.append(j.1["src"].string!)
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
//
//                self.collectionView.reloadData()
//            }
        }
    }
    
    
//    @IBOutlet weak var threeDMagicButton: UIButton!
//    @IBAction func threeDMagicAction(_ button: UIButton) {
//        threeDMagicButton.isSelected = !threeDMagicButton.isSelected
//        in3DMode = threeDMagicButton.isSelected
//        inDrawMode = false
//
//        trackImageInitialOrigin = nil
//    }
    
    @IBOutlet weak var revokeButton: UIButton!
    @IBAction func revokeButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        inDrawMode = false
        drawButton.isSelected = false
        MQARSCNController.sharedInstance.revoke()
//
//        guard let lastNode = self.sceneView.scene.rootNode.childNodes.last else {
//            sender.isSelected = !sender.isSelected
//            return
//        }
//        lastNode.removeFromParentNode()
        
        sender.isSelected = !sender.isSelected
        
    }
    
    
    
    // MARK: - Queues
    
    static let serialQueue = DispatchQueue(label: "com.apple.arkitexample.serialSceneKitQueue")
	// Create instance variable for more readable access inside class
	let serialQueue: DispatchQueue = ViewController.serialQueue
	
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView!.register(HomeCollectionViewCell.self, forCellWithReuseIdentifier: "simpleCell")
        
        let transController = MQARSCNController.sharedInstance
        transController.delegate = self
        
        readSVGInfo()
        
//        Alamofire.request("https://www.autodraw.com/assets/stencils.json", method: .get ).responseJSON { (data) in
//            print(data)
//        }
        
        

        setupUIControls()
        setupScene()
        
        colorSelect.layer.cornerRadius = colorSelect.frame.width/2.0
        colorSelect.layer.masksToBounds = true
        colorSelect.backgroundColor = MQARSCNController.sharedInstance.linecolour
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed after a while.
		UIApplication.shared.isIdleTimerDisabled = true
		
		if ARWorldTrackingConfiguration.isSupported {
			// Start the ARSession.
            resetTracking()
		} else {
			// This device does not support 6DOF world tracking.
			let sessionErrorMsg = "This app requires world tracking. World tracking is only available on iOS devices with A9 processor or newer. " +
			"Please quit the application."
			displayErrorMessage(title: "Unsupported platform", message: sessionErrorMsg, allowRestart: false)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		session.pause()
	}
	
    // MARK: - Setupg g g
    
	func setupScene() {
		virtualObjectManager = VirtualObjectManager()
		
		// set up scene view
		sceneView.setup()
		sceneView.delegate = self
		sceneView.session = session
		// sceneView.showsStatistics = true
        sceneView.frame = self.view.bounds
        self.view.addSubview(sceneView)
        self.view.sendSubview(toBack: sceneView)
//        self.view.bringSubview(toFront: sceneView)
//        self
		
		sceneView.scene.enableEnvironmentMapWithIntensity(25, queue: serialQueue)
		
		setupFocusSquare()
		
		DispatchQueue.main.async {
			self.screenCenter = self.sceneView.bounds.mid
		}
	}
    
    func setupUIControls() {
        textManager = TextManager(viewController: self)
        
        // Set appearance of message output panel
        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
        messagePanel.isHidden = true
        messageLabel.text = ""
    }
    
	
    // MARK: - ARSCNViewDelegate
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		updateFocusSquare()
        
//        DispatchQueue.main.async {
//            self.colorSelect.backgroundColor = MQARSCNController.sharedInstance.linecolour
//        }
		
		// If light estimation is enabled, update the intensity of the model's lights and the environment map
		if let lightEstimate = self.session.currentFrame?.lightEstimate {
			self.sceneView.scene.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 40, queue: serialQueue)
		} else {
			self.sceneView.scene.enableEnvironmentMapWithIntensity(40, queue: serialQueue)
		}
        
        
        // Setup a dot that represents the virtual pen's tippoint
//        if (self.virtualPenTip == nil) {
//            self.virtualPenTip = PointNode(color: UIColor.red)
//            self.sceneView.scene.rootNode.addChildNode(self.virtualPenTip!)
//        }
//        if self.penTip == nil {
//            self.penTip = MQShapeNode(sceneView: self.sceneView)
//        }
        
        
        // Track the thumbnail
        guard let pixelBuffer = self.sceneView.session.currentFrame?.capturedImage,
            let observation = self.lastObservation else {
                self.handler = VNSequenceRequestHandler()
                return
        }
        let request = VNTrackObjectRequest(detectedObjectObservation: observation) { [unowned self] request, error in
            self.handle(request, error: error)
        }
        request.trackingLevel = .accurate
        do {
            try self.handler.perform([request], on: pixelBuffer)
        }
        catch {
            print(error)
        }
        
//         print("predraw")
        // Draw
        if let lastFingerWorldPos = self.lastFingerWorldPos {
            
//            // Update virtual pen position
//            self.virtualPenTip?.isHidden = false
//            self.virtualPenTip?.simdPosition = lastFingerWorldPos
//
//            // Draw new point
//            if (self.inDrawMode && !self.virtualObjectManager.pointNodeExistAt(pos: lastFingerWorldPos)){
//                let newPoint = PointNode()
//                self.sceneView.scene.rootNode.addChildNode(newPoint)
//                self.virtualObjectManager.loadVirtualObject(newPoint, to: lastFingerWorldPos)
//            }
//            self.penTip?.isHidden = false
//
//            if self.inDrawMode {
//                let pLocation = penTip?.preLocation
//                if lastFingerWorldPos == pLocation {
//                    print("plocation \(pLocation)")
//                    return
//                }
//                print("touch \(touchPoint.x) \(touchPoint.y)")
//                if let planeHitTestPosition = self.penTip?.hitTest(touchPoint) {
//                    print("x:\(planeHitTestPosition.x) y: \(planeHitTestPosition.y) z: \(planeHitTestPosition.z)")
//                    self.penTip?.addVertices(vertice: planeHitTestPosition)
//                }
//
//            }
            MQARSCNController.sharedInstance.currentNode?.isHidden = false
            if self.inDrawMode {
                MQARSCNController.sharedInstance.addLines(touchPoint: touchPoint)
            }
            
            
            
            
            
            // Convert drawing to 3D
            if (self.in3DMode ) {
                if self.trackImageInitialOrigin != nil {
                    DispatchQueue.main.async {
                        if self.trackImageInitialOrigin != nil{
                            let newH = 0.4 *  (self.trackImageInitialOrigin!.y - self.trackImageBoundingBox!.origin.y) / self.sceneView.frame.height
                            self.virtualObjectManager.setNewHeight(newHeight: newH)
                        }
                        
                    }
                }
                else {
                    self.trackImageInitialOrigin = self.trackImageBoundingBox?.origin
                }
            }
//            preTouchPoint = touchPoint
        }
        else{
            print("same")
        }
        
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		if let planeAnchor = anchor as? ARPlaneAnchor {
			serialQueue.async {
				self.addPlane(node: node, anchor: planeAnchor)
				self.virtualObjectManager.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor, planeAnchorNode: node)
			}
		}
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		if let planeAnchor = anchor as? ARPlaneAnchor {
			serialQueue.async {
				self.updatePlane(anchor: planeAnchor)
				self.virtualObjectManager.checkIfObjectShouldMoveOntoPlane(anchor: planeAnchor, planeAnchorNode: node)
			}
            print("renderer")
            
            print("\(MQARSCNController.sharedInstance.currentNode?.pLocation) \(touchPoint)")
            
            if MQARSCNController.sharedInstance.currentNode?.pLocation == touchPoint{
                print("same1")
//                self.penTip?._beganAddVertices = false
//                MQARSCNController.sharedInstance.stopLines()
            }
            
		}
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
		if let planeAnchor = anchor as? ARPlaneAnchor {
			serialQueue.async {
				self.removePlane(anchor: planeAnchor)
			}
		}
	}
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        glLineWidth(8)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable:
            fallthrough
        case .limited:
            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
        }
    }
	
    func session(_ session: ARSession, didFailWithError error: Error) {

        guard let arError = error as? ARError else { return }

        let nsError = error as NSError
		var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
		if let recoveryOptions = nsError.localizedRecoveryOptions {
			for option in recoveryOptions {
				sessionErrorMsg.append("\(option).")
			}
		}

        let isRecoverable = (arError.code == .worldTrackingFailed)
		if isRecoverable {
			sessionErrorMsg += "\nYou can try resetting the session or quit the application."
		} else {
			sessionErrorMsg += "\nThis is an unrecoverable error that requires to quit the application."
		}
		
		displayErrorMessage(title: "We're sorry!", message: sessionErrorMsg, allowRestart: isRecoverable)
	}
	
	func sessionWasInterrupted(_ session: ARSession) {
		textManager.blurBackground()
		textManager.showAlert(title: "Session Interrupted", message: "The session will be reset after the interruption has ended.")
	}
		
	func sessionInterruptionEnded(_ session: ARSession) {
		textManager.unblurBackground()
		session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
		restartExperience(self)
		textManager.showMessage("RESETTING SESSION")
	}
	
    // MARK: - Planes
	
	var planes = [ARPlaneAnchor: Plane]()
	
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
		let plane = Plane(anchor)
		planes[anchor] = plane
		node.addChildNode(plane)
		
		textManager.cancelScheduledMessage(forType: .planeEstimation)
		textManager.showMessage("SURFACE DETECTED")
		if virtualObjectManager.pointNodes.isEmpty {
			textManager.scheduleMessage("TAP + TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
		}
	}
		
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
			plane.update(anchor)
		}
	}
			
    func removePlane(anchor: ARPlaneAnchor) {
		if let plane = planes.removeValue(forKey: anchor) {
			plane.removeFromParentNode()
//            self.penTip?.clearTheScreen()
//            MQARSCNController.sharedInstance.clearTheScreen()
        }
    }
	
	func resetTracking() {
		session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
		
		textManager.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT",
		                            inSeconds: 7.5,
		                            messageType: .planeEstimation)
        
        trackImageInitialOrigin = nil
        inDrawMode = false
        in3DMode = false
        lastFingerWorldPos = nil
        drawButton.isSelected = false
        revokeButton.isSelected = false
        MQARSCNController.sharedInstance.clearTheScreen()
        MQARSCNController.sharedInstance.currentNode = nil
//        threeDMagicButton.isSelected = false
//        self.virtualPenTip?.isHidden = true
        
	}

    // MARK: - Focus Square
    
    var focusSquare: FocusSquare?
	
    func setupFocusSquare() {
		serialQueue.async {
			self.focusSquare?.isHidden = true
			self.focusSquare?.removeFromParentNode()
			self.focusSquare = FocusSquare()
			self.sceneView.scene.rootNode.addChildNode(self.focusSquare!)
		}
		
		textManager.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
    }
	
	func updateFocusSquare() {
		guard let screenCenter = screenCenter else { return }
		
		DispatchQueue.main.async {
//            if self.virtualObjectManager.pointNodes.count > 0 {
            if MQARSCNController.sharedInstance.currentNode != nil {
				self.focusSquare?.hide()
			} else {
				self.focusSquare?.unhide()
			}
			
            let (worldPos, planeAnchor, _) = self.virtualObjectManager.worldPositionFromScreenPosition(screenCenter,
                                                                                                       in: self.sceneView,
                                                                                                       objectPos: self.focusSquare?.simdPosition)
			if let worldPos = worldPos {
				self.serialQueue.async {
					self.focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.session.currentFrame?.camera)
				}
				self.textManager.cancelScheduledMessage(forType: .focusSquare)
			}
		}
	}
    
	// MARK: - Error handling
	
	func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
		// Blur the background.
		textManager.blurBackground()
		
		if allowRestart {
			// Present an alert informing about the error that has occurred.
			let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
				self.textManager.unblurBackground()
				self.restartExperience(self)
			}
			textManager.showAlert(title: title, message: message, actions: [restartAction])
		} else {
			textManager.showAlert(title: title, message: message, actions: [])
		}
	}
    
    // MARK: - ARPaint methods
    
    var inDrawMode = false
    var in3DMode = false
    var lastFingerWorldPos: float3?
    
//    var virtualPenTip: PointNode?
//    var penTip: MQShapeNode?
    
    
    // MARK: Object tracking
    
    private var handler = VNSequenceRequestHandler()
    fileprivate var lastObservation: VNDetectedObjectObservation?
    var trackImageBoundingBox: CGRect?
    var trackImageInitialOrigin: CGPoint?
    let trackImageSize = CGFloat(20)
    
    @objc private func tapAction(recognizer: UITapGestureRecognizer) {
        
        lastObservation = nil
        let tapLocation = recognizer.location(in: sceneView)
        
        // Set up the rect in the image in view coordinate space that we will track
        let trackImageBoundingBoxOrigin = CGPoint(x: tapLocation.x - trackImageSize / 2, y: tapLocation.y - trackImageSize / 2)
        trackImageBoundingBox = CGRect(origin: trackImageBoundingBoxOrigin, size: CGSize(width: trackImageSize, height: trackImageSize))
        
        let t = CGAffineTransform(scaleX: 1.0 / self.view.frame.size.width, y: 1.0 / self.view.frame.size.height)
        let normalizedTrackImageBoundingBox = trackImageBoundingBox!.applying(t)
        
        // Transfrom the rect from view space to image space
        guard let fromViewToCameraImageTransform = self.sceneView.session.currentFrame?.displayTransform(for: UIInterfaceOrientation.portrait, viewportSize: self.sceneView.frame.size).inverted() else {
            return
        }
        var trackImageBoundingBoxInImage =  normalizedTrackImageBoundingBox.applying(fromViewToCameraImageTransform)
        trackImageBoundingBoxInImage.origin.y = 1 - trackImageBoundingBoxInImage.origin.y   // Image space uses bottom left as origin while view space uses top left
        
        print("track \(trackImageBoundingBoxInImage.origin)")
        
//        self.penTip?._beganAddVertices = false
         //*new
        MQARSCNController.sharedInstance.currentNode = nil
        
        lastObservation = VNDetectedObjectObservation(boundingBox: trackImageBoundingBoxInImage)
        
    }
    
    fileprivate func handle(_ request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let newObservation = request.results?.first as? VNDetectedObjectObservation else {
                return
            }
            
            self.lastObservation = newObservation
            
            // check the confidence level before updating the UI
            guard newObservation.confidence >= 0.3 else {
                // hide the pen when we lose accuracy so the user knows something is wrong
//                self.virtualPenTip?.isHidden = true
                
                //*new
//                MQARSCNController.sharedInstance.currentNode?.isHidden = true
                
                self.lastObservation = nil
                return
            }
            
            var trackImageBoundingBoxInImage = newObservation.boundingBox
            
            // Transfrom the rect from image space to view space
            trackImageBoundingBoxInImage.origin.y = 1 - trackImageBoundingBoxInImage.origin.y
            guard let fromCameraImageToViewTransform = self.sceneView.session.currentFrame?.displayTransform(for: UIInterfaceOrientation.portrait, viewportSize: self.sceneView.frame.size) else {
                return
            }
            let normalizedTrackImageBoundingBox = trackImageBoundingBoxInImage.applying(fromCameraImageToViewTransform)
            let t = CGAffineTransform(scaleX: self.view.frame.size.width, y: self.view.frame.size.height)
            let unnormalizedTrackImageBoundingBox = normalizedTrackImageBoundingBox.applying(t)
            self.trackImageBoundingBox = unnormalizedTrackImageBoundingBox
            
            // Get the projection if the location of the tracked image from image space to the nearest detected plane
            if let trackImageOrigin = self.trackImageBoundingBox?.origin {
                self.touchPoint = CGPoint(x: trackImageOrigin.x - 20.0, y: trackImageOrigin.y + 40.0 )
                (self.lastFingerWorldPos, _, _) = self.virtualObjectManager.worldPositionFromScreenPosition(CGPoint(x: trackImageOrigin.x - 20.0, y: trackImageOrigin.y + 40.0), in: self.sceneView, objectPos: nil, infinitePlane: false)
            }
            
        }
    }
}


extension UIImage {
    func imageWithColor(color:UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        //        CGContextTranslateCTM(context!, 0, self.size.height)
        context?.translateBy(x: 0,y: self.size.height)
        //        CGContextScaleCTM(context!, 1.0, -1.0)
        context?.scaleBy(x: 1.0, y: -1.0)
        //        CGContextSetBlendMode
        context?.setBlendMode(CGBlendMode.normal)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context?.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context?.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
