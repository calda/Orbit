//
//  GameScene.swift
//  Gravity
//
//  Created by Cal on 11/8/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import SpriteKit
import Darwin

class GameScene: SKScene {
    
    var planet1 = Planet(radius: 10, color: SKColor.blueColor(), position: CGPointMake(300,300), physicsMode: .Player)
    var planet2 = Planet(radius: 60, color: SKColor.redColor(), position: CGPointMake(300,500), physicsMode: .SceneStationary)
    let touchTracker = TouchTracker()
    
    override func didMoveToView(view: SKView) {
        addChild(planet1)
        addChild(planet2)
        //planet1.physicsBody?.applyForce(CGVectorMake(30, 0))
        
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
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        
    }
    
}

class TouchTracker {

    var touches : [Planet : CGPoint] = [:]
    
    func startTracking(touch: CGPoint){
        let newPlanet = Planet(radius: 10, color: SKColor.blueColor(), position: touch, physicsMode: .Player)
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
        planet.dumpStats()
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
