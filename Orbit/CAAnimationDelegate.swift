//
//  CAAnimationBlockDelegate.swift
//  Orbit
//
//  Created by Cal on 5/31/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import SpriteKit

class CAAnimationDelegate : NSObject {
    
    var animationEnded: () -> ()
    
    init(animationEnded: () -> ()) {
        self.animationEnded = animationEnded
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        animationEnded()
    }
    
}