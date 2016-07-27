//
//  KlaviyoNotificationViewController.swift
//  MixpanelPlayground
//
//  Created by Katherine Keuper on 7/15/16.
//  Copyright © 2016 Katherine Keuper. All rights reserved.
//  Base class of all Klaviyo In-App Messages
//  All messages have body + title + ability to dismiss
//  Image is optional
//  Action-Bar & buttons are dependent on style
//

import UIKit

class KlaviyoNotificationViewController: UIViewController {
    var notification: KlaviyoNotification!
    weak var delegate:KlaviyoNotificationDelegate?
    
    @IBOutlet var fullScreenView: UIView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageTitleLabel: UILabel!
    @IBOutlet weak var messageBodyLabel: UILabel!
    @IBOutlet weak var messageImage: UIImageView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var customButton: UIButton!
    
    @IBAction func dismissNotificationButton(sender: UIButton) {
        delegate?.didDismissNotificationViewController(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        if notification != nil && notification.type != .MiniScreen {
            updateUI()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    func updateUI() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(KlaviyoNotificationViewController.dismissNotificationButton))
        gesture.cancelsTouchesInView = false
        fullScreenView.addGestureRecognizer(gesture)
        
        // Message Content
        messageTitleLabel.text = notification.title
        messageBodyLabel.text = notification.body
        messageImage.image = notification.image.image
        
        // Message UI
        fullScreenView.backgroundColor = notification.style.backgroundColor
        messageView.backgroundColor = notification.style.overlayColor
        messageTitleLabel.font = notification.style.titleFont
        messageTitleLabel.textColor = notification.style.textColor
        messageBodyLabel.font = notification.style.messageBodyFont
        messageBodyLabel.textColor = notification.style.textColor
        dismissButton.setTitleColor(notification.style.textColor, forState: .Normal)
        
        // Update button if it exists
        if notification.hasActionButton && customButton != nil {
            customButton.addTarget(self, action: #selector(KlaviyoNotificationViewController.executeCustomAction), forControlEvents: .TouchUpInside)
            customButton.backgroundColor = notification.actionButton?.backgroundColor
            customButton.titleLabel?.textColor = notification.actionButton?.titleColor
            customButton.titleLabel?.text = notification.actionButton?.buttonText
            if let border = notification.actionButton?.border {
                customButton.layer.borderColor = border.borderColor.CGColor
                customButton.layer.borderWidth = border.borderWeight
                customButton.layer.cornerRadius = border.cornerRadius
            }
        }
        
        
        if let border = notification.style.border {
            messageView.layer.borderColor = border.borderColor.CGColor
            messageView.layer.borderWidth = border.borderWeight
            messageView.layer.cornerRadius = border.cornerRadius
        }
        
        // MidScreen notifications should override to a clear background
        if notification.type == .MidScreen {
            print("setting background color")
            print("notification color is: \(notification.style.backgroundColor)")
            fullScreenView.backgroundColor = UIColor.clearColor()
            print("background color: \(fullScreenView.backgroundColor)")
        }
    }
    
    func executeCustomAction() {
        delegate?.didDismissNotificationViewControllerWithAction(self)
        
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }


}

protocol KlaviyoNotificationDelegate: class {
    func didDismissNotificationViewController(sender: KlaviyoNotificationViewController?) -> Bool
    func didDismissNotificationViewControllerWithAction(sender: KlaviyoNotificationViewController?) -> Bool
}

