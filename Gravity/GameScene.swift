//
//  GameScene.swift
//  Gravity
//
//  Created by Cal on 11/8/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import SpriteKit
import Darwin

typealias Planet = SKShapeNode

struct PhysicsCategory {
    static let None : UInt32 = 0
    static let All : UInt32 = UInt32.max
    static let ScenePlanet : UInt32 = 1
    static let ScenePlanetStatic : UInt32 = 2
    static let PlayerPlanet : UInt32 = 3
    static let PlayerPlanetStatic : UInt32 = 4
}

enum CalculationPriority : String {
    case Low = "Low", Mid = "Mid", High = "High"
    
    func highBound() -> CGFloat{
        switch(self){
            case .Low: return 10_000
            case .Mid: return 1_000
            case .High: return 200
        }
    }
    
    func lowBound() -> CGFloat{
        switch(self){
        case .Low: return CalculationPriority.Mid.highBound()
        case .Mid: return CalculationPriority.High.highBound()
        case .High: return 0
        }
    }
    
    func isInBounds(distance: CGFloat) -> Bool{
        return Int(highBound()) >= Int(distance) && Int(lowBound()) <= Int(distance)
    }
    
    static func getPriority(distance: CGFloat) -> CalculationPriority{
        if(CalculationPriority.High.isInBounds(distance)){ return .High }
        if(CalculationPriority.Mid.isInBounds(distance)){ return .Mid }
        else{ return .Low }
    }
}

class GameScene: SKScene {
    
    let forceMultiplyer : CGFloat = 10
    var stationary : [Planet] = []
    
    override func didMoveToView(view: SKView) {
        let sun = buildPlanet("Sun", radius: 100, color: SKColor.yellowColor(), border: SKColor.orangeColor(), position: CGPointMake(size.width/2, size.height/2), stationary: true, affectedByPlayer: false)
        let earth = buildPlanet("Earth", radius: 20, color: SKColor.greenColor(), border: SKColor.blueColor(), position: CGPointMake(size.width/2, size.height/2 + 350), stationary: false, affectedByPlayer: true)
        earth.physicsBody?.velocity = CGVectorMake(300, 0)
        let earth2 = buildPlanet("Earth-2", radius: 20, color: SKColor.blueColor(), border: SKColor.greenColor(), position: CGPointMake(size.width/2, size.height/2 - 450), stationary: false, affectedByPlayer: true)
        earth2.physicsBody?.velocity = CGVectorMake(200, 0)
        
        let doHighPriorityCalculations = SKAction.sequence([
                SKAction.runBlock(highPriorityCalculations),
                SKAction.waitForDuration(0.05)
            ])
        let doMidPriorityCalculations = SKAction.sequence([
                SKAction.runBlock(midPriorityCalculations),
                SKAction.waitForDuration(0.1)
            ])
        let doLowPriorityCalculations = SKAction.sequence([
                SKAction.runBlock(lowPriorityCalculations),
                SKAction.waitForDuration(1)
            ])
        runAction(SKAction.repeatActionForever(doHighPriorityCalculations))
        runAction(SKAction.repeatActionForever(doMidPriorityCalculations))
        runAction(SKAction.repeatActionForever(doLowPriorityCalculations))
    }
    
    func lowPriorityCalculations(){
        applyGlobalForcesForPriority(.Low, waitMultiplyer: 100)
    }
    
    func midPriorityCalculations(){
        applyGlobalForcesForPriority(.Mid, waitMultiplyer: 10)
    }
    
    func highPriorityCalculations(){
        applyGlobalForcesForPriority(.High, waitMultiplyer: 5)
    }
    
    func applyGlobalForcesForPriority(priority: CalculationPriority, waitMultiplyer: CGFloat){
        for object in self.children{
            if object is Planet{
                let planet = object as Planet
                if(!priority.isInBounds(planet.zPosition)){ continue; }
                let physics = planet.physicsBody!
                if physics.categoryBitMask % 2 == 1{ //category is odd, thus non-stationary
                    var distant = true
                    for stationaryPlanet in stationary{
                        var distanceSquared = pow(planet.position.x - stationaryPlanet.position.x, 2) + pow(planet.position.y - stationaryPlanet.position.y, 2)
                        if(distanceSquared < 100_000_000){
                            distant = false
                        }
                    }
                    if(distant){
                        planet.removeFromParent()
                    }
                    
                    var shortestDistance : (distance: CGFloat, force: CGFloat, planet: Planet) = (CGFloat.max, 0, planet)
                    
                    for possibleAttractor in self.children{
                        if possibleAttractor is Planet{
                            let attractor = possibleAttractor as Planet
                            if(attractor != planet){ //planet is distant and attractor is not stationary
                                let (distance, force) = applyForce(planet, attractor, waitMultiplyer)
                                if(shortestDistance.distance > distance){
                                    shortestDistance = (distance, force, attractor)
                                }
                            }
                        }
                    }
                    
                    planet.zPosition = shortestDistance.distance
                    
                }else{ //category is even, thus static
                    
                }
            }
        }
    }
    
    func applyForce(planet : Planet, _ attractor : Planet, _ waitMultiplyer: CGFloat) -> (distance: CGFloat, force: CGFloat){
        var mass1 = attractor.physicsBody?.area
        var mass2 = planet.physicsBody?.area
        var force = mass1! + mass2!
        force *= forceMultiplyer
        force *= waitMultiplyer
        var distanceSquared = pow(planet.position.x - attractor.position.x, 2) + pow(planet.position.y - attractor.position.y, 2)
        var intensity = 1 / (distanceSquared / pow(forceMultiplyer, 5))
        var offset = CGVectorMake(planet.position.x - attractor.position.x, planet.position.y - attractor.position.y)
        var distance = sqrt(distanceSquared)
        var normalOffset = CGVectorMake(offset.dx / distance, offset.dy / distance)
        var velocityDelta = CGVectorMake(normalOffset.dx * force * intensity * -1, normalOffset.dy * force * intensity * -1)
        planet.physicsBody!.applyForce(velocityDelta)
        return (distance, force * intensity)
    }
    
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for anyTouch in touches{
            let touch = anyTouch as UITouch
            let planet = buildPlanet("Earth", radius: 20, color: SKColor.blueColor(), border: SKColor.greenColor(), position: touch.locationInNode(self), stationary: false, affectedByPlayer: true)
            planet.physicsBody?.velocity = CGVectorMake(400, 0)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        
    }
    
    func buildPlanet(name: String?, radius: CGFloat, color: SKColor, border: SKColor, position: CGPoint, stationary: Bool, affectedByPlayer: Bool) -> Planet{
        var planet = Planet(circleOfRadius: radius * (7/8))
        planet.name = name?
        planet.lineWidth = radius / 4
        planet.strokeColor = border
        planet.fillColor = color
        planet.position = position
        planet.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        planet.physicsBody?.dynamic = true
        planet.physicsBody?.affectedByGravity = false
        planet.physicsBody?.contactTestBitMask = 1 | 2 | 3 | 4
        planet.physicsBody?.categoryBitMask = (affectedByPlayer ? 3 : 1) + (stationary ? 1 : 0)
        planet.physicsBody?.collisionBitMask = PhysicsCategory.None
        addChild(planet)
        if(stationary){
            self.stationary.append(planet)
        }
        return planet
    }
    
}
