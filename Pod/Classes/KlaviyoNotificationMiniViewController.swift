//
//  KlaviyoNotificationMiniViewController.swift
//  MixpanelPlayground
//
//  Created by Katherine Keuper on 7/21/16.
//  Copyright © 2016 Katherine Keuper. All rights reserved.
//  All mini notifications are limited in their maximum height/line length
//

import UIKit

class KlaviyoNotificationMiniViewController : KlaviyoNotificationViewController{
    let MAX_HEIGHT: CGFloat = 80
    let MARGINS: CGFloat = 15
    
   // var notification: KlaviyoNotification!
   // weak var delegate: KlaviyoNotificationDelegate?
    
    var icon: UIImageView!
    var message: UILabel!
    var isCurrentlyBeingDismissed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Default values:
        view.backgroundColor = UIColor.blueColor()
        view.clipsToBounds = true
        view.layer.cornerRadius = 7.0
        
        // Add tap gesture recognizer
        let gestureRecognizer =  UITapGestureRecognizer(target: self, action: #selector(KlaviyoNotificationMiniViewController.didTapNotification))
        gestureRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gestureRecognizer)
        
        var frame: CGRect = CGRectZero
        if let hasParent = getParentFrameForContainer() {
            frame = hasParent.frame
        }

        self.view.frame = CGRect(x: 0, y: 0, width: frame.width - MARGINS, height: MAX_HEIGHT)
        print("created frame: \(self.view.frame)")
        
        // Initialize the views default values
        icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        //icon.frame = CGRectMake(0, 0, 25, 25)
        icon.contentMode = .ScaleAspectFit
        icon.layer.masksToBounds = true
        icon.clipsToBounds = true
        icon.image = UIImage(named: "about")
        icon.setContentHuggingPriority(1000, forAxis: .Vertical)
        icon.setContentHuggingPriority(1000, forAxis: .Horizontal)
        
        message = UILabel(frame: CGRectZero)
        message.backgroundColor = UIColor.clearColor()
        message.textColor = UIColor.whiteColor()
        message.font = UIFont(name: "Avenir", size: 13.0)
        message.numberOfLines = 0
        message.lineBreakMode = .ByTruncatingTail
        message.text = notification.body
        message.translatesAutoresizingMaskIntoConstraints = false

        
        // Add to the view
        self.view.addSubview(icon)
        self.view.addSubview(message)
        
        let iconConstraint = NSLayoutConstraint(item: icon, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 45)
        let iconConstraintHeight = NSLayoutConstraint(item: icon, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 45)
        icon.addConstraints([iconConstraint, iconConstraintHeight])
        
        let imageCenter = NSLayoutConstraint(item: icon, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1, constant: 0)
        let imageMarginLeft = NSLayoutConstraint(item: icon, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 10)
        let messageMarginLeft = NSLayoutConstraint(item: message, attribute: .Leading, relatedBy: .Equal, toItem: icon, attribute: .Trailing, multiplier: 1, constant: 10)
        let messageCenter = NSLayoutConstraint(item: message, attribute: .CenterY, relatedBy: .Equal, toItem: icon, attribute: .CenterY, multiplier: 1, constant: 0)
        let messageEnd = NSLayoutConstraint(item: message, attribute: .RightMargin, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1, constant: 20)
        let messageBottom = NSLayoutConstraint(item: message, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1, constant: 10)
        
        self.view.addConstraints([imageCenter, imageMarginLeft, messageMarginLeft, messageCenter, messageEnd, messageBottom])
        
