//
//  FurnitureButton.swift
//  OfficeMover500
//
//  Created by Katherine Fang on 10/28/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

import Foundation
import UIKit

class FurnitureButton : UIButton {
    
    // -- Model state handlers
    var moveHandler: ((Int, Int) -> ())?
    var rotateHandler: (() -> ())?
    var deleteHandler: (() -> ())?

    // Calculated propeties
    var top:Int {
        return Int(frame.origin.y)
    }
    
    var left:Int {
        return Int(frame.origin.x)
    }
    
    // --- Handling UI state
    var dragging = false
    var menuShowing = false
    private var menuListener: AnyObject?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(furniture: Furniture) {
        super.init(frame: CGRectMake((CGFloat(RoomWidth)-100)/2, (CGFloat(RoomHeight)-100)/2, 100, 50))
        setTop(furniture.top, left: furniture.left)
        
        // TODO replace with image stuff
        setTitle(furniture.key, forState:.Normal)
        backgroundColor = UIColor.redColor()
        
        // Add dragability
        addTarget(self, action:Selector("dragged:withEvent:"), forControlEvents:.TouchDragInside | .TouchDragOutside)
        
        // Add tap menu
        addTarget(self, action:Selector("touchUp:withEvent:"), forControlEvents:.TouchUpInside)
    }
    
    // -- Methods for updating the view
    func setTop(top: Int?, left: Int?) {
        if let x = left {
            frame.origin.x = CGFloat(x)
        }
        if let y = top {
            frame.origin.y = CGFloat(y)
        }
        frame.origin = boundLocToRoom(frame.origin)
    }
    
    func rotateView() {
        transform = CGAffineTransformRotate(transform, CGFloat(M_PI / -2))
    }
    
    func deleteView() {
        removeFromSuperview()
    }
    
    
    // --- Methods for dragging
    func dragged(button: UIButton, withEvent event: UIEvent) {
        dragging = true // To avoid triggering tap functionality
        temporarilyHideMenu() // Hide the menu while dragging
        
        // Get the touch in view, bound it to the room, and move the button there
        if let touch = event.touchesForView(button)?.anyObject() as? UITouch {
            let touchLoc = touch.locationInView(self.superview)
            center = boundCenterLocToRoom(touchLoc)
            if let handler = moveHandler {
                handler(top, left)
            }
        }
    }
    
    func boundCenterLocToRoom(centerLoc: CGPoint) -> CGPoint {
        var pt = CGPointMake(centerLoc.x, centerLoc.y)
        
        // Bound x inside of width
        if centerLoc.x < frame.size.width / 2 {
            pt.x = frame.size.width / 2
        } else if centerLoc.x > CGFloat(RoomWidth) - frame.size.width / 2 {
            pt.x = CGFloat(RoomWidth) - frame.size.width / 2
        }
        
        // Bound y inside of height
        if centerLoc.y < frame.size.height / 2 {
            pt.y = frame.size.height / 2
        } else if centerLoc.y > CGFloat(RoomHeight) - frame.size.height / 2 {
            pt.y = CGFloat(RoomHeight) - frame.size.height / 2
        }
        
        return pt
    }
    
    func boundLocToRoom(topLeftLoc: CGPoint) -> CGPoint {
        var pt = CGPointMake(topLeftLoc.x, topLeftLoc.y)
        
        // Bound x inside of width
        if topLeftLoc.x < frame.size.width / 2 {
            pt.x = frame.size.width / 2
        } else if topLeftLoc.x > CGFloat(RoomWidth) - frame.size.width {
            pt.x = CGFloat(RoomWidth) - frame.size.width
        }
        
        // Bound y inside of height
        if topLeftLoc.y < frame.size.height / 2 {
            pt.y = frame.size.height / 2
        } else if topLeftLoc.y > CGFloat(RoomHeight) - frame.size.height {
            pt.y = CGFloat(RoomHeight) - frame.size.height
        }
        
        return pt
    }
    
    // --- Methods for popping the menu up
    func touchUp(button: UIButton, withEvent event: UIEvent) {
        if dragging {
            dragging = false // This always ends drag events
            if !menuShowing {
                // Don't show menu at the end of dragging if there wasn't a menu to begin with
                return
            }
        }
        
        showMenu()
    }
    
    // --- Edit buttons were clicked
    func triggerRotate(sender: AnyObject) {
        if let handler = rotateHandler {
            handler()
        }
    }
    
    func triggerDelete(sender: AnyObject) {
        if let handler = deleteHandler {
            handler()
        }
    }
    
    // --- Menu helper methods
    
    func showMenu() {
        menuShowing = true
        let menuController = UIMenuController.sharedMenuController()
        
        // Set new menu location
        let targetRect = CGRectMake(0, 0, frame.size.width, 0)
        menuController.setTargetRect(targetRect, inView:self)
        
        // Set menu items
        menuController.menuItems = [
            UIMenuItem(title: "Rotate", action:Selector("triggerRotate:")),
            UIMenuItem(title: "Delete", action:Selector("triggerDelete:"))
        ]
        
        // Handle displaying and disappearing the menu
        becomeFirstResponder()
        menuController.setMenuVisible(true, animated: true)
        watchForMenuExited()
    }
    
    // Temporarily
    func temporarilyHideMenu() {
        let menuController = UIMenuController.sharedMenuController()
        menuController.setMenuVisible(false, animated:false)
    }
    
    // Watch for menu exited - handles the menuShowing state for cancels and such
    func watchForMenuExited() {
        if menuListener != nil {
            NSNotificationCenter.defaultCenter().removeObserver(menuListener!)
        }
        
        menuListener = NSNotificationCenter.defaultCenter().addObserverForName(UIMenuControllerWillHideMenuNotification, object:nil, queue: nil, usingBlock: {
            notification in
            if !self.dragging {
                self.menuShowing = false
            }
            NSNotificationCenter.defaultCenter().removeObserver(self.menuListener!)
        })
    }
    
    // UIResponder override methods
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return action == Selector("triggerRotate:") || action == Selector("triggerDelete:")
    }
}