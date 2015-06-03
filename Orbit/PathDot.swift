//
//  PathDot.swift
//  Orbit
//
//  Created by DFA Film 9: K-9 on 5/14/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import SpriteKit

class PathDot : SKShapeNode {
    
    static var dotDirectory: [PlanetID : [PathDot]] = [:]
    
    convenience init(position: CGPoint){
        self.init()
        self.init(circleOfRadius: 3)
        self.fillColor = SKColor(hue: 0.0, saturation: 0.0, brightness: 0.6, alpha: 1.0)
        self.lineWidth = 5.0
        self.strokeColor = self.fillColor
        self.position = position
        self.physicsBody = SKPhysicsBody(circleOfRadius: 3)
        self.physicsBody?.dynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.contactTestBitMask = 1 | 2 | 3 | 4
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = PlanetPhysicsMode.PathDot.rawValue
    }
    
    static func generatePathOnPlanet(attached: Planet, persistAttached: Bool, resetAll: Bool) {
        let scene = attached.scene! as! GameScene
        let sceneChildren : [AnyObject] = scene.children
        
        var originalPlanets : [Planet : (vector: CGVector, position: CGPoint, color: UIColor, radius: CGFloat, mode: PlanetPhysicsMode)] = [:]
        for child in sceneChildren {
            if let planet = child as? Planet {
                let config = (vector: planet.velocityVector, position: planet.position, color: planet.fillColor, radius: planet.radius, mode: planet.physicsMode)
                originalPlanets.updateValue(config, forKey: planet)
            }
        }
        
        var dots = dotDirectory[attached.name!]
        
        //create path dots if empty
        if dots == nil {
            dots = []
            for i in 0...10 {
                let dot = PathDot(position: CGPointZero)
                attached.parent?.addChild(dot)
                dots!.append(dot)
            }
            dotDirectory.updateValue(dots!, forKey: attached.name!)
        }
        
        //get path dots
        
        
        attached.isSimulated = true
        for i in 0...50 {
            for planet in scene.planets {
                if planet != attached {
                    attached.applyForcesOf(planet)
                }
            }
            
            if attached.simulationDead {
                break //simulated planet collided with other
            }
            
            attached.updatePosition()
            
            if i % 5 == 0 {
                let index = i / 5
                let dot = dots![index]
                dot.position = attached.position
            }
        }
        attached.isSimulated = false
        
        if !persistAttached {
            attached.removeFromParent()
        }
        
        if resetAll {
            for planet in originalPlanets.keys {
                planet.removeFromParent()
                if planet == attached {
                    originalPlanets.removeValueForKey(planet)
                }
            }
            for (vector, position, color, radius, mode) in originalPlanets.values {
                let replacement = Planet(radius: radius, color: color, position: position, physicsMode: mode)
                replacement.velocityVector = vector
                scene.addChild(replacement)
            }
        }
        
    }
    
    static func clearDotsForPlanet(planet: Planet) {
        if let dots = dotDirectory[planet.name!] {
            for dot in dots {
                dot.removeFromParent()
            }
            dotDirectory.removeValueForKey(planet.name!)
        }
    }
    
}