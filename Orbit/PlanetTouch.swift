//
//  self.swift
//  Gravity
//
//  Created by Cal on 11/12/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import Foundation
import SpriteKit

class PlanetTouch : SKShapeNode{
    
    var lineNode : SKShapeNode?
    var planetVelocity : CGVector = CGVectorMake(0, 0)
    
    convenience init(radius: CGFloat, color: SKColor, position: CGPoint){
        self.init()
        self.init(circleOfRadius: radius)
        self.zPosition = 100.0
        self.fillColor = color
        self.lineWidth = 5.0
        self.strokeColor = color
        self.position = position
        
        lineNode = SKShapeNode(rectOfSize: CGSizeMake(5, 5), cornerRadius: 5.0)
        lineNode!.fillColor = color
        lineNode!.strokeColor = color
        lineNode!.lineWidth = 5.0
        lineNode!.lineCap = kCGLineCapRound
        self.addChild(lineNode!)
    }
    
    func setTouchPosition(touch: CGPoint) {
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, 0, 0)
        CGPathAddLineToPoint(path, nil, touch.x - self.position.x, touch.y - self.position.y)
        CGPathCloseSubpath(path)
        lineNode!.path = path
        drawPlanetPath()
        
    }
    
    func drawPlanetPath() {
        for anyChild in self.parent!.children {
            if let dot = anyChild as? PathDot {
                dot.removeFromParent()
            }
        }
        
        let tempPlanet = Planet(radius: 20, color: self.fillColor, position: self.position, physicsMode: .Player)
        tempPlanet.velocityVector = planetVelocity
        if let parent = self.parent {
            self.parent!.addChild(tempPlanet)
            PathDot.generatePathOnPlanet(tempPlanet, persistAttached: false, resetAll: true)
        }
    }
    
}


class TouchTracker {
    
    var touches : [Planet : CGPoint] = [:]
    
    func startTracking(touch: CGPoint) -> PlanetTouch {
        let newPlanet = Planet(radius: 20, color: getRandomColor(), position: touch, physicsMode: .Player)
        newPlanet.touch = PlanetTouch(radius: 20, color: newPlanet.fillColor, position: touch)
        touches.updateValue(touch, forKey: newPlanet)
        return newPlanet.touch!
    }
    
    func stopTracking(touch: CGPoint) -> Planet? {
        if var planet = getAssociatedPlanet(touch) {
            planet.velocityVector = (planet.position.asVector() - touch.asVector()) / -40
            touches.removeValueForKey(planet)
            planet.touch?.removeFromParent()
            return planet
        }
        return nil
    }
    
    func didMove(touch: CGPoint){
        if var planet = getAssociatedPlanet(touch) {
            touches.updateValue(touch, forKey: planet)
            planet.touch?.planetVelocity = (planet.position.asVector() - touch.asVector()) / -40
            planet.touch?.setTouchPosition(touch)
        }
    }
    
    func getAssociatedPlanet(touch : CGPoint) -> Planet? {
        var closest : (distance: CGFloat, planet: Planet?, touch: CGPoint?) = (CGFloat.max, nil, nil)
        for (planet, candidate) in touches{
            var distanceSquared = touch.distanceSquaredTo(candidate)
            if(closest.distance > distanceSquared){
                closest = (distanceSquared, planet, candidate)
            }
        }
        return closest.planet
    }
    
}

