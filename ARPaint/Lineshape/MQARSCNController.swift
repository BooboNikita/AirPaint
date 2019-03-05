//
//  MQScene.swift

import Foundation
import SceneKit
import ARKit
import SwiftyJSON

protocol transDelegate {
    func svgList(svgInfo:Array<String>)
}

/// 禁止使用init方法初始化,请使用共享实例MQARSCNController.sharedInstance
class MQARSCNController {
    
    //MARK: - 属性
    var currentNode:MQNode?//当前绘制的node,每次按下屏幕->移动手指->松手手指创建一个node
    
    // Autodraw
    var ink:Array = Array<Any>()
    var arrayX = Array<Any>()
    var arrayY = Array<Any>()
    var time = Array<Any>()
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height

    var delegate:transDelegate?
    
    let url="https://inputtools.google.com/request?ime=handwriting&app=autodraw&dbg=1&cs=1&oe=UTF-8"
    
    let sceneView:ARSCNView = {
        let view = ARSCNView()
        view.scene = SCNScene()
        return view
    }()
    private var rootNodeVaule:SCNNode? = nil
    var rootNode:SCNNode! {
        get {
            if rootNodeVaule == nil {
                rootNodeVaule = SCNNode()
                sceneView.scene.rootNode.addChildNode(rootNodeVaule!)
            }
            return rootNodeVaule
        }
        set {
            rootNodeVaule = newValue
        }
    }
    
    private var linecolourValue:UIColor? = nil
    var linecolour:UIColor? {
        get {
            if linecolourValue == nil {
                return UIColor(red: CGFloat(arc4random()%255)/255.0, green: CGFloat(arc4random()%255)/255.0, blue: CGFloat(arc4random()%255)/255.0, alpha: 1)
            } else {
                return linecolourValue
            }
        }
        set {
            linecolourValue = newValue
        }
    }
    var linewidth:Double! = 0.001
    
    
    //MARK: - 初始化
    /// 共享实例
    static var sharedInstance:MQARSCNController = {
        let instance = MQARSCNController();
        return instance;
    }()
    private init() {
        
    }
    
    
    //MARK: - 清屏
    func clearTheScreen() {
        self.rootNode.removeFromParentNode()
        self.rootNode = nil
        self.ink.removeAll()
        self.arrayX.removeAll()
        self.arrayY.removeAll()
        self.time.removeAll()
    }
    
    //MARK: - 撤销
    func revoke() {
        
        guard let lastNode = self.rootNode.childNodes.last else {
            return
        }
        
        if ink.count>0{
            ink.removeLast()
            arrayX.removeAll()
            arrayY.removeAll()
            time.removeAll()
        }
        
        
        lastNode.removeFromParentNode()
    }
 
}
