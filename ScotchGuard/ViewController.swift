//
//  ViewController.swift
//  ScotchGuard
//
//  Created by Mike Manzano on 8/7/16.
//  Copyright © 2016 Broham Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

// MARK: Model
    
    var model = [NSDictionary]()
    
// MARK: UI Components
    
    var animator: UIDynamicAnimator!
    let square: TrackingView = {
        let v = TrackingView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 200, height: 200)))
        v.backgroundColor = UIColor.blueColor()
        v.userInteractionEnabled = true
        return v
        }()
    let attachedItem: UIView = {
        let v = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 50)))
        v.backgroundColor = UIColor.greenColor()
        return v
        }()
    let attachmentPoint: UIView = {
        let v = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10)))
        v.backgroundColor = UIColor.redColor()
        return v
        }()
    
// MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(square)
        view.addSubview(attachedItem)
        view.addSubview(attachmentPoint)

        square.center = view.center
        attachedItem.center = square.center

        let pan = UIPanGestureRecognizer(target: self, action: #selector(ViewController.panned(_:)))
        square.addGestureRecognizer(pan)

        let tap = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.tapped(_:)))
        tap.minimumPressDuration = 0
        square.addGestureRecognizer(tap)
        
        tap.requireGestureRecognizerToFail(pan)
        
        animator = UIDynamicAnimator(referenceView: view)
        
        addBaseAttachmentBehavior()
        
        loadModelFromDisk()
        startFetchingModelFromNetwork()
    }
    
// MARK: Display
    
    var alreadyAnimatedIn = false
    func addBaseAttachmentBehavior() {

        let attachToCenterBehavior = UIAttachmentBehavior(item: square, attachedToAnchor: CGPoint(x: view.bounds.midX, y: view.bounds.midY))
        attachToCenterBehavior.length = 0
        animator.addBehavior(attachToCenterBehavior)
        
        let attachAttachmentPointBehavior = UIAttachmentBehavior(item: square, offsetFromCenter: UIOffset(horizontal: 100, vertical: 0), attachedToItem: attachmentPoint, offsetFromCenter: UIOffsetZero)
        attachAttachmentPointBehavior.length = 0
        attachAttachmentPointBehavior.damping = 0
        attachAttachmentPointBehavior.frequency = 0
        animator.addBehavior(attachAttachmentPointBehavior)
        
        let attachItemToAttachmentPointBehavior = UIAttachmentBehavior(item: attachmentPoint, offsetFromCenter: UIOffsetZero, attachedToItem: attachedItem, offsetFromCenter: UIOffsetZero)
        animator.addBehavior(attachItemToAttachmentPointBehavior)
        if alreadyAnimatedIn {
            attachItemToAttachmentPointBehavior.length = 0
        } else {
            let attachAttachmentToCenterBehavior = UIAttachmentBehavior(item: attachedItem, attachedToAnchor: view.center)
            attachAttachmentToCenterBehavior.length = 0
            animator.addBehavior(attachAttachmentToCenterBehavior)
            attachItemToAttachmentPointBehavior.length = 100
            attachItemToAttachmentPointBehavior.frequency = 2
            attachItemToAttachmentPointBehavior.damping = 0.5
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(5 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                
                // (*) SIMULATE AN ATTACHMENT LOADING IN AND APPEARING ON SCREEN
                
                self.alreadyAnimatedIn = true
                self.animator.removeBehavior(attachAttachmentToCenterBehavior)
                attachItemToAttachmentPointBehavior.length = 0
            }
        }
        
        let massBehavior = UIDynamicItemBehavior(items: [attachmentPoint, attachedItem])
        massBehavior.density = 0
        massBehavior.friction = 0
        massBehavior.resistance = 1
        animator.addBehavior(massBehavior)
        
        let angularResistanceBehavior = UIDynamicItemBehavior(items: [square])
        angularResistanceBehavior.angularResistance = 2
        animator.addBehavior(angularResistanceBehavior)
    }

    
// MARK: Callbacks and Actions
    
    var draggingAttachmentBehavior: UIAttachmentBehavior! = nil
    func panned(pan: UIPanGestureRecognizer) {
        let offsetInView = pan.locationInView(pan.view)
        square.trackPoint = offsetInView
        switch pan.state {
        case .Began:
            animator.removeAllBehaviors()
            addBaseAttachmentBehavior()
            square.touchDownPoint = offsetInView
            draggingAttachmentBehavior = UIAttachmentBehavior(item: square, offsetFromCenter: UIOffset(horizontal: -(square.bounds.midX - offsetInView.x), vertical: -(square.bounds.midY - offsetInView.y)), attachedToAnchor: pan.locationInView(view))
            draggingAttachmentBehavior.length = 0
            animator.addBehavior(draggingAttachmentBehavior)
        case .Ended:
            animator.removeBehavior(draggingAttachmentBehavior)
            // coast the rotation
            let pushBehavior = UIPushBehavior(items: [square], mode: .Instantaneous)
            pushBehavior.setTargetOffsetFromCenter(UIOffset(horizontal: -(square.bounds.midX - offsetInView.x), vertical: -(square.bounds.midY - offsetInView.y)), forItem: square)
            let velocity: CGPoint = pan.velocityInView(square)
            let magnitude: CGFloat = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            pushBehavior.pushDirection = CGVectorMake((velocity.x / 10) , (velocity.y / 10))
            pushBehavior.magnitude = magnitude / 35.0
            animator.addBehavior(pushBehavior)
            square.pushImpetusPoint = offsetInView
        default:
            draggingAttachmentBehavior.anchorPoint = pan.locationInView(view)
        }
    }
    
    func tapped(tap: UILongPressGestureRecognizer) {
        animator.removeAllBehaviors()
    }
    
