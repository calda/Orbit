//
//  GameSegue.swift
//  Orbit
//
//  Created by Cal on 6/1/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import UIKit

class GameSegue : UIStoryboardSegue {
    
    override func perform() {
        let source = (self.sourceViewController as! UIViewController)
        let destination = (self.destinationViewController as! UIViewController)
        
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(destination.view, belowSubview: source.view)
        
        let destOriginal = destination.view.transform
        destination.view.transform = CGAffineTransformScale(destOriginal, 1.5, 1.5)
        
        let sourceShrink = CGAffineTransformScale(source.view.transform, 1.5, 1.5)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: nil, animations: {
                source.view.transform = sourceShrink
                source.view.alpha = 0.0
            }, completion: nil)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: nil, animations: {
                destination.view.transform = destOriginal
            }, completion: { success in
                source.presentViewController(destination, animated: false, completion: nil)
        })
    }
    
}

class GameSegueUnwind : UIStoryboardSegue {
    
    override func perform() {
        let source = (self.sourceViewController as! UIViewController)
        let destination = (self.destinationViewController as! UIViewController)
        destination.view.alpha = 0.0
        
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(destination.view, belowSubview: source.view)
        
        let destOriginal = CGAffineTransformMakeScale(1.0, 1.0)
        destination.view.transform = CGAffineTransformScale(destOriginal, 1.5, 1.5)
        
        let sourceShrink = CGAffineTransformScale(source.view.transform, 1.5, 1.5)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: nil, animations: {
            source.view.transform = sourceShrink
        }, completion: nil)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: nil, animations: {
                destination.view.transform = destOriginal
                destination.view.alpha = 1.0
            }, completion: { success in
                source.dismissViewControllerAnimated(false, completion: nil)
        })
    }
    
}