//
//  Klaviyo.swift
//
//  Created by Katherine Keuper on 9/14/15.
//  Copyright (c) 2015 Klaviyo. All rights reserved.
//


import Foundation
import UIKit

public class Klaviyo : NSObject, KlaviyoNotificationDelegate {
    
    /*
     Klaviyo Class Constants
     */
    #if RELEASE_VERSION
    let KlaviyoServerURLString = "https://a.klaviyo.com/api"
    let inAppMessageServerString = "https://a.klaviyo.com/mobile/in-app-messages/recent?"
    #else
    let KlaviyoServerURLString = "https://b966dc7c.ngrok.io/api" // can use local-klaviyo if you are only testing on the simulator
    let inAppMessageServerString = "https://b966dc7c.ngrok.io/mobile/in-app-messages/recent?"
    #endif
    
    // Create the singleton instance
    public static let sharedInstance = Klaviyo()
    
    /*
     Klaviyo JSON Key Constants
     */
    
    // KL Definitions File: JSON Keys for Tracking Events
    let KLEventTrackTokenJSONKey = "token"
    let KLEventTrackEventJSONKey = "event"
    let KLEventTrackCustomerPropetiesJSONKey = "customer_properties" //must use id or email
    let KLEventTrackingServiceKey = "service"
    
    //Optional Event Tracking Properties
    let KLEventTrackPropertiesJSONKey = "properties"
    let KLEventTrackTimeJSONKey = "time"
    public let KLEventTrackPurchasePlatform = "platform"
    
    // KL Definitions File: JSON Keys for Tracking People
    let KLPersonTrackTokenJSONKey = "token"
    let KLPersonPropertiesJSONKey = "properties" // same as customer properties
    
    // Push Notification Event Tracking
    public let KLPersonReceivedPush = "Received Push"
    public let KLPersonOpenedPush = "$opened_push"
    public let KLMessageDimension = "$message"
    
    // KL Definitions File: API URL Constants
    let KlaviyoServerTrackEventEndpoint = "/track"
    let KlaviyoServerTrackPersonEndpoint = "/identify"
    
    
    /*
     Current API WorkAround: Update this once the $anonymous in place
     */
    let CustomerPropertiesIDDictKey = "$anonymous"
    
    let CustomerPropertiesAppendDictKey = "$append"
    let CustomerPropertiesAPNTokensDictKey = "$ios_tokens" //tokens for push notification
    let KLRegisterAPNDeviceTokenEvent = "KL_ReceiveNotificationsDeviceToken"
    
    // Track event special info dict keys
    let KLEventIDDictKey = "$event_id" // unique identifier for an event
    let KLEventValueDictKey = "$value" // a numeric value to associate with this special event
    
    // Track person special info dict keys
    let KLPersonIDDictKey = "$id" // your unique identifier for a person
    private let KLCustomerIDNSDefaults = "$kl_customerID"
    let KLPersonDeviceIDDictKey = "$device_id"
    private let KLTimezone = "Mobile Timezone"
    
    // Public Info Dictionary Keys
    public let KLPersonEmailDictKey = "$email" // email address
    private let KLEmailNSDefaultsKey = "$kl_email"
    public let KLPersonFirstNameDictKey = "$first_name" // first name
    public let KLPersonLastNameDictKey = "$last_name" // last name
    public let KLPersonPhoneNumberDictKey = "$phone_number" // phone number
    public let KLPersonTitleDictKey = "$title" // title at their business or organization
    public let KLPersonOrganizationDictKey = "$organization" // business or organization they belong to
    public let KLPersonCityDictKey = "$city" // city they live in
    public let KLPersonRegionDictKey = "$region" // region or state they live in
    public let KLPersonCountryDictKey = "$country" // country they live in
    public let KLPersonZipDictKey = "$zip" // postal code where they live
    
    /*
     Shared Instance Variables
     */
    var apiKey : String?
    var apnDeviceToken : String?
    var userEmail : String = ""
    var serialQueue : dispatch_queue_t!
    var eventsQueue : NSMutableArray?
    var peopleQueue : NSMutableArray?
    var urlSession : NSURLSession?
    var reachability : Reachability?
    var remoteNotificationsEnabled : Bool?
    let urlSessionMaxConnection = 5
    var showNetworkActivityIndicator : Bool = true
    
