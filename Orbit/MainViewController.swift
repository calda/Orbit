//
//  GameViewController.swift
//  Gravity
//
//  Created by Cal on 11/8/14.
//  Copyright (c) 2014 Cal. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var planet1: UIImageView!
    @IBOutlet weak var planet2: UIImageView!
    @IBOutlet weak var planet3: UIImageView!
    @IBOutlet weak var planet4: UIImageView!
    @IBOutlet weak var levelCollection: UICollectionView!
    @IBOutlet weak var levelCollectionHeight: NSLayoutConstraint!
    
    @IBOutlet weak var gameView: SKView!
    
    override func viewDidLoad() {
        planet1.transform = CGAffineTransformRotate(planet1.transform, CGFloat(M_PI))
        planet3.transform = CGAffineTransformRotate(planet1.transform, CGFloat(M_PI * 0.5))
        //planet4.transform = CGAffineTransformRotate(planet1.transform, CGFloat(M_PI * 1.5))
        
        for planet in [planet1, planet2, planet3, planet4] {
            planet.image = planet.image!.imageWithRenderingMode(.AlwaysTemplate)
            planet.tintColor = getRandomColor()
        }
        
        getRandomColor()
        
        animatePlanets()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        levelCollectionHeight.constant = levelCollection.contentSize.height
    }
    
    func animatePlanets() {
        planet1.transform = CGAffineTransformRotate(planet1.transform, 0.0057)
        planet2.transform = CGAffineTransformRotate(planet2.transform, 0.0078)
        planet3.transform = CGAffineTransformRotate(planet3.transform, 0.0093)
        //planet4.transform = CGAffineTransformRotate(planet4.transform, 0.0053)
        delay(0.001) {
            self.animatePlanets()
        }
    }
    
    //pragma MARK: - Presenting the Game Scene
    
    @IBAction func presentSandbox(sender: UIButton) {
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            gameView.showsFPS = false
            gameView.showsNodeCount = false
            gameView.ignoresSiblingOrder = true
            scene.scaleMode = .AspectFill
            gameView.presentScene(scene)
            
            
            gameView.alpha = 0.0
            gameView.hidden = false
            
            let scrollScale = CGAffineTransformScale(scrollView.transform, CGFloat(0.5), CGFloat(0.5))
            UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: nil, animations: {
                self.gameView.alpha = 1.0
                self.scrollView.transform = scrollScale
            }, completion: nil)
        }
    }
    
    
    //pragma MARK: - Collection view for Levels
    
    var sectionColors = [getRandomColor(), getRandomColor(), getRandomColor(), getRandomColor(), getRandomColor()]

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "section", forIndexPath: indexPath) as! UICollectionReusableView
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("level", forIndexPath: indexPath) as! LevelCell
        cell.decorate(indexPath.item + 1, outOf: 10, baseColor: sectionColors[indexPath.section])
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSizeMake(collectionView.frame.width, 40)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // cell - 10 - cell - 10 - cell - 10 - cell - 10 - cell
        let availableWidth = collectionView.frame.width - 40.0
        let cellWidth = availableWidth / 5.0
        return CGSizeMake(cellWidth, cellWidth)
    }
    
    
    //pragma MARK: Basic View Controller Methods
    
    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.Portrait.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

class LevelCell : UICollectionViewCell {
    
    @IBOutlet weak var levelNumber: UILabel!
    @IBOutlet weak var planet: UIImageView!
    
    let roman = [ "0",
        "I", "II", "III", "IV", "V",
        "VI", "VII", "VIII", "IX", "X",
        "XI", "XII", "XIII", "XIV", "XV",
        "XVI", "XVII", "XVIII", "XIX", "XX"]
    
    func decorate(levelNumber: Int, outOf levelCount: Int, baseColor: UIColor) {
        self.levelNumber.text = roman[levelNumber]
        planet.image = planet.image!.imageWithRenderingMode(.AlwaysTemplate)
        planet.tintColor = baseColor
        
        planet.alpha = 0.5 + (0.5 * (CGFloat(levelNumber) / CGFloat(levelCount)))
    }
    
}











