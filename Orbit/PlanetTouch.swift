//
//  self.swift
//  Gravity
//
//  Created by Cal on 11/12/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import Foundation
import SpriteKit

var TOUCH_TO_VELOCITY_RATIO: CGFloat = -40.0

class PlanetTouch : SKShapeNode{
    
    var touchIsDown: Bool = true
    var lineNode : SKShapeNode?
    var lineEnd : CGPoint?
    var planetVelocity : CGVector = CGVectorMake(0, 0)
    
    var showVelocityPercentage: CGFloat = 1.0
    
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
        
        lineEnd = touch
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, 0, 0)
        CGPathAddLineToPoint(path, nil, touch.x - self.position.x, touch.y - self.position.y)
        CGPathCloseSubpath(path)
        lineNode!.path = path
        drawPlanetPath()
        
    }
    
    func showVelocity(velocityVector: CGVector) -> Bool {
        let touchVector = (velocityVector * -TOUCH_TO_VELOCITY_RATIO) * showVelocityPercentage
        let touchPosition = CGPointMake(touchVector.dx + self.position.x, touchVector.dy + self.position.y)
        self.setTouchPosition(touchPosition)
        
        if showVelocityPercentage <= 0.0 {
            return true
        }
        
        showVelocityPercentage -= 0.05
        return false
    }
    
    func drawPlanetPath() {
        if !touchIsDown {
           return
        }
        
        clearDots()
        
        let tempPlanet = Planet(radius: 20, color: self.fillColor, position: self.position, physicsMode: .Player)
        tempPlanet.velocityVector = planetVelocity
        if let parent = self.parent {
            self.parent!.addChild(tempPlanet)
            PathDot.generatePathOnPlanet(tempPlanet, persistAttached: false, resetAll: false)
        }
    }
    
    func clearDots() {
        for anyChild in self.parent!.children {
            if let dot = anyChild as? PathDot {
                dot.removeFromParent()
            }
        }
    }
    
    func clearDuplicatePortalPlanets() {
        for anyChild in self.parent!.children {
            if let portalPlanet = anyChild as? DecorationPlanet {
                portalPlanet.removeFromParent()
            }
        }
    }
    
}


class TouchTracker {
    
    static var touches : [Planet : CGPoint] = [:]
    
    func startTracking(touch: CGPoint) -> PlanetTouch {
        let newPlanet = Planet(radius: 20, color: getRandomColor(), position: touch, physicsMode: .Player)
        newPlanet.touch = PlanetTouch(radius: 20, color: newPlanet.fillColor, position: touch)
        TouchTracker.touches.updateValue(touch, forKey: newPlanet)
        return newPlanet.touch!
    }
    
    func stopTracking(touch: CGPoint) -> Planet? {
        if var planet = getAssociatedPlanet(touch) {
            planet.velocityVector = (planet.position.asVector() - touch.asVector()) / TOUCH_TO_VELOCITY_RATIO
            TouchTracker.touches.removeValueForKey(planet)
            planet.touch?.clearDots()
            planet.touch?.clearDuplicatePortalPlanets()
            planet.touch?.touchIsDown = false
            return planet
        }
        return nil
    }
    
    func didMove(touch: CGPoint){
        if var planet = getAssociatedPlanet(touch) {
            TouchTracker.touches.updateValue(touch, forKey: planet)
            planet.touch?.planetVelocity = (planet.position.asVector() - touch.asVector()) / TOUCH_TO_VELOCITY_RATIO
            planet.touch?.setTouchPosition(touch)
        }
    }
    
    func getAssociatedPlanet(touch : CGPoint) -> Planet? {
        var closest : (distance: CGFloat, planet: Planet?, touch: CGPoint?) = (CGFloat.max, nil, nil)
        for (planet, candidate) in TouchTracker.touches {
            var distanceSquared = touch.distanceSquaredTo(candidate)
            if(closest.distance > distanceSquared){
                closest = (distanceSquared, planet, candidate)
            }
        }
        return closest.planet
    }
    
}

