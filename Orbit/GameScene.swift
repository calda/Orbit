 //
 //  GameScene.swift
 //  Gravity
 //
 //  Created by Cal on 11/8/14.
 //  Copyright (c) 2014 Cal. All rights reserved.
 //
 
 import SpriteKit
 import Darwin
 
 class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var touchTracker : TouchTracker? = nil
    let GUINode = SKNode()
    var screenSize : CGSize = CGSizeMake(0, 0)
    var edgeLayer: CAShapeLayer?
    
    var planets: [Planet] = []
    
    
    //pragma MARK: - Game Setup
    
    override func didMoveToView(view: SKView) {
        //GUI setup
        GUINode.name = "GUI"
        screenSize = CGSizeMake(760, 1365)
        addEdgePath(screenSize)
        
        let center = CGPointMake(screenSize.width / 2, screenSize.height / 2)
        addChild(Planet(radius: 40, color: getRandomColor(), position: center, physicsMode: .SceneStationary))
        
        //game setup
        physicsWorld.contactDelegate = self
        let doCalculations = SKAction.sequence([
            SKAction.runBlock(doGameLoop),
            SKAction.waitForDuration(0.005)
            ])
        runAction(SKAction.repeatActionForever(doCalculations))
    }
    
    func addEdgePath(screenSize: CGSize) {
        
        let width = self.view!.frame.width
        let height = self.view!.frame.height
        
        let mutable = CGPathCreateMutable()
        CGPathMoveToPoint(mutable, nil, width / 2, 0)
        CGPathAddLineToPoint(mutable, nil, 0, 0)
        CGPathAddLineToPoint(mutable, nil, 0, height)
        CGPathAddLineToPoint(mutable, nil, width, height)
        CGPathAddLineToPoint(mutable, nil, width, 0)
        CGPathAddLineToPoint(mutable, nil, width / 2, 0)
        let path = CGPathCreateMutableCopy(mutable)
        
        edgeLayer = CAShapeLayer()
        edgeLayer!.frame = self.frame
        edgeLayer!.path = path
        edgeLayer!.strokeColor = UIColor(hue: 0.333, saturation: 0.6, brightness: 0.6, alpha: 1.0).CGColor
        edgeLayer!.fillColor = nil
        edgeLayer!.lineWidth = 20.0
        edgeLayer!.strokeEnd = 0.0
        self.view!.layer.addSublayer(edgeLayer!)
    }
    
    
    //pragma MARK: - Planet Management
    
    override func addChild(node: SKNode) {
        if node is Planet && !(node is DummyPlanet) {
            planets.append(node as! Planet)
        }
        super.addChild(node)
    }
    
    override func removeChildrenInArray(nodes: [AnyObject]!) {
        for node in nodes {
            if let planet = node as? Planet {
                planet.removeFromParent()
            }
        }
    }
    
    func markPlanetRemoved(planet: Planet) {
        var index: Int?
        for i in 0 ..< planets.count {
            if planets[i] == planet {
                index = i
            }
        }
        if let index = index {
            planets.removeAtIndex(index)
        }
    }
    
    
    //pragma MARK: - Game Loop Methods
    
    func doGameLoop() {
        doForceCaculations()
        checkLevelCompletion()
    }
    
    func doForceCaculations() {
        for child in self.children{
            if let touch = child as? PlanetTouch {
                touch.drawPlanetPath()
            }
            if !(child is Planet){ continue }
            let planet = child as! Planet
            for child in self.children{
                if !(child is Planet){ continue }
                let other = child as! Planet
                if other == planet{ continue }
                planet.applyForcesOf(other)
            }
            planet.updatePosition()
        }
    }
    
    func checkLevelCompletion() {
        var neededPlanets = 3
        
        func createAnimationNamed(name: String, #fill: Bool, #current: CGFloat) {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = edgeLayer?.strokeEnd
            animation.toValue = (fill ? 1.0 : 0.0)
            if fill {
                animation.duration = (1.0 - Double(current)) * 3.0
            } else {
                animation.duration = Double(current) * 1.0
            }
            animation.removedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            edgeLayer?.addAnimation(animation, forKey: name)
        }
        
        if let edgeLayer = edgeLayer {
            
            var current: CGFloat = 0.0
            
            if let presentation = edgeLayer.presentationLayer() as? CAShapeLayer {
                current = presentation.strokeEnd
            }
            
            if TouchTracker.countTouches() != 0 {
                edgeLayer.removeAllAnimations()
                edgeLayer.strokeEnd = current
                return
            }
            
            if planets.count == neededPlanets {
                if edgeLayer.animationForKey("drain") != nil {
                    edgeLayer.removeAnimationForKey("drain")
                    edgeLayer.strokeEnd = current
                }
                if edgeLayer.animationForKey("fill") == nil && edgeLayer.strokeEnd < 1.0 {
                    createAnimationNamed("fill", fill: true, current: current)
                }
            }
            else {
                if edgeLayer.animationForKey("fill") != nil {
                    edgeLayer.removeAnimationForKey("fill")
                    edgeLayer.strokeEnd = current
                }
                if edgeLayer.animationForKey("drain") == nil && edgeLayer.strokeEnd > 0.0 {
                    createAnimationNamed("drain", fill: false, current: current)
                }
            }
        }
        
    }
    
    func didBeginContact(contact: SKPhysicsContact){
        if contact.bodyA.node is Planet && contact.bodyB.node is Planet{
            let planet1 = contact.bodyA.node as! Planet
            let planet2 = contact.bodyB.node as! Planet
            
            if let newPlanet = planet1.mergeWithPlanet(planet2) {
                addChild(newPlanet)
            }
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if touchTracker == nil{
            touchTracker = TouchTracker()
        }
        for touch in touches{
            let position = (touch as! UITouch).previousLocationInNode(self)
            if let planetTouch = touchTracker!.startTracking(position) {
                self.addChild(planetTouch)
            }
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as! UITouch).previousLocationInNode(self)
            touchTracker?.didMove(position)
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as! UITouch).previousLocationInNode(self)
            if touchTracker != nil{
                if var planet = touchTracker!.stopTracking(position) {
                    addChild(planet)
                }
            }
        }
    }
    
 }
 
 
 //pragma MARK: - Utility Functions
 
 func getRandomColor() -> SKColor{
    return SKColor(hue: random(min: 0.15, max: 1.0), saturation: random(min: 0.8, max: 1.0), brightness: random(min: 0.5, max: 0.8), alpha: 1.0)
 }
 
 func random(#min: CGFloat, #max: CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
 }
 
 func delay(delay:Double, closure:()->()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), closure)
 }