    private var isCheckingForInAppMessages: Bool = false
    private var newNotification: KlaviyoNotification?
    
    /*
     Computed property for iOSIDString
     :returns: A unique string that represents the device using the application
     This is only unique for the lifetime of the application. If a user uninstalls and reinstalls the app this value will change
     There is currently no way to identify devices across app installs
     */
    var iOSIDString : String {
        return "iOS:" + UIDevice.currentDevice().identifierForVendor!.UUIDString
    }
    
    /*
     Singleton Initializer. Must be kept private as only one instance can be created.
     */
    private override init() {
        super.init()
        
        // Dev warnings for incorrect iOS version
        assert(isOperatingMinimumiOSVersion() == true, "operating outdated iOS version. requires >= ios 8")
        // Dev warnings for nil api keys
        assert(apiKey == nil, "api key is nil")
        
        // Create the queue
        serialQueue = dispatch_queue_create("com.klaviyo.serialQueue", DISPATCH_QUEUE_SERIAL)
        
        // Configure the URL Session
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.allowsCellularAccess = true
        config.HTTPMaximumConnectionsPerHost = urlSessionMaxConnection
        urlSession = NSURLSession(configuration: config)
        reachability = Reachability(hostname: "www.klaviyo.com")
    }
    
    /**
     setupWithPublicAPIKey: sets up the Klaviyo iOS SDK for use in the application. Should be called once upon initial application setup in the AppDelegate didFinishLaunchingWithOptions: Requires an account ID, which can be accessed through Klaviyo.com.
     
     - Parameter apiKey: string representation of the Klaviyo API Key
     */
    public class func setupWithPublicAPIKey(apiKey : String) {
        sharedInstance.apiKey = apiKey
        sharedInstance.unarchive()
        sharedInstance.flush()
        sharedInstance.addNotificationObserver()
    }
    
    /**
     setUpUserEmail: Register the current user's email address with Klaivyo. This can also be done via passing a dictionary containing a user's email to trackEvent.
     
     - Parameter userEmail: the user's email address
     */
    public func setUpUserEmail(userEmail :String) {
        self.userEmail = userEmail
        
        /* Save to nsuser defaults */
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(userEmail, forKey: KLEmailNSDefaultsKey)
    }
    
    
    /*
     setUpCustomerID: Register the current customer ID and saves it
     If this is called once, there is no need to pass in identifiying dictionaries to tracked events
     */
    public func setUpCustomerID(id: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(id, forKey: KLCustomerIDNSDefaults)
    }
    
    /**
     handlePush: Extracts tracking information from received push notification and sends the data to Klaviyo for push-tracking
     analystics.
     
     - Parameter userInfo: NSDictionary containing the push notification text & metadata
     */
    public func handlePush(userInfo: [NSObject: AnyObject]) {
        if let metadata = userInfo["_k"] as? [NSObject: AnyObject] {
            if let hasDeepLink = userInfo["dl"] as? String {
                handleDeepLink(hasDeepLink)
            }
            
            // Track the push open
            trackEvent(KLPersonOpenedPush, properties: metadata)
        } else {
            trackEvent(KLPersonOpenedPush, properties: userInfo)
        }
    }
    
