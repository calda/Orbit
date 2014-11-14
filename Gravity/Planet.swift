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
    
    let GRAVITATIONAL_CONSTANT : CGFloat = 1000
    var physicsMode : PlanetPhysicsMode = PlanetPhysicsMode.None
    var deservesUpdate : Bool = true
    var radius : CGFloat = 0
    var mass : CGFloat {
        get{
            return pow(radius, 3) * 3.14 * (4/3)
            //return 3.14 * pow(radius, 2)
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
        self.radius = radius
        self.fillColor = color
        self.position = position
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.dynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.contactTestBitMask = 1 | 2 | 3 | 4
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = physicsMode.rawValue
    }
    
    /*func applyForcesOf(other: Planet){
        if(!self.deservesUpdate && !other.deservesUpdate){ return }
        //Fg = m1 * m2 / d62
        let distanceSquared = self.position.distanceSquaredTo(other.position)
        let gravityForce = (self.mass * other.mass) / distanceSquared
        var distance : CGFloat = 0
        
        func applyForcesBetween(planet: Planet, other: Planet){
            if(!planet.deservesUpdate){ return }
            //a = f / m
            let accelleration = gravityForce / planet.mass
            println("Accelleration for planet(r=\(planet.radius)) is \(accelleration)")
            if(accelleration < 0.1){ return }
            if(distance == 0){ distance = sqrt(distanceSquared) }
            let normalVector = (planet.position.asVector() - other.position.asVector()) / -distance
            // Fv = Vn * a * G / M
            let forceVector = (normalVector * accelleration * GRAVITATIONAL_CONSTANT / planet.mass)
            println("Force vector: \(forceVector)")
            planet.velocityVector = planet.velocityVector + forceVector
        }
        
        applyForcesBetween(self, other)
        //applyForcesBetween(other, self)
    }*/
    
    func applyForcesOf(other: Planet){
        if physicsMode.stationary { return }
        let distance = CGVectorMake(other.position.x - self.position.x, other.position.y - self.position.y)
        let accelleration = distance / (abs(distance.dx) + abs(distance.dy))
        velocityVector = velocityVector + (accelleration * other.gravity * 0.00005)
    }
    
    func updatePosition(){
        self.position = CGPointMake(self.position.x + velocityVector.dx, self.position.y + velocityVector.dy)
    }
    
    func dumpStats(){
        println("Planet: radius=\(radius)  mass=\(mass)  location=\(position)")
    }
    
}

enum PlanetPhysicsMode : UInt32{
    case None = 0,
    Scene = 1,
    SceneStationary = 2,
    Player = 3,
    PlayerStationary = 4
    
    var affactedByPlayer : Bool{
        get{
            return self.rawValue > 2
        }
    }
    
    var stationary : Bool{
        get{
            return self.rawValue % 2 == 0
        }
    }
    
}

