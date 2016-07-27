//
//  KlaviyoNotificationElements.swift
//  MixpanelPlayground
//
//  Created by Katherine Keuper on 7/19/16.
//  Copyright © 2016 Katherine Keuper. All rights reserved.
//  This file holds all the custom UI + action components for in-app messages
//

import Foundation


/*
 Loads the provided image for full-screen & mid-screen messages
*/
class KlaviyoNotificationImage {
    var imageURL: String?
    var imagePath: String?
    var scale: Double?
    
    var image: UIImage? {
        if imageURL != nil {
            return self.loadImage(imageURL!)
        } else if imagePath != nil {
            return UIImage(named: imagePath!)
        } else {
            return nil
        }
    }
    
    func loadImage(urlString: String) -> UIImage? {
        guard let nsURL = NSURL(string: urlString) else {
            return nil
        }
        
        if let data = NSData(contentsOfURL: nsURL) {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    
    init(imageURL: String?, imagePath: String?, scale: Double?) {
        self.imageURL = imageURL
        self.imagePath = imagePath
        self.scale = scale
    }
    
    convenience init(json: [String: AnyObject]) {
        var scale: Double?
        var url: String?
        var path: String?
        
        if let useScale = json[KLNImageScale] as? Double {
            scale = useScale
        }
        
        if let useURL = json[KLNImageURL] as? String {
            url = useURL
        }
        
        if let usePath = json[KLNImagePath] as? String {
            path = usePath
        }
        
        self.init(imageURL: url, imagePath: path, scale: scale)
    }
    
    func setNotificationImage() -> UIImage? {
        if imagePath != nil {
            return UIImage(named: imagePath!)
        } else if image != nil {
            return image
        } else {
            return nil
        }
    }
    
}

extension UIColor {
    /* Custom helper method to instantiate a UIColor using the provided JSON payload */
    convenience init(json: [String: AnyObject]) {
        var red: CGFloat = 255
        var green: CGFloat = 255
        var blue: CGFloat = 255
        var alpha: CGFloat = 1.0
        if let hasR = json[KLNBgColorRed] as? Int {
            red = CGFloat(hasR)
        }
        if let hasG = json[KLNBgColorGreen] as? Int {
            green = CGFloat(hasG)
        }
        
        if let hasB = json[KLNBgColorBlue] as? Int {
            blue = CGFloat(hasB)
        }
        
        if let hasA = json[KLNBgColorAlpha] as? Double {
            alpha = CGFloat(hasA)
        }
        
        self.init(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
}

class KlaviyoButton {
    var deepLink: String?
    var buttonText: String = "OK"
    var buttonBorderRadius: Double = 1.0
    var hasDeepLink: Bool = false
    var border: KlaviyoBorder?
    var backgroundColor = UIColor.clearColor()
    var titleColor = UIColor.whiteColor()
    var titleText = "Ok"
    
    init(json:[String: AnyObject]) {
        customizeButtonUI(json)
    }
    
    func customizeButtonUI(json: [String: AnyObject]) {
        if let hasBG = json[KLNBackgroundColor] as? [String: AnyObject] {
            backgroundColor = UIColor(json: hasBG)
        }
        
        if let hasTextColor = json[KLNTextColor] as? [String: AnyObject] {
            self.titleColor = UIColor(json: hasTextColor)
        }
        
        if let hasTitle = json[KLNTitleText] as? String {
            self.titleText = hasTitle
        }
        
        if let borderJSON = json[KLNBorder] as? [String: AnyObject] {
            self.border = KlaviyoBorder(json: borderJSON)
        }
        
        if let deepLink = json[KLNDeepLink] as? String {
            self.deepLink = deepLink
        }
        
    }

}

/*
    Note: Mid-Screen Messages are actually just full-screen messages but with clear background views i.e. the bg color has 0 alpha
*/

/* Default layout for light screen full-screen views
    -> Any and all of these could be overidden by custom updates
    Background Color: UIColor.whiteColor()
    Overlay Color: UIColor.whiteColor()
    Font:
    Font-Size:
    Border:
    Alpha:
    Font-Color:
*/
class KlaviyoStyle {
    var backgroundColor = UIColor.whiteColor()
    var overlayColor = UIColor.whiteColor()
    var textColor = UIColor.blackColor()
    var titleFont = UIFont(name: "Avenir", size: 15.0)
    var messageBodyFont = UIFont(name: "Avenir", size: 13.0)
    var alpha: CGFloat = 1.0
    var hasBorder = false
    var border: KlaviyoBorder?

    init(theme: KlaviyoTheme) {
        if theme == .Dark {
            backgroundColor = UIColor.blackColor()
            overlayColor = UIColor.blackColor()
            textColor = UIColor.whiteColor()
        }
    }
    
    init(json: [String: AnyObject]) {
        if let bg = json[KLNBackgroundColor] as? [String: AnyObject] {
            self.backgroundColor = UIColor(json: bg)
        }
        
        if let textColor = json[KLNTextColor] as? [String: AnyObject] {
            self.textColor = UIColor(json: textColor)
        }
        
        if let overlayColor = json[KLNOverlayColor] as? [String: AnyObject] {
            self.overlayColor = UIColor(json: overlayColor)
        }
        
        if let fontString = json[KLNTitleFont] as? String, let newFont = UIFont(name: fontString, size: 15.0) {
            self.titleFont = newFont
        }
        
        if let messageFont = json[KLNMessageFont] as? String, let newFont = UIFont(name: messageFont, size: 13.0) {
            self.messageBodyFont = newFont
        }
        
        if let alpha = json[KLNBgColorAlpha] as? Double {
            self.alpha = CGFloat(alpha)
        }
        
        if let doesHaveBorder = json[KLNBorder] as? [String: AnyObject] {
            self.border = KlaviyoBorder(json: doesHaveBorder)
        }
        
    }
    
}

/*
    Enum used for notification customization when not provided in the payload
*/
enum KlaviyoTheme: String {
    case Light = "light"
    case Dark = "dark"
    
    init(theme: String) {
        switch theme.lowercaseString {
        case "light":
            self = Light
        default:
            self = Dark
        }
    }
}

class KlaviyoBorder {
    var cornerRadius: CGFloat!
    var borderColor: UIColor!
    var borderWeight: CGFloat!
    
    init(json: [String: AnyObject]) {
        guard let cR = json[KLNBorderRadius] as? Double, let borderColor = json[KLNBorderColor] as? [String: AnyObject],
            let borderWeight = json[KLNBorderWeight] as? Double else {
                self.cornerRadius = 0.0
                self.borderColor = UIColor.whiteColor()
                self.borderWeight = 1.5
                return
        }
        
        self.cornerRadius = CGFloat(cR)
        self.borderColor = UIColor(json: borderColor)
        self.borderWeight = CGFloat(borderWeight)
    }
    
}
