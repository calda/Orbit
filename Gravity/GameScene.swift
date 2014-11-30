//
//  GameScene.swift
//  Gravity
//
//  Created by Cal on 11/8/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import SpriteKit
import Darwin

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var planetCount: Int = 0 {
        willSet(newCount) {
            let plural = "s"
            let singular = ""
            (self.childNodeWithName("GUI")!.childNodeWithName("PlanetCount")! as SKLabelNode).text = "\(newCount) planet\(newCount == 1 ? singular : plural)"
            (self.childNodeWithName("GUI")!.childNodeWithName("PPS")! as SKLabelNode).text = "\(max(newCount - 1, 0)) point\((newCount - 1) == 1 ? singular : plural) per second"
        }
    }
    var points: Int = 0 {
        willSet(newPoints) {
            (self.childNodeWithName("GUI")!.childNodeWithName("Points")! as SKLabelNode).text = "\(newPoints)"
        }
    }
    var touchTracker : TouchTracker? = nil
    let GUINode = SKNode()
    let gameOverLabel = SKLabelNode(fontNamed: "HelveticaNeue-UltraLight")
    var screenSize : (width: CGFloat, height: CGFloat) = (0, 0)
    
    override func didMoveToView(view: SKView) {
        //GUI setup
        GUINode.name = "GUI"
        screenSize = (760, 1365)
        let countLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
        countLabel.name = "PlanetCount"
        countLabel.text = "0 planets"
        countLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.15, alpha: 1)
        countLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        countLabel.fontSize = 60
        countLabel.position = CGPointMake(20, 20)
        GUINode.addChild(countLabel)
        let pointsLabel = SKLabelNode(fontNamed: "HelveticaNeue-UltraLight")
        pointsLabel.name = "Points"
        pointsLabel.text = "200"
        pointsLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        pointsLabel.fontSize = 150
        pointsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        pointsLabel.position = CGPointMake(20, screenSize.height - 120)
        GUINode.addChild(pointsLabel)
        gameOverLabel.name = "GameOver"
        gameOverLabel.text = "game over"
        gameOverLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        gameOverLabel.fontSize = 140
        gameOverLabel.position = CGPointMake(screenSize.width / 2, screenSize.height / 2)
        gameOverLabel.hidden = true
        GUINode.addChild(gameOverLabel)
        let ppsLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
        ppsLabel.name = "PPS"
        ppsLabel.text = "0 points per second"
        ppsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        ppsLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.15, alpha: 1)
        ppsLabel.fontSize = 40
        ppsLabel.position = CGPointMake(screenSize.width - 10, 20)
        GUINode.addChild(ppsLabel)
        GUINode.zPosition = 100
        addChild(GUINode)
        let updatePoints = SKAction.sequence([
            SKAction.runBlock({ self.points += max(self.planetCount - 1, 0) }),
            SKAction.waitForDuration(0.5)
        ])
        runAction(SKAction.repeatActionForever(updatePoints))
        
        //game setup
        physicsWorld.contactDelegate = self
        let doCalculations = SKAction.sequence([
            SKAction.runBlock(doForceCaculations),
            SKAction.waitForDuration(0.01)
        ])
        runAction(SKAction.repeatActionForever(doCalculations))
    }
    
    func doForceCaculations(){
        for child in self.children{
            if !(child is Planet){ continue }
            let planet = child as Planet
            for child in self.children{
                if !(child is Planet){ continue }
                let other = child as Planet
                if other == planet{ continue }
                planet.applyForcesOf(other)
            }
            planet.updatePosition()
            let maxX = screenSize.width - planet.radius
            let maxY = screenSize.height - planet.radius - 5
            if planet.position.x > maxX || planet.position.x < planet.radius - 5 || planet.position.y > maxY || planet.position.y < planet.radius - 5 {
                gameOver(planet)
            }
        }
    }
    
    func gameOver(loser: Planet){
        self.paused = true
        self.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1)
        loser.fillColor = UIColor.blackColor()
        gameOverLabel.hidden = false
    }
    
    func didBeginContact(contact: SKPhysicsContact){
        if contact.bodyA.node is Planet && contact.bodyB.node is Planet{
            let planet1 = contact.bodyA.node as Planet
            let planet2 = contact.bodyB.node as Planet
            removeChildrenInArray([planet1, planet2])
            let biggest = (planet1.radius >= planet2.radius ? planet1 : planet2)
            let smallest = (planet1.radius >= planet2.radius ? planet2 : planet1)
            let newRadius = biggest.radius + (smallest.radius / 2)
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
            newVelocityVector.dy = (planet1.velocityVector.dy * planet1.mass + planet2.velocityVector.dy * planet2.mass) / (planet1.radius + planet2.mass)
            let combinedPlanet = Planet(radius: newRadius, color: combinedColor, position: biggest.position, physicsMode: .Player)
            //combinedPlanet.velocityVector = newVelocityVector
            addChild(combinedPlanet)
            planetCount--
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if !gameOverLabel.hidden {
            for node in self.children{
                if node is Planet {
                    self.removeChildrenInArray([node])
                }
            }
            points = 0
            planetCount = 0
            backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.95, alpha: 1)
            self.paused = false
            gameOverLabel.hidden = true
            touchTracker = nil
        } else {
            if touchTracker == nil{
                touchTracker = TouchTracker()
            }
            for touch in touches{
                let position = (touch as UITouch).previousLocationInNode(self)
                touchTracker?.startTracking(position)
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as UITouch).previousLocationInNode(self)
            touchTracker?.didMove(position)
        }
    }
   
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as UITouch).previousLocationInNode(self)
            if touchTracker != nil{
                if var planet = touchTracker!.stopTracking(position) {
                    addChild(planet)
                    planetCount++
                }
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        
    }
    
}

class TouchTracker {

    var touches : [Planet : CGPoint] = [:]
    
    func startTracking(touch: CGPoint){
        let newPlanet = Planet(radius: 20, color: getRandomColor(), position: touch, physicsMode: .Player)
        touches.updateValue(touch, forKey: newPlanet)
    }
    
    func stopTracking(touch: CGPoint) -> Planet?{
        if var planet = getAssociatedPlanet(touch) {
            planet.velocityVector = (planet.position.asVector() - touch.asVector()) / -20
            touches.removeValueForKey(planet)
            return planet
        }
        return nil
    }
    
    func didMove(touch: CGPoint){
        if var planet = getAssociatedPlanet(touch) {
            touches.updateValue(touch, forKey: planet)
        }
    }
    
    func getAssociatedPlanet(touch : CGPoint) -> Planet?{
        var closest : (distance: CGFloat, planet: Planet?, touch: CGPoint?) = (CGFloat.max, nil, nil)
        for (planet, candidate) in touches{
            var distanceSquared = touch.distanceSquaredTo(candidate)
            if(closest.distance > distanceSquared){
                closest = (distanceSquared, planet, candidate)
            }
        }
        return closest.planet
    }
    
}

func getRandomColor() -> SKColor{
    return SKColor(hue: random(min: 0.15, max: 1.0), saturation: random(min: 0.8, max: 1.0), brightness: random(min: 0.5, max: 0.8), alpha: 1.0)
}

func random(#min: CGFloat, #max: CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
}