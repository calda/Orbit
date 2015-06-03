//
//  self.swift
//  Gravity
//
//  Created by Cal on 11/12/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import Foundation
import SpriteKit

typealias PlanetID = String

class Planet : SKShapeNode{
    
    let GRAVITATIONAL_CONSTANT : CGFloat = 0.008125
    var physicsMode : PlanetPhysicsMode = PlanetPhysicsMode.None
    var deservesUpdate : Bool = true
    var radius : CGFloat = 0
    var hasMass = true
    var mass : CGFloat {
        get{
            if !hasMass { return 0.0 }
            return pow(radius, 3) * 3.14 * (4/3)
        }
    }
    var gravity : CGFloat {
        get{
            return mass / radius
        }
    }
    var velocityVector = CGVectorMake(0, 0)
    var touch: PlanetTouch?
    
    var portalPlanet: DecorationPlanet?
    var doingPortalPlanet: Bool = false
    
    var isSimulated: Bool = false
    var simulationDead: Bool = false
    
    convenience init(radius: CGFloat, color: SKColor, position: CGPoint, physicsMode: PlanetPhysicsMode){
        self.init()
        self.init(circleOfRadius: radius)
        self.physicsMode = physicsMode
        self.zPosition = CGFloat(physicsMode.rawValue)
        self.radius = radius
        self.fillColor = color
        self.lineWidth = 5.0
        self.strokeColor = color
        self.position = position
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.dynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.contactTestBitMask = 1 | 2 | 3 | 4
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = physicsMode.rawValue
        self.name = "\(arc4random())"
    }
    
    func applyForcesOf(other: Planet){
        if self.physicsMode.isStationary { return }
        if self.physicsMode.isScene && other.physicsMode.isPlayer { return }
        
        let distance = CGVectorMake(other.position.x - self.position.x, other.position.y - self.position.y)
        let distanceSquared = distance.dx * distance.dx + distance.dy * distance.dy
        
        let largestRadius = max(self.radius, other.radius)
        if (distanceSquared < pow(largestRadius, 2) || distanceSquared < pow(largestRadius, 2)) {
            simulationDead = true
            return //prevent acceleration during collision
        }
        let acceleration = distance / pow((abs(distance.dx) + abs(distance.dy)), 2)
        
        var slowDown: CGFloat = 1.0
        if TouchTracker.touches.count > 0 && !isSimulated {
            slowDown = 0.2
        }
        
        velocityVector = velocityVector + (acceleration * other.gravity * GRAVITATIONAL_CONSTANT * slowDown)
    }
    
    func updatePosition(){
        if self.physicsMode.isStationary { return }
        
        var slowDown: CGFloat = 1.0
        if TouchTracker.touches.count > 0 && !isSimulated {
            slowDown = 0.2
        }
        
        let adjustedVelocity = velocityVector * slowDown
        
        self.position = CGPointMake(self.position.x + adjustedVelocity.dx, self.position.y + adjustedVelocity.dy)
        
        //retract touch tail
        if let touch = self.touch {
            touch.position = self.position
            let done = touch.showVelocity(self.velocityVector)
            if done {
                self.touch = nil
                touch.removeFromParent()
            }
        }
        
        //portal
        if let parent = self.parent {
            let parentWidth = parent.frame.size.width
            let parentHeight = parent.frame.size.height
            let radius = self.radius
            
            //warps
            if position.x < 0 { //hitting left edge
                position.x = parentWidth
            }
            else if position.x > parentWidth { //hitting right edge
                position.x = 0
            }
            
            if position.y < 0 { //hitting top edge
                position.y = parentHeight
            }
            else if position.y > parentHeight { //hitting bottom edge
                position.y = 0
            }
            
            //poral decorations
            killPortalPlanet()
            
            if !isSimulated {
                if position.x < self.radius {
                    ensurePortalPlanet()
                    self.portalPlanet!.position.x = parentWidth + position.x
                }
                if position.x > parentWidth - self.radius {
                    ensurePortalPlanet()
                    self.portalPlanet!.position.x = position.x - parentWidth
                }
                
                if position.y < self.radius {
                    ensurePortalPlanet()
                    self.portalPlanet!.position.y = parentHeight + position.y
                }
                if position.y > parentHeight - self.radius {
                    ensurePortalPlanet()
                    self.portalPlanet!.position.y = position.y - parentHeight
                }
                
                doingPortalPlanet = false
            }
            
        }
    }
    