    private func handleDeepLink(urlString: String) {
        guard let url = NSURL(string: urlString) where UIApplication.sharedApplication().canOpenURL(url) else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    /**
     trackEvent: KL Event tracking for event name only
     
     - Parameter eventName: name of the event
     */
    public func trackEvent(eventName : String?) {
        trackEvent(eventName, properties: nil)
    }
    
    /**
     trackEvent: KL Event tracking for event name and customer properties
     
     - Parameter eventName: name of the event
     - Parameter properties: customerProperties
     */
    public func trackEvent(eventName : String?, properties : NSDictionary?) {
        trackEvent(eventName, customerProperties: nil, properties: properties)
    }
    
    /**
     trackEvent: KL Event tracking for event name, customer & event properties
     
     - Parameter eventName: name of the event
     - Parameter customerPropertiesDict: dictionary for user info
     - Parameter properties: dictionary for event info
     */
    public func trackEvent(eventName: String?, customerProperties: NSDictionary?, properties: NSDictionary?) {
        trackEvent(eventName, customerProperties: customerProperties, propertiesDict: properties, eventDate: nil)
    }
    
    /**
     trackEvent: KL Event tracking using all possible parameters
     
     - Parameter eventName: name of the event
     - Parameter customerPropertiesDict: dictionary for user info
     - Parameter propertiesDict: dictionary for event info
     - Parameter eventDate: date of the event
     */
    public func trackEvent(event: String?, customerProperties: NSDictionary?, propertiesDict: NSDictionary?, eventDate: NSDate?) {
        
        var eventName = event
        // Set default track name if none provided
        if (eventName == nil || eventName!.isEmpty) { eventName = "KL_Event" }
        
        // Check both dictionaries
        let customerPropertiesDict = updatePropertiesDictionary(customerProperties)
        assertPropertyTypes(propertiesDict)
        
        dispatch_async(self.serialQueue!, {
            let event = NSMutableDictionary()
            
            // Set the apiKey for the event
            if (self.apiKey!.characters.count > 0) {
                event[self.KLEventTrackTokenJSONKey] = self.apiKey
            } else {
                event[self.KLEventTrackTokenJSONKey] = ""
            }
            
            // If it's a push event, set a service key to Klaviyo
            var service: String = "api"
            if eventName == self.KLPersonReceivedPush || eventName == self.KLPersonOpenedPush {
                service = "klaviyo"
            }
            
            // Set the event info
            event[self.KLEventTrackEventJSONKey] = eventName
            event[self.KLEventTrackCustomerPropetiesJSONKey] = customerPropertiesDict
            event[self.KLEventTrackingServiceKey] = service
            
            if propertiesDict?.allKeys.count > 0 { event[self.KLEventTrackPropertiesJSONKey] = propertiesDict }
            
            if eventDate != nil { event[self.KLEventTrackTimeJSONKey] = eventDate }
            
            // Add the event to the queue
            self.eventsQueue!.addObject(event)
            
            if self.eventsQueue!.count > 500 {
                self.eventsQueue!.removeObjectAtIndex(0)
            }
            
            if self.inBackground() {
                self.archiveEvents()
            }
            // execute
            self.flushEvents()
        })
    }
    
    /**
     emailAddressExists: internal helper function that checks if email has been passed in via the setUpUserEmail method
     
     - Returns: true if the email exists, false otherwise
     */
    func emailAddressExists()->Bool {
        return (self.userEmail.characters.count > 0) ?? false
    }
    
    /*
     getEmailAdress: executed internally, and only after checking if email address exists
     */
    private func getEmailAddress() -> String {
        if emailAddressExists() {
            return self.userEmail
        } else if let savedEmail = NSUserDefaults.standardUserDefaults().valueForKey(KLEmailNSDefaultsKey) as? String{
            return savedEmail
        }
        return ""
    }
    
    /**
     trackPersonWithInfo: method that creates a Klaviyo person tracking instance that is separate from an event
     
     - Parameter personInfoDictionary: dictionary of user attributes that you wish to track. These can be special properties provided by Klaviyo, such as KLPersonFirstNameDictKey, or created by the user on the fly.
     
     - Returns: Void
     */
    public func trackPersonWithInfo(personDictionary: NSDictionary) {
        // No info, return
        if personDictionary.allKeys.count == 0 {
            return
        }
        // Update properties for JSON encoding
        let personInfoDictionary = updatePropertiesDictionary(personDictionary)
        assertPropertyTypes(personInfoDictionary)
        
        dispatch_async(self.serialQueue!, {
            let event = NSMutableDictionary()
            
            if self.apiKey!.characters.count > 0 {
                event[self.KLPersonTrackTokenJSONKey] = self.apiKey
            } else {
                event[self.KLPersonTrackTokenJSONKey] = ""
            }
            
            event[self.KLPersonPropertiesJSONKey] = personInfoDictionary
            self.peopleQueue!.addObject(event)
            
            if self.peopleQueue!.count > 500 {
                self.peopleQueue!.removeObjectAtIndex(0)
            }
            
            if self.inBackground() {
                self.archivePeople()
            }
            
            self.flushPeople()
        })
    }
    
    /**
     addPushDeviceToken: Registers Klaviyo with Apple Push Notifications (APN)
     Private function creates a unique identifier for the device and uses it to track the event
     
     - Parameter deviceToken: token provided by Apple that registers push notifications to the given device
     - Returns: Void
     */
    public func addPushDeviceToken(deviceToken: NSData) {
        
        let characterSet = NSCharacterSet(charactersInString: "<>")
        let trimEnds = deviceToken.description.stringByTrimmingCharactersInSet(characterSet)
        let cleanToken = trimEnds.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        apnDeviceToken = cleanToken
        
        if apnDeviceToken != nil {
            let personInfoDictionary : NSMutableDictionary = NSMutableDictionary()
            personInfoDictionary[CustomerPropertiesAppendDictKey] = [CustomerPropertiesAPNTokensDictKey: apnDeviceToken!]
            trackPersonWithInfo(personInfoDictionary)
        }
    }
    
    
    
    /**
     updatePropertiesDictionary: Internal function that configures the properties dictionary so that it holds the minimum info needed to track events and users
     - Parameter propertiesDictionary: dictionary of properties passed in for a given event or user. May be nil if no parameters are given.
     - Returns: Void
     */
    private func updatePropertiesDictionary(propDictionary: NSDictionary?)->NSDictionary {
        var propertiesDictionary = propDictionary
        if propertiesDictionary == nil {
            propertiesDictionary = NSMutableDictionary()
        }
        
        let returnDictionary = propertiesDictionary as! NSMutableDictionary
        
        if emailAddressExists() && returnDictionary[KLPersonEmailDictKey] == nil {
            // if setUpUserEmail has been called & a new value has not been provided; use the passed value
            returnDictionary[KLPersonEmailDictKey] = self.userEmail
        } else if let newEmail = returnDictionary[KLPersonEmailDictKey] {
            // if user provides an email address that takes precendence; save it to defaults & use
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(newEmail, forKey: KLEmailNSDefaultsKey)
        } else if let savedEmail = NSUserDefaults.standardUserDefaults().valueForKey(KLEmailNSDefaultsKey) as? String {
            // check NSuserDefaults for a stored value
            returnDictionary[KLPersonEmailDictKey] = savedEmail
        }
        
        // Set the $anonymous property in case there i sno email address
        returnDictionary[CustomerPropertiesIDDictKey] = self.iOSIDString
        
        // Set the $id if it exists
        if let idExists = returnDictionary[KLPersonIDDictKey] {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(idExists, forKey: KLCustomerIDNSDefaults)
        } else if let customerID =  NSUserDefaults.standardUserDefaults().valueForKey(KLCustomerIDNSDefaults) as? String {
            returnDictionary[KLPersonIDDictKey] = customerID
        }
        
        // Set the user's timezone: Note if the customer exists this will override their current profile
        // Alternatively, could create a customer mobile timezone property instead using a different key
        let timezone = NSTimeZone.localTimeZone().name
        returnDictionary[KLTimezone] = timezone
        
        // If push notifications are used, append them
        if apnDeviceToken != nil {
            returnDictionary[CustomerPropertiesAppendDictKey] = [CustomerPropertiesAPNTokensDictKey : apnDeviceToken!]
        }
        
        return returnDictionary
    }
    
    /**
     assertPropretyTypes: Internal alert function for development purposes. Asserts an error if dictionary types are of incorrect type for JSON encoding. Doesn't return a value but will assert an error during development.
     
     - Parmeter properties: the dictionary of property values
     - Returns: Void
     */
    private func assertPropertyTypes(properties: NSDictionary?) {
        guard let _ = properties as NSDictionary! else {
            return
        }
        
        for (k, _) in properties! {
            assert(properties![k as! NSCopying]!.isKindOfClass(NSString) || properties![k as! NSCopying]!.isKindOfClass(NSNumber) || properties![k as! NSCopying]!.isKindOfClass(NSNull) || properties![k as! NSCopying]!.isKindOfClass(NSArray) || properties![k as! NSCopying]!.isKindOfClass(NSDictionary)
                || properties![k as! NSCopying]!.isKindOfClass(NSDate) || properties![k as! NSCopying]!.isKindOfClass(NSURL)
                , "Property values must be of NSString, NSNumber, NSNull, NSDictionary, NSDate, or NSURL. Got: \(properties![k as! NSCopying])")
        }
    }
    
    /**
     addNotificationObserver: sets up notification observers for various application state changes
     */
    func addNotificationObserver() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(Klaviyo.applicationDidBecomeActiveNotification(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(Klaviyo.applicationDidEnterBackgroundNotification(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)), name: UIApplicationWillTerminateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(Klaviyo.hostReachabilityChanged(_:)), name: ReachabilityChangedNotification , object: nil)
    }
    
    /**
     isOperatingMinimumiOSVersion: internal alert function for development purposes. Asserts an error if the application is running an OS system below 8.0.0.
     
     - Returns: A boolean value where true means the os is compatible and the SDK can be used
     */
    private func isOperatingMinimumiOSVersion()->Bool {
        return NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 8, minorVersion: 0, patchVersion: 0)) ?? false
    }
    
    /**
     removeNotificationObserver() removes the observers that are set up upon instantiation.
     */
    func removeNotificatoinObserver() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, forKeyPath: UIApplicationDidBecomeActiveNotification)
        notificationCenter.removeObserver(self, forKeyPath: UIApplicationDidEnterBackgroundNotification)
        notificationCenter.removeObserver(self, forKeyPath: UIApplicationWillTerminateNotification)
        notificationCenter.removeObserver(self, forKeyPath: ReachabilityChangedNotification)
    }
    
    func removeNotificationsObserver() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self)
    }
    
    func applicationDidBecomeActiveNotification(notification: NSNotification) {
        reachability?.startNotifier()
        
        /* 7/16: New Feature - checks for in app messages, if there is one, show it */
        checkForInAppMessages { result in
            if result && self.newNotification != nil {
                
                if self.newNotification!.type == NotificationStyle.MiniScreen {
                    self.showMiniNotification()
                } else {
                    self.showFullScreenNotification()
                }
            }
        }
    }
    
    func applicationDidEnterBackgroundNotification(notification: NSNotification){
        reachability?.stopNotifier()
    }
    
    func applicationWillTerminate(notification : NSNotification) {
        archive()
    }
    
    /*
     New Feature: 07/16: In-App Messages
     */
    func checkForInAppMessages(completionHandler: (result: Bool) -> Void)  {
        /* Make sure the app is not already querying for the data */
        if isCheckingForInAppMessages {
            completionHandler(result: false)
            return
        }
        
        isCheckingForInAppMessages = true
        
        var fullURL = inAppMessageServerString
        
        // add customer information + company API Key to the params
        if let email = getEmailAddress().stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            where !email.isEmpty {
            fullURL += "email=" + email + "&"
        }
        
        if let anonymous = iOSIDString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
            fullURL += "anonymous=" + anonymous + "&"
        }
        
        if let key = apiKey {
            fullURL += "id=" + key
        }
        
        
        var requestSuccess: Bool = false
        
        guard let session = urlSession, let url = NSURL(string: fullURL) else {
            completionHandler(result: false)
            return
        }
        
        let request = NSMutableURLRequest(URL: url)
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.HTTPMethod = "GET"
        
        /* Optional, but good practice to alert the user that data is being retrieved in the status bar */
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        /* Check for any in-app messages */
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request) { data, response, error in
            
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            
            if let _ = error {
                requestSuccess = false
            } else if let httpResponse = response as? NSHTTPURLResponse, let hasData = data where httpResponse.statusCode == 200 {
                
                do {
                    // Serialize the returned data into JSON
                    guard let json = try NSJSONSerialization.JSONObjectWithData(hasData, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject], let jsonData = json["data"] as? [String : [AnyObject]],
                        let notifications = jsonData["notifications"] else {
                            completionHandler(result: false)
                            return
                    }
                    
                    if notifications.isEmpty || notifications.count == 0 {
                        completionHandler(result: false)
                        return
                    }
                    
                    let first = notifications[0]
                    
                    if first is [String: AnyObject] {
                        let notification = KlaviyoNotification(json: (first as? [String: AnyObject])!)
                        self.newNotification = notification
                        requestSuccess = true
                        completionHandler(result: true)
                        return
                    }
                } catch {
                    // this means our server returned invalid json
                    requestSuccess = false
                }
                
            }
            self.isCheckingForInAppMessages = false
        }
        
        task.resume()
        completionHandler(result: requestSuccess)
    }
    
    func showMiniNotification() {
        
        guard let notification = newNotification, let presentingVC = topPresentedViewController() where
            !canPresentFromViewController(presentingVC) else {
                return
        }
        
        // Create the mini view controller
        let miniVC = KlaviyoNotificationMiniViewController()
        
        // Set the notification
        miniVC.notification = notification
        miniVC.delegate = self
        
        // Animate the view, wait for certain amount of time, then dismiss the view
        // This has to be done on the main thread, otherwise it risks crashing the app
        dispatch_async(dispatch_get_main_queue()) {
            miniVC.animateView()
            
            // Animate the view out after 4 seconds
            let wait = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 4 * Int64(NSEC_PER_SEC))
            dispatch_after(wait, dispatch_get_main_queue()) {
                if !miniVC.isCurrentlyBeingDismissed {
                    miniVC.dismissAnimation(0.3)
                }
            }
        }
    }
    
    /*
     This function grabs the current view controller and creates the full screen notification
     */
    func showFullScreenNotification() {
        print("showing full screen notification")
        guard let presentingVC = topPresentedViewController(), let showNotification = newNotification
            where canPresentFromViewController(presentingVC) else {
                print("returning")
                return
        }
        
        let storyboard = KlaviyoNotification.klaviyoNotificationStoryboard(showNotification.hasActionButton, styleType: showNotification.type)
        
        guard let klaviyoNotificationController = storyboard.instantiateViewControllerWithIdentifier("klaviyoNotificationVC") as? KlaviyoNotificationViewController else {
            print("failed to instantiate vc")
            return
        }
        
        // set the notification & the delegate
        klaviyoNotificationController.notification = showNotification
        klaviyoNotificationController.delegate = self
        print("showing to user")
        // present the notification
        presentingVC.modalPresentationStyle = .OverCurrentContext
        klaviyoNotificationController.modalPresentationStyle = .OverCurrentContext
        presentingVC.presentViewController(klaviyoNotificationController, animated: true, completion: nil)
    }
    
    func didDismissNotificationViewControllerWithAction(sender: KlaviyoNotificationViewController?) -> Bool {
        /* Sanity check that sender and notification exist and unwrap optionals */
        if sender == nil || (newNotification == nil && sender?.notification == nil) ||
            sender?.notification.actionButton?.deepLink == nil {
            sender?.dismiss()
            return false
        }
        
        if let urlString = sender?.notification.actionButton?.deepLink, let url = NSURL(string: urlString) {
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        
        sender?.dismiss()
        return true
    }
    
    /*
     func didDismissNotificationViewController(sender: KlaviyoNotificationViewController) -> Bool
     
     */
    func didDismissNotificationViewController(sender: KlaviyoNotificationViewController?) -> Bool {
        // if the sender is nil or notification does not exist, there is nothing to dismiss
        if sender == nil || (newNotification == nil  || sender?.notification == nil) {
            return false
        }
        
        
        //isShowingNotification = false
        newNotification = nil
        
        // TBD: if deep linking if the user selected the call to action, then take the user there
        
        // else, close the animation
        sender?.dismiss()
        return true
    }
    
    /* Grabs the current view controller on the user's screen in order to present an in app message */
    private func topPresentedViewController() -> UIViewController? {
        var topController: UIViewController
        guard let controller = UIApplication.sharedApplication().keyWindow?.rootViewController else {
            return nil
        }
        topController = controller
        while((controller.presentedViewController) != nil) {
            topController = controller.presentedViewController!
        }
        return topController
    }
    
    /* Checks that the status of the app will allow the user to present a message*/
    private func canPresentFromViewController(vc:  UIViewController) -> Bool {
        if vc.isBeingDismissed() || vc.isBeingPresented() {
            return false
        }
        if vc.isKindOfClass(UIAlertController) {
            return false
        }
        return true
    }
    
    //: Persistence Functionality
    
    /**
     filePathForData: returns a string representing the filepath where archived event queues are stored
     
     - Parameter data: name representing the event queue to locate (will be either people or events)
     - Returns: filePath string representing the file location
     */
    private func filePathForData(data: String)->String {
        let fileName = "/klaviyo-\(apiKey!)-\(data).plist"
        let directory = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true).last
        let filePath = directory!.stringByAppendingString(fileName)
        return filePath
    }
    
    // Helper functions
    private func eventsFilePath()->String {
        return filePathForData("events")
    }
    
    private func peopleFilePath()->String{
        return filePathForData("people")
    }
    
    /*
     archiveEvents: copies the event queue and archives it to the appropriate directory location
     */
    private func archiveEvents() {
        let filePath = eventsFilePath()
        let eventsQueueCopy = eventsQueue!
        if !NSKeyedArchiver.archiveRootObject(eventsQueueCopy, toFile: filePath) {
            /* TBA: log this error */
        }
    }
    /*
     archivePeople: copies the people queue and archives it to the appropriate directory location
     */
    private func archivePeople() {
        let filePath = peopleFilePath()
        let peopleQueueCopy : NSMutableArray = peopleQueue!
        if !NSKeyedArchiver.archiveRootObject(peopleQueueCopy, toFile: filePath) {
            print("unable to archive the people data")
        }
    }
    
    private func archive() {
        archiveEvents()
        archivePeople()
    }
    
    private func unarchive() {
        unarchiveEvents()
        unarchivePeople()
    }
    
    private func unarchiveEvents() {
        eventsQueue = unarchiveFromFile(eventsFilePath()) as! NSMutableArray?
        if eventsQueue == nil { eventsQueue = NSMutableArray() }
    }
    
    private func unarchivePeople() {
        peopleQueue = unarchiveFromFile(peopleFilePath()) as! NSMutableArray?
        if peopleQueue == nil { peopleQueue = NSMutableArray() }
    }
    
    /**
     unarchiveFromFile: takes a file path of store data and attempts to
     */
    private func unarchiveFromFile(filePath: String)-> AnyObject? {
        var unarchivedData : AnyObject? = nil
        
        unarchivedData =  NSKeyedUnarchiver.unarchiveObjectWithFile(filePath)
        
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            var removed: Bool
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(filePath)
                removed = true
            }
            catch {
                removed = false
            }
            if !removed {print("Unable to remove archived data!")}
            return unarchivedData
        }
        return unarchivedData
    }
    
    // MARK: Application Helpers
    private func inBackground()->Bool {
        return UIApplication.sharedApplication().applicationState == UIApplicationState.Background
    }
    
    private func updateNetworkActivityIndicator(on : Bool) {
        if showNetworkActivityIndicator {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = on
        }
    }
    
    
    //: MARK: Network Control
    
    /*
     Internal function that initiates the flushing of data
     */
    private func flush() {
        
        flushEvents()
        flushPeople()
    }
    
    private func flushEvents() {
        dispatch_async(self.serialQueue!, {
            self.flushQueue(self.eventsQueue!, endpoint: self.KlaviyoServerTrackEventEndpoint)
        })
    }
    
    private func flushPeople() {
        dispatch_async(self.serialQueue!, {
            self.flushQueue(self.peopleQueue!, endpoint: self.KlaviyoServerTrackPersonEndpoint)
        })
    }
    
    /**
     flushQueue: Iterates through an array of events and produces the relevant API request
     - Parameter queue: an array of events
     - Parameter endpoint: the api endpoint
     */
    private func flushQueue(queue: NSMutableArray, endpoint: String) {
        
        if !isHostReachable() {
            return
        }
        
        let currentQueue : NSArray = queue
        
        
        for item in currentQueue {
            let i = item as! NSDictionary
            
            //Encode the parameters
            let requestParamData = encodeAPIParamData(i)
            let param = "data=\(requestParamData)"
            
            //Construct the API Request
            let request = apiRequestWithEndpoint(endpoint, param: param)
            updateNetworkActivityIndicator(true)
            
            //Execute
            let task : NSURLSessionDataTask = urlSession!.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                dispatch_async(self.serialQueue!, {
                    if(error != nil) {
                        print("network failure: \(error)")
                    } else {
                        let response = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        if response!.intValue == 0 {
                            print("api rejected item: \(endpoint), \(i)")
                        }
                        queue.removeObject(i)
                    }
                    if queue.count == 0 {
                        self.updateNetworkActivityIndicator(false)
                    }
                })
            })
            task.resume()
        }
    }
    
    
    /**
     apiRequestWithEndpoint: Internal function that returns an NSURLRequest for the Klaviyo Server
     - Parameter endpoint: String representing the type of event (track or identify)
     - Parameter param: String representing the properties of the event or the identify call
     - Returns: an NSURLRequest for the API call
     */
    private func apiRequestWithEndpoint(endpoint : String, param: String)-> NSURLRequest {
        let urlString = KlaviyoServerURLString+endpoint+"?"+param
        let url = NSURL(string: urlString)
        
        let request = NSMutableURLRequest(URL: url!)
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.HTTPMethod = "GET"
        
        return request
    }
    
    // Reachability Functions
    
    private func isHostReachable()->Bool {
        return reachability?.currentReachabilityStatus != Reachability.NetworkStatus.NotReachable
    }
    
    internal func hostReachabilityChanged(note : NSNotification) {
        if isHostReachable() {
            flush()
        }
    }
    
    // :MARK- Encoding & Decoding functions
    
    /**
     encodeAPIParamData: Internal function that encodes API dictionary data to base64 and returns a string
     - Parameter dict: an NSDictionary representing the data to be encoded for a given event
     - Returns: an encoded string
     */
    private func encodeAPIParamData(dict: NSDictionary)->String {
        var b64String = ""
        let data : NSData? = JSONSerializeObject(dict)
        
        if data != nil {
            let characterSet = NSMutableCharacterSet.URLQueryAllowedCharacterSet()
            b64String = data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            b64String = b64String.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)!
        }
        
        return b64String
    }
    
    /**
     JSONSerializeObject: serializes an AnyObject into an NSData Object.
     
     - Parameter obj: the object to be serialized
     - Returns: NSData representation of the object
     */
    private func JSONSerializeObject(obj : AnyObject)-> NSData? {
        
        let coercedobj = JSONSerializableObjectForObject(obj)
        var error : NSError? = nil
        var data : NSData? = nil
        
        if NSJSONSerialization.isValidJSONObject(obj) {
            do {
                data = try NSJSONSerialization.dataWithJSONObject(coercedobj, options: .PrettyPrinted)
            }
            catch let errors as NSError{
                data = nil
                error = errors
                print("exception encoding the api data: \(errors)")
            }
            catch {
                print("unknown error")
            }
            if error == nil { return data }
            print("Error parsing the json: \(error)")
        }
        
        return data
    }
    
    /**
     JSONSerializableObjectForObject: Function checks & converts data into approved data types for JSON
     
     :param: obj type AnyObject
     :returns: an AnyObject that has been verified and cleaned
     */
    private func JSONSerializableObjectForObject(obj: AnyObject)-> AnyObject {
        
        if NSJSONSerialization.isValidJSONObject(obj) {
            return obj
        }
        
        // Apple Documentation: "All objects need to be instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull"
        if (obj.isKindOfClass(NSString) || obj.isKindOfClass(NSNumber) || obj.isKindOfClass(NSNull)) {
            return obj
        }
        
        // recurse through collections and serialize each object
        if obj.isKindOfClass(NSArray) {
            let a = NSMutableArray()
            let objects = obj as! NSArray
            for item in objects {
                a.addObject(JSONSerializableObjectForObject(item))
            }
            return a as NSArray
        }
        
        if obj.isKindOfClass(NSDictionary) {
            let dict = NSMutableDictionary()
            let objects = obj as! NSDictionary
            
            for key in objects.keyEnumerator() {
                var stringKey : NSString?
                if !(key.isKindOfClass(NSString)) {
                    stringKey = key.description
                    print("warning: property keys should be strings. got: \(stringKey)")
                } else {
                    stringKey = NSString(string: key as! NSString)
                }
                if stringKey != nil {
                    let v : AnyObject = JSONSerializableObjectForObject(objects[stringKey!]!)
                    dict[stringKey!] = v
                }
            }
            return dict
        }
        
        if(obj.isKindOfClass(NSDate)) {
            return obj.timeIntervalSince1970
        }
        
        let s = obj.description
        print("Warning, the property values should be valid json types")
        return s
    }
    
}
