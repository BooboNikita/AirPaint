//
//  MQARSCNController+AddNode.swift

import ARKit
import Alamofire
import SwiftyJSON



extension MQARSCNController {
    
    //MARK: - touches
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentNode = nil
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let firstTouch = touches.first else {
            return;
        }
        
        let location = firstTouch.location(in: self.sceneView)
        let pLocation = firstTouch.previousLocation(in: self.sceneView)
        if location.x == pLocation.x && location.y == pLocation.y {
            return
        }
        
        if self.currentNode == nil {
            self.currentNode = MQNode()
            self.addNode(self.currentNode!)
        }
        
        //获取屏幕上当前滑动到点的世界位置
        if let planeHitTestPosition = self.hitTest(location) {
            self.currentNode?.addVertices(vertice: planeHitTestPosition)
        }
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentNode = nil
    }
    
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentNode = nil
    }
    
    //MARK: - 添加node
    func addNode(_ node: MQNode) {
        self.rootNode.addChildNode(node)
    }
    func addNodes(_ nodes: [MQNode]) {
        if nodes.count > 0 {
            for node in nodes {
                self.rootNode.addChildNode(node)
            }
        }
    }
    
    func addLines(touchPoint location:CGPoint){
        
        if location.x == currentNode?.pLocation.x && location.y == currentNode?.pLocation.y {
            return
        }
        
        if self.currentNode == nil {
            self.currentNode = MQNode()
            self.addNode(self.currentNode!)
        }
        
        if let planeHitTestPosition = self.hitTest(location) {
            self.currentNode?.addVertices(vertice: planeHitTestPosition)
            
            arrayX.append(planeHitTestPosition.x)
            arrayY.append(planeHitTestPosition.z)
            time.append(ProcessInfo().systemUptime)
            
            
        }
        currentNode?.pLocation = location
    }
    func stopLines(){
        self.currentNode = nil
        print("stopLines")
        
        ink.append([arrayX,arrayY,time])
        arrayX.removeAll()
        arrayY.removeAll()
        time.removeAll()
        
        let request:Dictionary<String,Any> = ["input_type":0,"requests":[["language":"autodraw","writing_guide":["width":width,"height":height],"ink":ink]]]
//        print(request)
        
//        Alamofire.request(url, method: .post, parameters: request, encoding: JSONEncoding.default).responseJSON { (data) in
//            print("network")
//                        print(data)
//            let json = JSON(data: data.data!)
//            print(json[1][0][1])
//        }
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        let jsonStr = JSON(request)
//        print("xixix")
//        print(jsonStr)
        
        let parameters = [
            "jsonData": jsonStr
        ]
        
//        Alamofire.request("http://172.18.57.205:8079/getJsonData", method: .post, parameters: parameters, encoding: URLEncoding(), headers: headers).responseJSON { (data) in
//            //            print("asd\(request)")
//
////            print(parameters["jsonData"])
//
//            print(data)
//            let json = JSON(data: data.data!)
//            print(json[1][0][1])
//        }
        
        Alamofire.request(url, method: .post, parameters: request, encoding: JSONEncoding.default).responseJSON { (data) in
            //            print("asd\(request)")
            
            //            print(parameters["jsonData"])
            
//            self.jsonData = JSON(data: data.data!)
//            print(self.jsonData![1][0][1])
            
            let json = JSON(data: data.data!)
            
            var svgInfoAdd:Array<String>=[]
            
            var cnt = 0
            
            for i in 0...4{
                svgInfoAdd.append(String(describing: json[1][0][1][i]))
                print(String(describing: json[1][0][1][i]))
            }
//            print(svgInfoAdd)km
            if  (svgInfoAdd.count != 0) {
//                print("have")
                self.delegate?.svgList(svgInfo: svgInfoAdd)
                
            }
        }
    }
}
