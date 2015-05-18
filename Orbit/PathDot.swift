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
        
        for i in 0...100 {
            for child in scene.children {
                if let planet = child as? Planet {
                    if planet != attached {
                        attached.applyForcesOf(planet)
                    }
                }
            }
            attached.updatePosition()
            
            if i % 10 == 0 {
                let pathDot = PathDot(position: attached.position)
                scene.addChild(pathDot)
            }
        }
        
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
    
}