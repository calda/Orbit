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
    
    let touchTracker = TouchTracker()
    var background = SKSpriteNode()
    let world = SKNode()
    
    override func didMoveToView(view: SKView) {
        
        let blurNode = SKEffectNode()
        let blur = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius": 1.0])
        blurNode.filter = blur
        addChild(blurNode)
        blurNode.addChild(world)
        
        background.zPosition = -1
        addChild(background)
        //var sun = Planet(radius: 75, color: SKColor.redColor(), position: CGPointMake(size.width / 2, size.height / 2), physicsMode: .SceneStationary)
        //self.sun = sun
        //addChild(sun)
        //planet1.physicsBody?.applyForce(CGVectorMake(30, 0))
        physicsWorld.contactDelegate = self
        
        let doCalculations = SKAction.sequence([
            SKAction.runBlock(doForceCaculations),
            SKAction.waitForDuration(0.01)
        ])
        
        runAction(SKAction.repeatActionForever(doCalculations))
    }
    
    func doForceCaculations(){
        for child in self.children{
            if !(child is Planet){ continue }
            let planet = child as Planet
            for child in self.children{
                if !(child is Planet){ continue }
                let other = child as Planet
                if other == planet{ continue }
                planet.applyForcesOf(other)
            }
            planet.updatePosition()
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact){
        
        if contact.bodyA.node is Planet && contact.bodyB.node is Planet{
            let planet1 = contact.bodyA.node as Planet
            let planet2 = contact.bodyB.node as Planet
            removeChildrenInArray([planet1, planet2])
            let biggest = (planet1.radius >= planet2.radius ? planet1 : planet2)
            let smallest = (planet1.radius >= planet2.radius ? planet2 : planet1)
            let newRadius = biggest.radius + (smallest.radius / 2)
            var color1 : [CGFloat] = [0,0,0]
            planet1.fillColor.getRed(&color1[0], green: &color1[1], blue: &color1[2], alpha: nil)
            var color2 : [CGFloat] = [0,0,0]
            planet2.fillColor.getRed(&color2[0], green: &color2[1], blue: &color2[2], alpha: nil)
            var newColor : [CGFloat] = [0,0,0]
            for i in 0...2 {
                newColor[i] = (color1[i] * planet1.mass + color2[i] * planet2.mass) / (planet1.mass + planet2.mass)
            }
            let combinedColor = UIColor(red: newColor[0], green: newColor[1], blue: newColor[2], alpha: 1.0)
            var newVelocityVector = CGVectorMake(0,0)
            newVelocityVector.dx = (planet1.velocityVector.dx * planet1.mass + planet2.velocityVector.dx * planet2.mass) / (planet1.mass + planet2.mass)
            newVelocityVector.dy = (planet1.velocityVector.dy * planet1.mass + planet2.velocityVector.dy * planet2.mass) / (planet1.radius + planet2.mass)
            let combinedPlanet = Planet(radius: newRadius, color: combinedColor, position: biggest.position, physicsMode: .Player)
            combinedPlanet.velocityVector = newVelocityVector
            addChild(combinedPlanet)
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as UITouch).previousLocationInNode(self)
            touchTracker.startTracking(position)
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as UITouch).previousLocationInNode(self)
            touchTracker.didMove(position)
        }
    }
   
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as UITouch).previousLocationInNode(self)
            let planet = touchTracker.stopTracking(position)
            addChild(planet)
            if(pow(planet.velocityVector.dx, 2) + pow(planet.velocityVector.dy, 2) > 4500){
                for child in self.children {
                    if child is Planet{
                        var planet = child as Planet
                        if !planet.physicsMode.stationary {
                            self.removeChildrenInArray([planet])
                        }
                    } else {
                        self.removeChildrenInArray([child])
                    }
                }
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        
    }
    
    /*
    func getBlurredBackground() -> UIImage {
        background.alpha = 0
        UIGraphicsBeginImageContextWithOptions(self.view!.bounds.size, false, 1)
        self.view?.drawViewHierarchyInRect(self.view!.frame, afterScreenUpdates: true)
        let ss = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        background.alpha = 1
        
        let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur")
        gaussianBlurFilter.setDefaults()
        gaussianBlurFilter.setValue(CIImage(image: ss), forKey: kCIInputImageKey)
        gaussianBlurFilter.setValue(10, forKey: kCIInputRadiusKey)
        
        let outputImage = gaussianBlurFilter.outputImage
        let context = CIContext(options:nil)
        let rect = outputImage.extent()
        let useRect = CGRectMake(rect.origin.x + (rect.size.width - ss.size.width) / 2, rect.origin.y + (rect.size.width - ss.size.width) / 2, ss.size.width, ss.size.height)
        let cgimg = context.createCGImage(outputImage, fromRect: useRect)
        let image = UIImage(CGImage: cgimg)
        return image!
    }*/
    
}

class TouchTracker {

    var touches : [Planet : CGPoint] = [:]
    
    func startTracking(touch: CGPoint){
        let newPlanet = Planet(radius: 20, color: getRandomColor(), position: touch, physicsMode: .Player)
        touches.updateValue(touch, forKey: newPlanet)
    }
    
    func stopTracking(touch: CGPoint) -> Planet{
        let planet = getAssociatedPlanet(touch)
        planet.velocityVector = (planet.position.asVector() - touch.asVector()) / -20
        touches.removeValueForKey(planet)
        return planet
    }
    
    func didMove(touch: CGPoint){
        let planet = getAssociatedPlanet(touch)
        touches.updateValue(touch, forKey: planet)
    }
    
    func getAssociatedPlanet(touch : CGPoint) -> Planet{
        var closest : (distance: CGFloat, planet: Planet?, touch: CGPoint?) = (CGFloat.max, nil, nil)
        for (planet, candidate) in touches{
            var distanceSquared = touch.distanceSquaredTo(candidate)
            if(closest.distance > distanceSquared){
                closest = (distanceSquared, planet, candidate)
            }
        }
        return closest.planet!
    }
    
}

func getRandomColor() -> SKColor{
    return SKColor(red: random(min:0, max:1), green: random(min:0, max:1), blue: random(min:0, max:1), alpha: 1)
}

func random(#min: CGFloat, #max: CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
}