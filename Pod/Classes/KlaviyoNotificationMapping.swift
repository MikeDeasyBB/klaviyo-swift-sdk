//
//  KlaviyoNotificationMapping.swift
//  MixpanelPlayground
//
//  Created by Katherine Keuper on 7/26/16.
//  Copyright © 2016 Katherine Keuper. All rights reserved.
//
//  Constants that are used to map server returned JSON to a custom in-app message
//  If the returned JSON keys every change, must update this section

import Foundation

let klaviyoNotificationID = "$id"
let KLNotificationType = "$type"
let KLNDirection = "direction"
let KLNImage = "$image"
let KLNImageScale = "scale"
let KLNImagePath = "path"
let KLNImageURL = "url"
let KLNTitle = "$title"
let KLNBody = "$body"
let KLNDefaultTheme = "$default-theme"
let KLNStyle = "style"
let KLNBackgroundColor = "background-color"
let KLNBgColorRed = "$r"
let KLNBgColorGreen = "$g"
let KLNBgColorBlue = "$b"
let KLNBgColorAlpha = "$a"
let KLNTextColor = "text-color"
let KLNOverlayColor = "overlay-color"
let KLNTitleFont = "title-font"
let KLNMessageFont = "message-font"
let KLNBorder = "border"
let KLNBorderColor = "border-color"
let KLNBorderWeight = "border-weight"
let KLNBorderRadius = "border-radius"

/* Action Button Keys */
let KLNActionButton = "action-button"
let KLNDeepLink = "deep-link"
let KLNTitleText = "title-text"
let KLNActionTextColor = "text-color"

/*
 guard let id = json["id"] as? String, let messageID = json["messageID"] as? String,
 let typeString = json["type"] as? String, let title = json["title"] as? String,
 let body = json["body"] as? String, let imageData = json["image"] as? [String: AnyObject],
 let defaultTheme = json["default-theme"] as? String
 else {
 return nil
 }
 
 if let hasStyle = json["style"] as? [String: AnyObject] {
 hasCustomStyling = true
 self.style = KlaviyoStyle(json: hasStyle)
 } else {
 self.style = KlaviyoStyle(theme: .Dark) // defaults to dark if no theme is specified
 }
 
 // Required Params
 self.id = id
 self.messageID = messageID
 self.type = NotificationStyle(styleString: typeString)
 self.title = title
 self.body = body
 self.image = KlaviyoNotificationImage(json: imageData)
 self.isValidNotification = true
 self.defaultTheme = defaultTheme
 
 // Grab Custom Params
 if let actionButton = json["action-button"] as? [String: AnyObject] {
 self.actionButton = KlaviyoButton(json: actionButton)
 self.hasActionButton = true
 }
 
 if self.type == .MiniScreen {
 let providedDirection = json["direction"] as? String
 self.direction = (providedDirection != nil) ? providedDirection! : "bottom"
 }
*/