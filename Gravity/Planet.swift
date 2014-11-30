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
        if physicsMode.stationary { return }
        let distance = CGVectorMake(other.position.x - self.position.x, other.position.y - self.position.y)
        let distanceSquared = distance.dx * distance.dx + distance.dy * distance.dy
        if (distanceSquared < pow(self.radius * 1.1, 2) || distanceSquared < pow(self.radius * 1.1, 2)) {
            println("collision \(rand())")
            return
        }
        let acceleration = distance / (abs(distance.dx) + abs(distance.dy))
        velocityVector = velocityVector + (acceleration * other.gravity * GRAVITATIONAL_CONSTANT)
    }
    
    func updatePosition(){
        self.position = CGPointMake(self.position.x + velocityVector.dx, self.position.y + velocityVector.dy)
    }
    
    func dumpStats(){
        println("Planet: radius=\(radius)  mass=\(mass)  location=\(position)")
    }
    
}

enum PlanetPhysicsMode : UInt32{
    case None = 0, Player, PlayerStationary, Scene, SceneStationary
    
    var affactedByPlayer : Bool{
        get{
            return self.rawValue <= 2
        }
    }
    
    var stationary : Bool{
        get{
            return self.rawValue % 2 == 0
        }
    }
    
}

