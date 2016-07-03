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

class PlanetTouch : SKShapeNode {
    
    var touchIsDown: Bool = true
    var lineNode : SKShapeNode?
    var arrowEnd : SKNode?
    var lineEnd : CGPoint?
    var planetVelocity : CGVector = CGVectorMake(0, 0)
    var ownerID : PlanetID?
    
    var showVelocityPercentage: CGFloat = 1.0
    var originalLength: CGFloat = 0.0
    
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
        lineNode!.lineCap = CGLineCap.Round
        self.addChild(lineNode!)
        
        //create arrow line cap
        arrowEnd = SKNode()
        let length: CGFloat = 25
        let arrow1 = SKShapeNode(rectOfSize: CGSizeMake(4, length), cornerRadius: 2)
        let arrow2 = SKShapeNode(rectOfSize: CGSizeMake(4, length), cornerRadius: 2)
        arrow1.fillColor = color
        arrow1.strokeColor = color
        arrow2.fillColor = color
        arrow2.strokeColor = color
        
        let theta: CGFloat = 1.04719755 //(pi / 3) = 60deg
        arrow1.zRotation = theta
        arrow2.zRotation = -theta
        let x = length * cos(theta)
        let y = length * cos(theta)
        arrow1.position = CGPointMake(-x / 2, (y / 2))
        arrow2.position = CGPointMake(-x / 2, (-y / 2))
        
        arrowEnd!.addChild(arrow1)
        arrowEnd!.addChild(arrow2)
        self.addChild(arrowEnd!)
    }
    
    func setTouchPosition(touch: CGPoint) {
        
        if(touchIsDown) {
            originalLength = CGFloat(hypot(touch.x - self.position.x, touch.y - self.position.y))
        }
        
        lineEnd = touch
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, 0, 0)
        CGPathAddLineToPoint(path, nil, touch.x - self.position.x, touch.y - self.position.y)
        CGPathCloseSubpath(path)
        lineNode!.path = path

        let theta = atan2((touch.y - self.position.y), (touch.x - self.position.x))
        
        arrowEnd!.position = CGPointMake(touch.x - self.position.x, touch.y - self.position.y)
        arrowEnd!.zRotation = theta
        
        drawPlanetPath()
        
    }
    
    func showVelocity(velocityVector: CGVector) -> Bool {
        var touchVector = (velocityVector * -TOUCH_TO_VELOCITY_RATIO) * showVelocityPercentage
        
        let length = hypot(touchVector.dx, touchVector.dy)
        if length > originalLength * showVelocityPercentage {
            let scale = (originalLength * showVelocityPercentage) / length
            touchVector = touchVector * scale
        }
        
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
        
        let tempPlanet = Planet(radius: 20, color: self.fillColor, position: self.position, physicsMode: .Player)
        tempPlanet.velocityVector = planetVelocity
        tempPlanet.name = ownerID
        if let parent = self.parent {
            self.parent!.addChild(tempPlanet)
            PathDot.generatePathOnPlanet(tempPlanet, persistAttached: false, resetAll: false)
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
    
    func startTracking(touch: CGPoint) -> PlanetTouch? {
        if TouchTracker.countTouches() > 0 {
            TouchTracker.touches.updateValue(touch, forKey: DummyPlanet())
            return nil
        }
        let newPlanet = Planet(radius: 20, color: getRandomColor(), position: touch, physicsMode: .Player)
        newPlanet.touch = PlanetTouch(radius: 20, color: newPlanet.fillColor, position: touch)
        newPlanet.touch!.ownerID = newPlanet.name
        TouchTracker.touches.updateValue(touch, forKey: newPlanet)
        return newPlanet.touch
    }
    
    func stopTracking(touch: CGPoint) -> Planet? {
        if let planet = getAssociatedPlanet(touch) {
            if planet is DummyPlanet {
                TouchTracker.touches.removeValueForKey(planet)
                return nil
            }
            planet.velocityVector = (planet.position.asVector() - touch.asVector()) / TOUCH_TO_VELOCITY_RATIO
            TouchTracker.touches.removeValueForKey(planet)
            planet.touch?.clearDuplicatePortalPlanets()
            planet.touch?.touchIsDown = false
            PathDot.clearDotsForPlanet(planet)
            
            return planet
        }
        return nil
    }
    
    func didMove(touch: CGPoint){
        if let planet = getAssociatedPlanet(touch) {
            TouchTracker.touches.updateValue(touch, forKey: planet)
            planet.touch?.planetVelocity = (planet.position.asVector() - touch.asVector()) / TOUCH_TO_VELOCITY_RATIO
            planet.touch?.setTouchPosition(touch)
        }
    }
    
    func getAssociatedPlanet(touch : CGPoint) -> Planet? {
        var closest : (distance: CGFloat, planet: Planet?, touch: CGPoint?) = (CGFloat.max, nil, nil)
        for (planet, candidate) in TouchTracker.touches {
            let distanceSquared = touch.distanceSquaredTo(candidate)
            if(closest.distance > distanceSquared){
                closest = (distanceSquared, planet, candidate)
            }
        }
        return closest.planet
    }
    
    static func countTouches() -> Int {
        var count = 0
        for planet in TouchTracker.touches.keys {
            if !(planet is DummyPlanet) {
                count++
            }
        }
        return count
    }
    
}

class DummyPlanet : Planet {
    
}

