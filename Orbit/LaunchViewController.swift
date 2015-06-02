//
//  LaunchViewController.swift
//  Orbit
//
//  Created by Cal on 6/1/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import UIKit

class LaunchViewController : UIViewController {

    override func viewDidAppear(animated: Bool) {
        let main = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("MainMenu") as! UIViewController
        let segue = GameSegue(identifier: "launch", source: self, destination: main, performHandler: {})
        segue.perform()
    }
    
    
}