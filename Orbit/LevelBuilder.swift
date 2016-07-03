//
//  LevelDesigner.swift
//  Orbit
//
//  Created by Cal on 6/2/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import SpriteKit
import UIKit

class LevelBuilder {
    
    static func build(levelName: String, forScene scene: GameScene) {
        
        //load plist
        let path = NSBundle.mainBundle().pathForResource("Levels", ofType: "plist")
        let plist = NSDictionary(contentsOfFile: path!)!
        
        if let level = plist[levelName] as? NSDictionary {
            
            //level goal
            if let goalString = level["Goal"] as? String, let goal = Int(goalString) {
                scene.neededPlanets = goal
            }

            //load planets
            if let planets = level["Planets"] as? [NSDictionary] {
                
                for planetDict in planets {
                    //load individual planet
                    var initialPosition: CGPoint?
                    var initialVelocity: CGVector = CGVectorMake(0, 0)
                    var radius: CGFloat = 20.0
                    var type = "Planet"
                    var physicsMode: PlanetPhysicsMode = .SceneStationary
                    
                    //position. defined in percentages. 50,50 is the middle of the screen.
                    if let dictPosition = planetDict["Position"] as? String {
                        let splits = dictPosition.characters.split{ $0 == "," }.map { String($0) }
                        if splits.count == 2 {
                            let xPercentage = (splits[0] as NSString).doubleValue
                            let yPercentage = (splits[1] as NSString).doubleValue
                            let x = scene.frame.width * CGFloat(xPercentage / 100.0)
                            let y = scene.frame.height * CGFloat(yPercentage / 100.0)
                            initialPosition = CGPointMake(x, y)
                        }
                    }
                    
                    //velocity. pretty self explanitory
                    if let dictVelocity = planetDict["Velocity"] as? String {
                        let splits = dictVelocity.characters.split{ $0 == "," }.map { String($0) }
                        if splits.count == 2 {
                            let x = (splits[0] as NSString).doubleValue
                            let y = (splits[1] as NSString).doubleValue
                            initialVelocity = CGVectorMake(CGFloat(x), CGFloat(y))
                            
                            if x > 0.0 || y > 0.0 {
                                physicsMode = .Scene
                            }
                        }
                    }
                    
                    //radius. also pretty simple.
                    if let dictRadius = planetDict["Radius"] as? String {
                        radius = CGFloat((dictRadius as NSString).doubleValue)
                    }
                    
                    //planet type. determines what to spawn.
                    if let dictType = planetDict["Type"] as? String {
                        type = dictType
                    }
                    
                    //position must be non-nil to spawn planet.
                    if let initialPosition = initialPosition {
                        
                        //spawn planet
                        var planet: Planet?
                        
                        if type == "Planet" {
                            planet = Planet(radius: radius, color: getRandomColor(), position: initialPosition, physicsMode: physicsMode)
                            planet?.velocityVector = initialVelocity
                        }
                        
                        //add it if everything seems to be in order
                        if let planet = planet {
                            scene.addChild(planet)
                        }
                        
                    }
                    else {
                        print("Could not spawn planet because it has no valid initial position.")
                    }
                    
                }
                
            }
        }
        
    }
    
}
