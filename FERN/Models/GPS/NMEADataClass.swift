//
//  EADataEntClass.swift
//  NMEASwift
//
//  Translated from original Objective-C to Swift by Dan Hopp on 5/8/23. Source was
//  from a Toolkit provided by Eos Positioning Systems Inc. Notes prefixed with an [O] were from the source.
//

import Foundation
import CoreLocation
import nmeaToolKit
import ExternalAccessory
import SwiftUI // For .append


@Observable class NMEA : NSObject, CLLocationManagerDelegate, StreamDelegate {
    
    var locationManager = CLLocationManager()
    var comThread:Thread?
    var accessorySession:EASession?
//    var rxInPause:Bool?
    private var runLoop:RunLoop? // Original code has a dict with a RunLoop and Bool variable type. Bool variable type was commented out. Trying a class-wide var.
    
    let kComThreadRunloop:String! = "kComThreadRunloop"
    let kRequestLocation:String! = "kRequestLocation"
    
    // Original code has them as instance variables (which are private implementation details of Obj-C's class?), and to to make Objective-C compatible with C?
    // Will need to "defer {info.deallocate()}" and "defer {parser.deallocate()}" when finished? (Where to place?)
    private var parserInitialized = nmeaPARSER()
    private var infoInitialized = nmeaINFO()

    
    var latitude:String?
    var longitude:String?
    var altitude:String?
    var accuracy:String?
    var gpsUsed:String?
    var protocolText:NSString = "No Protocol"
    var stringGPGST:String?
    
    // Alerts
    var streamHasNoData = false
    var endEventEncountered = false
//    var errorEventEncountered = false
    
    // Sounds
    let audio = playSound()
    