    func ensurePortalPlanet() {
        if portalPlanet == nil {
            self.portalPlanet = DecorationPlanet(radius: self.radius, color: self.fillColor, position: self.position)
            self.parent!.addChild(portalPlanet!)
        }
        if !doingPortalPlanet {
            doingPortalPlanet = true
            self.portalPlanet!.position = self.position
        }
    }
    
    func killPortalPlanet() {
        if portalPlanet != nil {
            self.portalPlanet!.removeFromParent()
            self.portalPlanet = nil
        }
    }
    
    func killPlanet() {
        self.removeFromParent()
    }
    override func removeFromParent() {
        if let parent = self.parent as? GameScene {
            parent.markPlanetRemoved(self)
        }
        super.removeFromParent()
    }
    
    func dumpStats(){
        println("Planet: radius=\(radius)  mass=\(mass)  location=\(position)")
    }
    
    func mergeWithPlanet(other: Planet) -> Planet? {
        
        if !other.hasMass || !self.hasMass {
            return nil
        }
        
        //clean up existing planets
        killPortalPlanet()
        other.killPortalPlanet()
        
        if let touch = self.touch {
            touch.removeFromParent()
            self.touch = nil
        }
        if let touch = other.touch {
            touch.removeFromParent()
            other.touch = nil
        }
        
        //merge planets
        let planet1 = self
        let planet2 = other
        
        removeChildrenInArray([planet1, planet2])
        var biggest = (planet1.radius >= planet2.radius ? planet1 : planet2)
        var smallest = (planet1.radius >= planet2.radius ? planet2 : planet1)
        
        //stationary will always absorb non-stationary
        if smallest.physicsMode.isStationary {
            let oldBig = biggest
            biggest = smallest
            smallest = oldBig
        }

        let newMass = biggest.mass + smallest.mass * 2
        let newRadius = pow(newMass / (4/3) / (3.14), 1/3)
        
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
        newVelocityVector.dy = (planet1.velocityVector.dy * planet1.mass + planet2.velocityVector.dy * planet2.mass) / (planet1.mass + planet2.mass)
        
        let combinedMode = planet1.physicsMode.mergeWith(planet2.physicsMode)
        
        let combinedPlanet = Planet(radius: newRadius, color: biggest.fillColor, position: biggest.position, physicsMode: combinedMode)
        combinedPlanet.velocityVector = newVelocityVector
        
        biggest.removeFromParent()
        
        //animate size changes
        smallest.hasMass = false
        let shrink = SKAction.group([
            SKAction.scaleTo(0.0, duration: 0.15),
            SKAction.fadeAlphaTo(0.0, duration: 0.05)
        ])
        smallest.runAction(shrink, completion: {
            smallest.removeFromParent()
        })
        
        let sizeRatio = biggest.radius / combinedPlanet.radius
        combinedPlanet.setScale(sizeRatio)
        let grow = SKAction.group([
            SKAction.scaleTo(1.0, duration: 0.3),
            SKAction.colorizeWithColor(combinedColor, colorBlendFactor: 1.0, duration: 0.3)
        ])
        combinedPlanet.runAction(grow, completion: {
            combinedPlanet.fillColor = combinedColor
            combinedPlanet.strokeColor = combinedColor
        })
        
        return combinedPlanet
    }
    
}

enum PlanetPhysicsMode : UInt32{
    case None = 0, Player, PlayerStationary, Scene, SceneStationary, PathDot

    var isPlayer : Bool{
        get{
            return self == .Player || self == .PlayerStationary
        }
    }

    var isScene : Bool{
        get{
            return self == .Scene || self == .SceneStationary
        }
    }
    
    var isStationary : Bool{
        get{
            return self == .PlayerStationary || self == .SceneStationary
        }
    }
    
    func mergeWith(other: PlanetPhysicsMode) -> PlanetPhysicsMode {
        return (other.rawValue >= self.rawValue ? other : self)
    }
    
}