// MARK: Screen Update Skeleton

    /// Actually, should be in the "Models" section above, but here to place it in proximity to the skeleton
    var images: [String:UIImage] = [:] { // id:image
        didSet {
            print("There are now \(images.count) images loaded")
            updateAttachmentsWithImages()
        }
    }
    func updateAttachmentsWithImages()
    {
        images.forEach { (identifier, image) in
            // Set image onto the attachment
        }
    }
    func updateDisplayFromModel() {
        
        // For each item in the model
        
            // Does the model already have an entry in `circles` and `costumes`?
        
            // IF NOT IN CIRCLES AND COSTUMES
                // Construct an icon circle and put it into a an `circles` dictionary keyed by the model's id
                // Construct an UIImageView for the costume and set its image from imagesDict, if it exists. Add it to a `costumes` dictionary keyed by the model's id
            
                // Are we in selection mode?
                
                    // If NOT IN SELECTION MODE
                        // Use a pattern similar to (*) above to place the new item in the center, behind Scotch, then animate it into place on the radial interface using behaviors
        
                    // IF IN SELECTION MODE
                        // Well, this isn't specified in the animation, but perhaps place the item above the screen, update collision behaviors, and drop it down from the top
        
        
            // IF IN CIRCLES AND COSTUMES

                    // NOP
    }
    
// MARK: Loading and Network
    
    // These method demonstrates loading the config file, and fetching items from the network. It is not intended to
    // demonstrate proper modelling. In an actual app, structs would be defined for the loaded items, and a JSON->Object
    // mapping would occur.

    func loadModelFromDisk() {
        
        if let path = NSBundle.mainBundle().pathForResource("config", ofType: "plist") {
            if let loadedItems = NSArray(contentsOfFile: path) {
                model += (loadedItems as! [NSDictionary])
                print("Loaded from disk: \(model)")
                
                updateDisplayFromModel()
            }
        }
    }
    
    func startFetchingModelFromNetwork() {
        if let url = NSURL(string: "http://ivdemo.frenchgirlsapp.com/api/current_costumes.json") {
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithURL(url, completionHandler: {
                (data, response, error) in
                if error == nil {
                    if let data = data {
                        
                        do {
                            let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                            print("\nLoaded from network: \(json)")
                            if let dicts = json as? [NSDictionary] {
                                self.model += dicts
                                self.updateDisplayFromModel()
                                self.model.forEach({
                                    (dictionary) in
                                    if  let imageOrURL = dictionary.objectForKey("image") as? String,
                                        let url = NSURL(string: imageOrURL),
                                        let identifier = dictionary.objectForKey("id") as? String {
                                        print("Fetch \(url) from network and store in `images` keyed by the id of the object")
                                        // these could use NSURLSessions, but for brevity…
                                        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
                                            if let imageData = NSData(contentsOfURL: url) {
                                                let image = UIImage(data: imageData)
                                                dispatch_async(dispatch_get_main_queue(), {
                                                    self.images[identifier] = image
                                                })
                                            }
                                        })
                                    }
                                    
                                })
                                
                            } else {
                                print("Unknown format for fetched model!")
                            }
                        }
                        catch _ {
                            print("Error parsing JSON: \(error)")
                        }
                        
                    } else {
                        print("No data returned from costume fetch")
                    }
                } else {
                    print("Could not fetch more costumes: \(error)")
                }
            })
            task.resume()
        } else {
            print("Couldn't fetch more costumes")
        }
    }
}

// MARK: -

/// A view to help visualize tracking
class TrackingView: UIView {
    var trackPoint = CGPointZero {
        didSet {
            setNeedsDisplay()
        }
    }
    var touchDownPoint = CGPointZero {
        didSet {
            setNeedsDisplay()
        }
    }
    var pushImpetusPoint = CGPointZero {
        didSet {
            setNeedsDisplay()
        }
    }
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        
        // pushImpetusPoint
        CGContextSetRGBFillColor(context, 1, 0, 0, 1)
        CGContextFillEllipseInRect(context, CGRect(x: pushImpetusPoint.x - 15, y: pushImpetusPoint.y - 15, width: 30, height: 30))
        
        // touchDownPoint
        CGContextSetRGBStrokeColor(context, 1, 1, 0, 1)
        CGContextSetLineWidth(context, 3)
        CGContextStrokeEllipseInRect(context, CGRect(x: touchDownPoint.x - 10, y: touchDownPoint.y - 10, width: 20, height: 20))
        
        // trackPoint
        CGContextSetRGBFillColor(context, 1, 1, 0, 1)
        CGContextFillEllipseInRect(context, CGRect(x: trackPoint.x - 10, y: trackPoint.y - 10, width: 20, height: 20))
        
        // mark the upper left always with a green dot
        CGContextSetRGBFillColor(context, 0, 1, 0, 1)
        CGContextFillEllipseInRect(context, CGRect(x: -10, y: -10, width: 20, height: 20))
    }
}
