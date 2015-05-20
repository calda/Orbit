//
//  self.swift
//  Gravity
//
//  Created by Cal on 11/12/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import Foundation
import SpriteKit

class DecorationPlanet : SKShapeNode{
    
    convenience init(radius: CGFloat, color: SKColor, position: CGPoint){
        self.init()
        self.init(circleOfRadius: radius)
        self.fillColor = color
        self.lineWidth = 5.0
        self.strokeColor = color
        self.position = position
    }
    
}

