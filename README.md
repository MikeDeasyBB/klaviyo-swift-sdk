# KlaviyoSwift

[![CI Status](http://img.shields.io/travis/Katy Keuper/KlaviyoSwift.svg?style=flat)](https://travis-ci.org/Katy Keuper/KlaviyoSwift)
[![Version](https://img.shields.io/cocoapods/v/KlaviyoSwift.svg?style=flat)](http://cocoapods.org/pods/KlaviyoSwift)
[![License](https://img.shields.io/cocoapods/l/KlaviyoSwift.svg?style=flat)](http://cocoapods.org/pods/KlaviyoSwift)
[![Platform](https://img.shields.io/cocoapods/p/KlaviyoSwift.svg?style=flat)](http://cocoapods.org/pods/KlaviyoSwift)

## Overview

KlaviyoSwift is an SDK, written in Swift, for users to incorporate Klaviyo's event tracking functionality into iOS applications. We also provide an SDK written in [Objective-C](https://github.com/klaviyo/klaviyo-objc-sdk). The two SDKs are identical in their functionality.

## Requirements
*iOS 8.0
*Swift 2.0 & XCode 7.0

## Installation with CocoaPods

KlaviyoSwift is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "KlaviyoSwift"
```

## Example Usage: Event Tracking

To run the example project, clone the repo, and run `pod install` from the Example directory first. 

```swift

    Klaviyo.setupWithPublicAPIKey("YOUR_PUBLIC_API_KEY")

    let klaviyo = Klaviyo.sharedInstance

    let customerDictionary : NSMutableDictionary = NSMutableDictionary()
    customerDictionary[klaviyo.KLPersonEmailDictKey] = "john.smith@example.com"
    customerDictionary[klaviyo.KLPersonFirstNameDictKey] = "John"
    customerDictionary[klaviyo.KLPersonLastNameDictKey] = "Smith"

    let propertiesDictionary : NSMutableDictionary = NSMutableDictionary()
    propertiesDictionary["Total Price"] = 10.99
    propertiesDictionary["Items Purchased"] = ["Milk","Cheese", "Yogurt"]
    Klaviyo.sharedInstance.trackEvent("Completed Checkout", customerProperties: customerDictionary, properties: propertiesDictionary)
```

## Argument Description

The `track` function can be called with anywhere between 1-4 arguments:

`eventName` This is the name of the event you want to track. It can be any string. At a bare minimum this must be provided to track and event.

`customer_properties` (optional, but recommended) This is a NSMutableDictionary of properties that belong to the person who did the action you're recording. If you do not include an $email or $id key, the user will be tracked by an $anonymous key.

`properties` (optional) This is a NSMutableDictionary of properties that are specific to the event. In the above example we included the items purchased and the total price.

`eventDate` (optional) This is the timestamp (an NSDate) when the event occurred. You only need to include this if you're tracking past events. If you're tracking real time activity, you can ignore this argument.

## Special Properties

As was shown in the event tracking example, special person and event properties can be used. This works in a similar manner to the [Klaviyo Analytics API](https://www.klaviyo.com/docs). These are special properties that can be utilized when identifying a user or event. They are:
    
    *KLPersonEmailDictKey 
    *KLPersonFirstNameDictKey
    *KLPersonLastNameDictKey
    *KLPersonPhoneNumberDictKey
    *KLPersonTitleDictKey
    *KLPersonOrganizationDictKey
    *KLPersonCityDictKey
    *KLPersonRegionDictKey
    *KLPersonCountryDictKey
    *KLPersonZipDictKey
    *KLEventIDDictKey
    *KLEventValueDictKey

## Author

Katy Keuper, katy.keuper@klaviyo.com

## License

KlaviyoSwift is available under the MIT license. See the LICENSE file for more info.