    // 03-OCT-2024 - Try class-wide variable to handle Bluetooth disconnect and reconnects
    let sharedAccessoryManager = EAAccessoryManager.shared()
    
//    private var doRestartLoop = false
    
//    var consoleText:String?
    
    
    // MARK: - Main Function
    // Main(?) function from ViewController @implementation
    // 13-JUN-2024: viewDidLoad() was changed to startNMEA():
    func startNMEA() {

//        resetConsoleText()
        print("STARTING NMEA...")
        
        // [O] register for EA notif
//        let sharedAccessoryManager = EAAccessoryManager.shared()
        sharedAccessoryManager.registerForLocalNotifications()
        
        let defaultCenter = NotificationCenter()
        defaultCenter.addObserver(self, selector: #selector(didConnectNotif), name: NSNotification.Name("EAAccessoryDidConnect"), object: nil)
        defaultCenter.addObserver(self, selector: #selector(didDisconnectNotif), name: NSNotification.Name("EAAccessoryDidDisconnect"), object: nil)
        
        // [O] BT button - If you want users to be able to pair to the receivers from inside your apps. Otherwise users can use Settings>bluetooth to initiate the pairing.
        // [Original Objective-C code]
        
        // [O] RequestLocation - You can choose to initialize or not iniialize the core location services
        
        // Beginnings of translated code to tie actions to view buttons:
//        var requestLocationConf:NSNumber = UserDefaults.standard.object(forKey: kRequestLocation) as! NSNumber
        // [Rest of the Original Objective-C code]
        
        //        // [O] Rx
        //        self.receiveTextView.delegate = self;
        //        self.receiveTextView.text = @"";
        
        // Fire off Parser, CoreLocation registration, and create the ComThread. To init only once, the original code was wrapped in a dispatch_once.
        lazy var initOnce: Void = {
            initNMEAParser()
            registerCoreLocation()
            createComThread()
        }()
        
        _ = initOnce // call the lazy
        
        
        // [O] Did we start with an accessory already connected ?
        if (sharedAccessoryManager.connectedAccessories.count > 0) {

            print("There are already connected accessories")
            
            // [O] get first accessory
            let firstAccessory:EAAccessory = sharedAccessoryManager.connectedAccessories.first!
            print("firstAccessory Accessory : \(firstAccessory.description)")
            
            // [O] Since the app was started after the accessory was connected, Send a connection notification as the system does when the accessory is connected
//            var accessoryKey:[EAAccessoryKey: EAAccessory]
            let accessoryKey:NSDictionary = ["EAAccessoryKey" : firstAccessory]
            let notif:NSNotification = NSNotification(name: NSNotification.Name(rawValue: "fakeAccessoryNotif") , object: nil, userInfo: (accessoryKey as! [AnyHashable : Any])) // Original userInfo was "userInfo:@{EAAccessoryKey: firstAccessory}" This was an NSDictionary, correct?
            didConnectNotif(notification: notif)
        }
    }
    
    // Not used in original code?
    /* didReceiveMemoryWarning() is for UIViewController subclasses. For other types, use UIApplicationDidReceiveMemoryWarningNotification.
     This funciton is automatically used when the system determines that the memory is low. iPhone 4 and greater usually don't have memory
     space issues.*/
//    func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning
//        // [O] Dispose of any resources that can be recreated.
//    }

    func loopToRestart() {
    // NOTE: restart will run when screen is in sleep mode and will use 50% CPU. Per Apple: The standard lifecycle for an iOS app is that, when the user moves it to the background, the system suspends it. A suspend app lurks in the background indefinitely. That way, if the user brings it to the front, it can be quickly resumed rather than relaunched. However, if the system comes under memory pressure it will terminate the app, removing it from memory.
        audio.playArrowConnLost()
        
//        print("NMEA looping call is DISABLED.")
        
//        print("Restarting NMEA with looping calls to reStartNMEA()...")
//        while (doRestartLoop) {
//            if (sharedAccessoryManager.connectedAccessories.count > 0) {
//                reStartNMEA()
//            }
//        }
    }
    
    // Not used in original code?
    func dealloc(sharedAccessoryManager:EAAccessoryManager, defaultCenter:NSNotification) {
        
        // [O] Always unregister when dealloc ...
        sharedAccessoryManager.unregisterForLocalNotifications()
        defaultCenter.removeObserver(self, forKeyPath: "what goes here?")
    }
    
    // Try restart function without initOnce'ing the parser, registering CoreLocation, and creating the ComThread
    func reStartNMEA() {
        
       // [O] Did we start with an accessory already connected ?
       if (sharedAccessoryManager.connectedAccessories.count > 0) {
           
           // [O] get first accessory
           let firstAccessory:EAAccessory = sharedAccessoryManager.connectedAccessories.first!
           
           // [O] Since the app was started after the accessory was connected, Send a connection notification as the system does when the accessory is connected
//            var accessoryKey:[EAAccessoryKey: EAAccessory]
           let accessoryKey:NSDictionary = ["EAAccessoryKey" : firstAccessory]
           let notif:NSNotification = NSNotification(name: NSNotification.Name(rawValue: "fakeAccessoryNotif") , object: nil, userInfo: (accessoryKey as! [AnyHashable : Any])) // Original userInfo was "userInfo:@{EAAccessoryKey: firstAccessory}" This was an NSDictionary, correct?
           didConnectNotif(notification: notif)
       }
   }

    // MARK: - Core location
    func registerCoreLocation(){
        
        // Original code checks for toggled switches on the UI before proceeding
        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Included in most CLLocationManager web examples
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    func stopUpdatingArrowCoreLocation(){
        locationManager.stopUpdatingLocation()
    }
    // end Core location
    
    // MARK: - EA notifications
    @objc func didConnectNotif(notification: NSNotification){
        
        // [O] Accessory just get connected
        let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory
        let selectedBTAccessory = notification.userInfo?[EAAccessorySelectedKey] as? EAAccessory
        let noValueFoundMsg:NSString = "No value found"
        
        if ((accessory != nil) && (accessory?.isConnected != nil)) {
            print("accessory Accessory : \(String(describing: accessory?.description))")
            
            if (accessory?.protocolStrings.count == 0) {
                print("No protocol declared yet")
                return
            }
            
            if (self.accessorySession?.accessory?.connectionID == accessory?.connectionID) {
                print("re entrance")
                print(#function,"::","re entrance", to: &logger)
                endEventEncountered = false
//                doRestartLoop = false
                return
            }
            
            // Code to raise alert announcing a connected accessory
            // [Original Obj-C code]
            
            
            // [O] Create a session. Get the first matching accessory thats supported by both the app (in info.plist) and the accessory and use it.
            let supportedProtocols = Bundle.main.infoDictionary?["UISupportedExternalAccessoryProtocols"] as? NSArray
            let theProtocol = supportedProtocols?.firstObjectCommon(with: accessory?.protocolStrings ?? [noValueFoundMsg]) as? NSString
            
            if (theProtocol == nil){
                print("Error, incompatible protocol")
                // Code to raise alert announcing a connected accessory
                // [Original Obj-C code]
                return
            }
            
            print("Using protocol \(theProtocol ?? noValueFoundMsg)")
            self.protocolText = theProtocol ?? "No Protocol"
            
        
        
            // Start accessory sesion?
            accessorySession = EASession(accessory: accessory!, forProtocol: theProtocol! as String)


            if (accessorySession == nil) {
                print("Error, accessory can't communicate. accessorySession is nil")
                print(#function,"::","Error, accessory can't communicate. accessorySession is nil", to: &logger)
                audio.playError()
//                doRestartLoop = true
//                loopToRestart()
                
                // Alert accessory can't communicate
                // [Original Obj-C code]
            } else {
//                doRestartLoop = false
                endEventEncountered = false
//                audio.playArrowConnSuccess()
            }
            
            // [O] link stream to the com thread
            accessorySession?.inputStream?.delegate = self
//            let comThreadRunloop = RunLoop() /* Swift-translated line. Original code: "NSRunLoop *comThreadRunloop = [[self.comThread threadDictionary] objectForKey:kComThreadRunloop];"  It's grabbing the runloop based on the dict key value of "kComThreadRunloop". (Could grabbing the app's current active RunLoop work?) */
            accessorySession?.inputStream?.schedule(in: runLoop!, forMode: .default)
            
            // [O] start our stream, this will launch callbacks
            accessorySession?.inputStream?.open() // Should trigger the stream function
        }
        
        if (selectedBTAccessory != nil) {
            print("selectedBTAccessory accessory: \(selectedBTAccessory?.description ?? "No selectedBTAccessory found")")
        }
    }
    
    @objc func didDisconnectNotif(notification: NSNotification){
        print("didDisconnectNotif(notification: NSNotification) WAS CALLED")
        
        // [O] An accessory just get disconnected
        let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory
        print("Checking to stop stream for accessory : \(String(describing: accessory?.description))")
        
        if (self.accessorySession?.accessory?.connectionID == accessory?.connectionID) {
            print("'accessorySession' == 'accessory?.connectionID'")
            
            // [O] stop stream
            print(#function,"::","stop stream", to: &logger)
//                print("Skipping endStreaming()...")
            print("Calling endStreaming()...")
            endStreaming()
            
            print("setting 'accessorySession' to nil")
            self.accessorySession = nil
            
            self.protocolText = "No Protocol"
        }
        else {
            print("'accessorySession' != 'accessory?.connectionID', endStreaming() is NOT called and 'accessorySession' is NOT set to nil.")
        }
    }
    // end EA notifications
    
    // MARK: - Buttons
    // Assign show the system bluetooth accessory discovery view, user can disable CoreLocation, and pause the receive screen actions to buttons.
        // [Original Obj-C code]
    // end Buttons
    
    // MARK: - RX Text
    // ascii-translate the accessory's streaming data for display in a text field
        // [Original Obj-C code]
    // end RX Text
    
    // MARK: - Com Thread
    func createComThread(){
        // [O] create a com thread dedicated to accessory I/O
        let aThread = Thread(target: self, selector: #selector(initComThread), object: nil)
        self.comThread = aThread
        self.comThread?.name = "Com thread"
        self.comThread?.threadPriority = 0.8
        self.comThread?.start()
        print("Com thread started")
    }
    
    @objc func initComThread(){
        print("New com thread starting")
        /* When we write swift code that is entirely swift, then there is no need for for autoreleasepool. We should however keep autoreleasepool in mind when we use Objective-C objects.
         */
        print("Getting into runloop")
        // [O] create infinte runloop for thread
//        let exitNow:Bool = false  // commented out for class-wide runLoop attempt
        self.runLoop = RunLoop.current
//        let runLoop = RunLoop.current  // Original line
        
        // [O] add exitNow bool in thread dictionnary
        // Swift-translated code was commented out for class-wide runLoop attempt:
//        let threadDict:NSMutableDictionary = Thread.current.threadDictionary
//        threadDict.setValue(exitNow, forKey: "ThreadShouldExitNow") // If the original code commented out this key's call, is this dict necesssary?
//        threadDict.setObject(runLoop, forKey: kComThreadRunloop! as NSCopying)
        
        // [O] create a timer which will fire in centuries to keep the runloop until input stream is added
        let myTimer = Timer(fireAt: .distantFuture, interval: 0, target: self, selector: #selector(timerCall), userInfo: nil, repeats: false)
        runLoop!.add(myTimer, forMode: .common)
        
        runLoop!.run()
        
        // [O] should never come here ... or at app end
        print("Exiting com thread (should never come here ... or at app end)");
    }
    
    @objc func timerCall(){
        // [O] should never be called !!
        print("A \"should not be called\"(?) timerCall function was called");
    }
    
    // What calls this function? If declared verbatum like in the apple documentation (minus the 'optional') the func will be auto-called. Per docs: "It is a delegate that recieves this message when a given event has occured in a given stream."
    func stream(_ aStream: Stream, handle eventCode:Stream.Event){
        // Original method signature was: "- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {" It is a delegate that recieves the handleEvent message when a given event has occured in a given stream. Swift's handleEvent equiv is stream(_:handle:)
        
        // [O] Main io stream event manager
//        print("\(Thread.current.name ?? "No thread name") enter with \(aStream == self.accessorySession?.inputStream ? "input" : "output") stream and event \(eventCode)") UNCOMMENT FOR STREAM INFO
        if ((self.accessorySession?.inputStream) != nil){
            // [O] input stream
            var buf = [UInt8](repeating: 0, count: 1024)// original Obj-c line: uint8_t buf[1024];
            var dataLength:Int? // original type was NSUInteger
            
//            print(eventCode, to: &logger)
            
            switch (eventCode) {
            case Stream.Event.openCompleted:
                print("openCompleted (NSStreamEventOpenCompleted)")
                break;
            case Stream.Event.hasBytesAvailable:
                // [O] got bytes to read
                dataLength = self.accessorySession?.inputStream?.read(&buf, maxLength: 1024) ?? 0 // When Address Sanitizer is enabled: Stack buffer overflow on self.accessorySession?.inputStream?.read
                if (dataLength != nil){
//                    print("Read \(dataLength ?? 0) bytes") UNCOMMENT FOR STREAM INFO
                    let theData:NSData = NSData(bytes: &buf, length: dataLength ?? 0)
                    // [O] show on screen
                    // [Original Objective-C code]
                    
                    // [O] NMEA parsing - If you want to parse data using the included NMEA parser lib.
                    let res:Int32 = parseNMEA(data: theData)
                    if (res > 0) {
                        // [O] found some NMEA sentences !
//                        self.performSelector(onMainThread: #selector(updateNMEAUI), with: nil, waitUntilDone: false)  // Original Obj-c code
                        // 1st attempt at swift-translated code: "self.performSelector(onMainThread: NSSelectorFromString("updateNMEAUI"), with: nil, waitUntilDone: false)". May need to switch call to #selector?
                        // Try a basic function call instead:
                        updateNMEAUI()
                    } else {
                        print("res has no NMEA sentences")
                        setStreamHasNoDataToTrue()
                    }
                }
                else {
                    print("dataLength is nil. Nothing to read...")
                    setStreamHasNoDataToTrue()
                }
                break;
            case Stream.Event.errorOccurred:
                print("ERROR event encountered")
                let theError:NSError = aStream.streamError! as NSError
                print ("Error is \(theError.localizedDescription)")
//                errorEventEncountered = true
//                doRestartLoop = false
                
//                print("Skipping setStreamHasNoDataToTrue()...")
                print("Calling setStreamHasNoDataToTrue()...")
                setStreamHasNoDataToTrue()

                // [O] kill the streaming
//                print("Skipping endStreaming()...")
                print("Calling endStreaming()...")
                endStreaming()
                break;
            case Stream.Event.endEncountered:
                print("END EVENT encountered")
                print(#function,"::","END EVENT encountered", to: &logger)
                endEventEncountered = true
//                doRestartLoop = true
                
//                print("Skipping setStreamHasNoDataToTrue()...")
                print("Calling setStreamHasNoDataToTrue()...")
                setStreamHasNoDataToTrue()
                
                print("Skipping endStreaming()...")
//                print("Calling endStreaming()...")
//                endStreaming()
                
//                print("Calling loopToRestart()...")
//                loopToRestart()
                break;
            default:
                print("No code for event '\(eventCode)'")
                break;
            }
        }
    }
    
    func endStreaming() {
        print("end streaming...")
        
//        audio.TBDAlert()
        
        // [O] kill stream
        accessorySession?.inputStream?.close()
        accessorySession?.inputStream?.remove(from: .current, forMode: .default)

        // [O] exit thread (Code was commented out in the original)
        //NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
        //[threadDict setValue:[NSNumber numberWithBool:TRUE] forKey:@"ThreadShouldExitNow"];
    }
    
    // MARK: - NMEA
    @objc func initNMEAParser(){
        /* UnsafeMutablePointer answer: Instantiate the classes */
        nmea_zero_INFO(&infoInitialized) // [O] reset info for results
        
        if (parserInitialized.buffer != nil) {
            nmea_parser_destroy(&parserInitialized) // [O] destroy previously created parser
        }
        nmea_parser_init(&parserInitialized) // [O] init parser
    }
    
    func parseNMEA(data: NSData) -> Int32{

        print("Enter with \(data.length) bytes")
        
        // [O] let's get a C buffer from data
        let buff:String = String(decoding: data, as: UTF8.self)
        // Original line was char *buff = (char *)[data bytes]; (converting the bytes into an array of characters (string))
        
        let res:Int32 = nmea_parse(&parserInitialized, buff, Int32(data.length), &infoInitialized) // [O]  updates info
        
        // [O] small resumé
        print("Analysed \(res) sentences");
        print("Mask is 0x\(infoInitialized.smask)");
        print("sig is \(infoInitialized.sig), fix is \(infoInitialized.fix)");
        print("GPS satellites in view \(infoInitialized.GPSsatinfo.inview), in use \(infoInitialized.GPSsatinfo.inuse)");
        print("GLONASS satellites in view \(infoInitialized.GLONASSsatinfo.inview), in use \(infoInitialized.GLONASSsatinfo.inuse)");
        
        return res
    }
    
    // MARK: - Variable Assignments
    
    @objc func updateNMEAUI(){
        // [Original code to update the view's fields with alt, lat, long, accuracy, etc]
        // May need to create properties in this class and assign values to them. @State (or @ObjectiveState) should allow view to auto-update.
        
        let latdeg:Double = nmea_ndeg2degree(infoInitialized.lat)
        let londeg:Double = nmea_ndeg2degree(infoInitialized.lon)
        
        // Wrapped in DispatchQueue for purple warning "Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates."
        DispatchQueue.main.async { [self] in
            self.latitude = String(format: "%0.8f", latdeg)
            self.longitude = String(format: "%0.8f", londeg)
            self.altitude = String(format: "%0.2f", infoInitialized.elv)
            // Origial Obj-C code for accuracy:
            //        if (infoInitialized.smask & GPGST) {  // C-supported bitwise operator. (may need to prefix GPGST?) "Cannot convert value of type '_nmeaPACKTYPE' to expected argument type 'Int32'"
            //            self.accuracy = String(format: "%0.2f M", infoInitialized.dev_xy)
            //        }
            self.accuracy = String(format: "%0.2f", infoInitialized.dev_xy)
            self.gpsUsed = String(format: "%2i", infoInitialized.GPSsatinfo.inuse)
            self.streamHasNoData = false
        }
    }
    
    func setStreamHasNoDataToTrue(){
        
        print("Setting NMEA var 'streamHasNoData' to TRUE. Zeroing-out NMEA coordinate vars.")
        
        DispatchQueue.main.async { [self] in
            self.streamHasNoData = true
            // set vars to 0
            self.latitude = "0.00000000"
            self.longitude = "0.00000000"
            self.altitude = "0.00"
            self.accuracy = "0.00"
            self.gpsUsed = "No GPS"
        }
    }
}
