//
//  KlaviyoNotification.swift
//  MixpanelPlayground
//
//  Created by Katherine Keuper on 7/14/16.
//  Copyright © 2016 Katherine Keuper. All rights reserved.
//

import Foundation

struct KlaviyoNotification {

    // Required 
    let id: String
    let type: NotificationStyle
    let title: String
    let body: String
    let isValidNotification: Bool
    let defaultTheme: String
    let image: KlaviyoNotificationImage
    var hasCustomStyling: Bool = false
    var hasActionButton: Bool = false
    var actionButton: KlaviyoButton?
    var direction: String?
    var style: KlaviyoStyle!

    init?(json: [String: AnyObject]) {
        guard let id = json[klaviyoNotificationID] as? String, let typeString = json[KLNotificationType] as? String,
            let title = json[KLNTitle] as? String, let body = json[KLNBody] as? String,
            let imageData = json[KLNImage] as? [String: AnyObject], let defaultTheme = json[KLNDefaultTheme] as? String
            else {
                return nil
        }
        
        if let hasStyle = json[KLNStyle] as? [String: AnyObject] {
            hasCustomStyling = true
            self.style = KlaviyoStyle(json: hasStyle)
        } else {
            self.style = KlaviyoStyle(theme: .Dark) // defaults to dark if no theme is specified
        }
        
        // Required Params
        self.id = id
        self.type = NotificationStyle(styleString: typeString)
        self.title = title
        self.body = body
        self.image = KlaviyoNotificationImage(json: imageData)
        self.isValidNotification = true
        self.defaultTheme = defaultTheme
        
        // Grab Custom Params
        if let actionButton = json[KLNActionButton] as? [String: AnyObject] {
            self.actionButton = KlaviyoButton(json: actionButton)
            self.hasActionButton = true
        }
        
        if self.type == .MiniScreen {
            let providedDirection = json[KLNDirection] as? String
            self.direction = (providedDirection != nil) ? providedDirection! : "bottom"
        }
    }
    
    /*
    Storyboards:
        KlaviyoNotificationWButton: full screen with deep linked button
        KlaviyoNotification: full screen notification
    */
    static func klaviyoNotificationStoryboard(isShowingActionButton: Bool, styleType: NotificationStyle) -> UIStoryboard {
        var storyboardname = isShowingActionButton ? "KlaviyoNotificationWButton" : "KlaviyoNotification" // default storyboard to use: ex. iPad
        
        if styleType == .MidScreen {
            storyboardname = isShowingActionButton ? "KlaviyoNotificationButtonMidSize" : "KlaviyoNotificationMidSize"
        } 
        
        /* TBD: If Storyboard's are designed correctly, might not need to have separate ones for landscape v. portrait*/
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            let isLandscape = UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation)
            if isLandscape {
                // use iPhone landscape
            } else {
                // use iPhone portrait
            }
        }
        
        /* Note that we will need to change the bundle once it becomes part of a separate library
         the main bundle will search in the app directory, but our storyboard will be included within our framework library
         */
        //NSBundle(forClass: ClassInTestTarget.self)
        let bundle = NSBundle(identifier: "org.cocoapods.KlaviyoSwift")
        return UIStoryboard(name: storyboardname, bundle: bundle)
    }
}

enum NotificationStyle: String {
    case FullScreen = "fullscreen"
    case MiniScreen = "miniscreen"
    case MidScreen = "midscreen"
    
    init(styleString: String) {
        let switchOnString = styleString.lowercaseString
        switch switchOnString {
        case "fullscreen":
            self = FullScreen
        case "midscreen":
            self = MidScreen
        default:
            self = MiniScreen
        }
    }
}




