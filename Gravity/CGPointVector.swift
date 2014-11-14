//
//  CGPointExtension.swift
//  Gravity
//
//  Created by Cal on 11/12/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import Foundation
import SpriteKit

extension CGPoint{
    
    func distanceSquaredTo(other: CGPoint) -> CGFloat{
        return abs(pow(self.x - other.x, 2) + pow(self.y - other.y, 2))
    }
    
    func distanceTo(other: CGPoint) -> CGFloat{
        return sqrt(distanceSquaredTo(other))
    }
    
    func asVector() -> CGVector{
        return CGVectorMake(x, y)
    }
    
}

extension CGVector : Printable {

    public var description: String {
        return "(\(dx), \(dy))"
    }
}

func + (left: CGVector, right: CGVector) -> CGVector{
    return CGVectorMake(left.dx + right.dx, left.dy + right.dy)
}

func - (left: CGVector, right: CGVector) -> CGVector{
    return CGVectorMake(left.dx - right.dx, left.dy - right.dy)
}

func * (left: CGVector, right: CGVector) -> CGVector{
    return CGVectorMake(left.dx * right.dx, left.dy * right.dy)
}

func / (left: CGVector, right: CGVector) -> CGVector{
    return CGVectorMake(left.dx / right.dx, left.dy / right.dy)
}

func * (left: CGVector, right: CGFloat) -> CGVector{
    return CGVectorMake(left.dx * right, left.dy * right)
}

func / (left: CGVector, right: CGFloat) -> CGVector{
    return CGVectorMake(left.dx / right, left.dy / right)
}