        if notification.hasCustomStyling {
            if let border = notification.style.border {
                self.view.layer.cornerRadius = border.cornerRadius
                self.view.layer.borderColor = border.borderColor.CGColor
                self.view.layer.borderWidth = border.borderWeight
            }
        }

    }
    
    func didTapNotification() {
        print("user tapped notification")
        if let _ = notification.actionButton {
            delegate?.didDismissNotificationViewControllerWithAction(self)
            print("dismissing with action")
        } else {
            delegate?.didDismissNotificationViewController(self)
        }
    }
    
    /* 
        Grabs the main window subviews and iterates through to find the top most view of the stack that is visible
        Returns the top most view's frame
     */
    func getParentFrameForContainer() -> UIView? {
        var topView: UIView?
        if let views = UIApplication.sharedApplication().keyWindow?.subviews {
            for view in views {
                if !view.hidden && view.alpha > 0 && view.frame.size.width > 0 && view.frame.size.height > 0 {
                    topView = view
                }
            }
        }
        return topView
    }
    
    override func viewWillLayoutSubviews() {
        print("laying out subviews")
        /*
         
         */

        //
        
        // Add layout constraints

        /*
         let imageTop = NSLayoutConstraint(item: icon, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 10)
         let imageBottom = NSLayoutConstraint(item: icon, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1, constant: 10)
         let imageRight = NSLayoutConstraint(item: icon, attribute: .TrailingMargin, relatedBy: .Equal, toItem: message, attribute: .LeadingMargin, multiplier: 1, constant: 10)
         let messageTop = NSLayoutConstraint(item: message, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 10)
         let messageBottom = NSLayoutConstraint(item: message, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1, constant: 10)
         // let messageLeft = NSLayoutConstraint(item: message, attribute: .Leading, relatedBy: .Equal, toItem: icon, attribute: .Trailing, multiplier: 1, constant: 10)
         let messsageRight = NSLayoutConstraint(item: message, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1, constant: 10)
         icon.setContentHuggingPriority(300, forAxis: .Horizontal)
         icon.setContentCompressionResistancePriority(800, forAxis: .Horizontal)
         message.setContentHuggingPriority(300, forAxis: .Horizontal)
         message.setContentCompressionResistancePriority(800, forAxis: .Horizontal)
         self.view.addConstraints([imageMarginLeft, imageTop, imageRight, imageBottom, messageTop, messageBottom, messsageRight])*/
    }
    
    func animateView() {
        print("animating view")
        
        // if top move down from top of screen
        guard let topView = getParentFrameForContainer() else {
            return
        }
        
        topView.addSubview(self.view)
        
        print("added subview: \(self.view.frame)")
        // Set the starting point of the view based off the direction it is to come from
        var startingY = topView.frame.height
        var endingY = topView.frame.height - self.MAX_HEIGHT - self.MARGINS
        if let direction = notification.direction {
            startingY = (direction == "top") ? -(self.MAX_HEIGHT + self.MARGINS) : startingY
            endingY = (direction == "top") ? (self.MARGINS) : endingY
        }
        
        
        self.view.frame = CGRect(x: MARGINS, y:startingY, width: topView.frame.width - self.MARGINS, height: MAX_HEIGHT)
        
      //  let imageLeft = NSLayoutConstraint(item: icon, attribute: .LeftMargin, relatedBy: .Equal, toItem: self.view, attribute: .LeftMargin, multiplier: 1, constant: 10)
     //   self.view.addConstraint(imageLeft)
        //self.view.addConstraints([imageLeft, imageCenter])
        
        print("starting point: \(self.view.frame)")
        print("image frame: \(icon.frame)")
        UIView.animateWithDuration(0.3) {
            self.view.frame = CGRect(x: self.MARGINS, y: endingY, width: topView.frame.width - (self.MARGINS * 2), height: self.MAX_HEIGHT)
            print("endpoint: \(self.view.frame)")
            print("final image: \(self.icon.frame), image: \(self.icon.image?.size)")
        }
        // Top: start at (0, -self.height, width, height) move to (0, self.height + buffer, width, height)
        
        // if bottom move up from below screen
    }
    
    func dismissAnimation(duration: NSTimeInterval) {
        isCurrentlyBeingDismissed = true
        guard let topView = getParentFrameForContainer() else {
            return
        }
        
        // Set the starting point of the view based off the direction it is to come from
        var endingY = topView.frame.height + self.MAX_HEIGHT + self.MARGINS
        if let direction = notification.direction {
            endingY = (direction == "top") ? -(self.MAX_HEIGHT + self.MARGINS) : endingY
        }
        
        
        UIView.animateWithDuration(0.3) {
            self.view.frame = CGRect(x: self.MARGINS, y: endingY, width: self.view.frame.width, height: self.MAX_HEIGHT)
            self.isCurrentlyBeingDismissed = false
        }
    }
    
    override func dismiss() {
        print("dismissing: \(self.view.frame)")
        isCurrentlyBeingDismissed = true
        dismissAnimation(0.1)
    /*    guard let topView = getParentFrameForContainer() else {
            return
        }
        
        // Set the starting point of the view based off the direction it is to come from
        var endingY = topView.frame.height + self.MAX_HEIGHT + self.MARGINS
        if let direction = notification.direction {
            endingY = (direction == "top") ? -(self.MAX_HEIGHT + self.MARGINS) : endingY
        }
        
        
        UIView.animateWithDuration(0.3) {
            self.view.frame = CGRect(x: self.MARGINS, y: endingY, width: self.view.frame.width, height: self.MAX_HEIGHT)
        }
        */
        // navigate to new screen
    }



}
