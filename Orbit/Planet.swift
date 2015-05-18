//
//  self.swift
//  Gravity
//
//  Created by Cal on 11/12/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import Foundation
import SpriteKit

class Planet : SKShapeNode{
    
    let GRAVITATIONAL_CONSTANT : CGFloat = 0.0000325
    var physicsMode : PlanetPhysicsMode = PlanetPhysicsMode.None
    var deservesUpdate : Bool = true
    var radius : CGFloat = 0
    var mass : CGFloat {
        get{
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
    }
    
    func applyForcesOf(other: Planet){
        if self.physicsMode.isStationary { return }
        if self.physicsMode.isScene && other.physicsMode.isPlayer { return }
        
        let distance = CGVectorMake(other.position.x - self.position.x, other.position.y - self.position.y)
        let distanceSquared = distance.dx * distance.dx + distance.dy * distance.dy
        if (distanceSquared < pow(self.radius * 1.1, 2) || distanceSquared < pow(self.radius * 1.1, 2)) {
            return //prevent acceleration during collision
        }
        let acceleration = distance / (abs(distance.dx) + abs(distance.dy))
        velocityVector = velocityVector + (acceleration * other.gravity * GRAVITATIONAL_CONSTANT)
    }
    
    func updatePosition(){
        if self.physicsMode.isStationary { return }
        self.position = CGPointMake(self.position.x + velocityVector.dx, self.position.y + velocityVector.dy)
    }
    
    func dumpStats(){
        println("Planet: radius=\(radius)  mass=\(mass)  location=\(position)")
    }
    
    func mergeWithPlanet(other: Planet) -> Planet {
        let planet1 = self
        let planet2 = other
        
        removeChildrenInArray([planet1, planet2])
        let biggest = (planet1.radius >= planet2.radius ? planet1 : planet2)
        let smallest = (planet1.radius >= planet2.radius ? planet2 : planet1)

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
        
        let combinedPlanet = Planet(radius: newRadius, color: combinedColor, position: biggest.position, physicsMode: combinedMode)
        combinedPlanet.velocityVector = newVelocityVector
        
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

