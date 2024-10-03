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


@Observable class NMEA : NSObject, CLLocationManagerDelegate, StreamDelegate {
    
    var locationManager = CLLocationManager()
    var comThread:Thread?
    var accessorySession:EASession?
    var rxInPause:Bool?
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
    
    // To alert the view if the stream has stopped
    var hasNMEAStreamStopped = false
    
    // Sounds
    let audio = playSound()
    
    let sharedAccessoryManager = EAAccessoryManager.shared()
    
    private var callRestartFunc = false
    private var tempCounter = 0
    
    // MARK: - Main Function
    // Main(?) function from ViewController @implementation
    // 13-JUN-2024: viewDidLoad() was changed to startNMEA():
    func startNMEA() {
        
        print("Lifecycle Print: startNMEA() called")

        // [O] register for EA notif
        print("Lifecycle Print: // registering for EA notification")
        print("Lifecycle Print: let sharedAccessoryManager = EAAccessoryManager.shared()")
//        let sharedAccessoryManager = EAAccessoryManager.shared()
        print("Lifecycle Print: sharedAccessoryManager.registerForLocalNotifications()")
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
        print("Lifecycle Print: creating initOnce")
        lazy var initOnce: Void = {
            hasNMEAStreamStopped = false // was added to try a NMEA feed restart by calling startNMEA() again
            initNMEAParser()
            registerCoreLocation()
            createComThread()
        }()
        
        print("Lifecycle Print: calling initOnce")
        _ = initOnce // call the lazy
        
        
        // [O] Did we start with an accessory already connected ?
        print("Lifecycle Print: // Did we start with an accessory already connected?")
        if (sharedAccessoryManager.connectedAccessories.count > 0) {
            print("Lifecycle Print: sharedAccessoryManager.connectedAccessories.count is > 0")
            print("There are already connected accessories")
            
            // [O] get first accessory
            print("Lifecycle Print: // getting first accessory")
            let firstAccessory:EAAccessory = sharedAccessoryManager.connectedAccessories.first!
            print("firstAccessory Accessory : \(firstAccessory.description)")
            
            // [O] Since the app was started after the accessory was connected, Send a connection notification as the system does when the accessory is connected
            print("Lifecycle Print: // Since the app was started after the accessory was connected, send a connection notification as the system does when the accessory is connected")
//            var accessoryKey:[EAAccessoryKey: EAAccessory]
            print("Lifecycle Print: let accessoryKey:NSDictionary = ['EAAccessoryKey' : firstAccessory]")
            let accessoryKey:NSDictionary = ["EAAccessoryKey" : firstAccessory]
            print("Lifecycle Print: let notif:NSNotification = NSNotification(name: NSNotification.Name(rawValue: 'fakeAccessoryNotif') , object: nil, userInfo: (accessoryKey as! [AnyHashable : Any]))")
            let notif:NSNotification = NSNotification(name: NSNotification.Name(rawValue: "fakeAccessoryNotif") , object: nil, userInfo: (accessoryKey as! [AnyHashable : Any])) // Original userInfo was "userInfo:@{EAAccessoryKey: firstAccessory}" This was an NSDictionary, correct?
            print("Lifecycle Print: calling didConnectNotif")
            didConnectNotif(notification: notif)
        } else {print("Lifecycle Print: sharedAccessoryManager.connectedAccessories.count is 0")}
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
        while (callRestartFunc) {
            if (sharedAccessoryManager.connectedAccessories.count > 0) {
                print("Restarting...")
                restartNMEA()
            }
        }
    }
    
    // Not used in original code?
    func dealloc(sharedAccessoryManager:EAAccessoryManager, defaultCenter:NSNotification) {
        print("Lifecycle Print: dealloc function called")
        // [O] Always unregister when dealloc ...
        print("Lifecycle Print: // Always unregister when dealloc'ing...")
        print("Lifecycle Print: sharedAccessoryManager.unregisterForLocalNotifications()")
        sharedAccessoryManager.unregisterForLocalNotifications()
        print("Lifecycle Print: defaultCenter.removeObserver(self, forKeyPath: 'what goes here?')")
        defaultCenter.removeObserver(self, forKeyPath: "what goes here?")
    }
    
    // Try function to didConnectNotif without initOnce'ing the parser, registering CoreLocation, and creating the ComThread
    func restartNMEA() {
        print("Lifecycle Print: restartNMEA function called")
        
       // [O] register for EA notif
//        print("Lifecycle Print: // registering for EA notification")
//        print("Lifecycle Print: let sharedAccessoryManager = EAAccessoryManager.shared()")
//       let sharedAccessoryManager = EAAccessoryManager.shared()
//        print("Lifecycle Print: sharedAccessoryManager.registerForLocalNotifications()")
//       sharedAccessoryManager.registerForLocalNotifications()
       
       // [O] Did we start with an accessory already connected ?
        print("Lifecycle Print: // Did we start with an accessory already connected?")
       if (sharedAccessoryManager.connectedAccessories.count > 0) {
           print("Lifecycle Print: sharedAccessoryManager.connectedAccessories.count is > 0")
           print("There are already connected accessories")
           
           // [O] get first accessory
           print("Lifecycle Print: // getting first accessory")
           let firstAccessory:EAAccessory = sharedAccessoryManager.connectedAccessories.first!
           print("firstAccessory Accessory : \(firstAccessory.description)")
           
           // [O] Since the app was started after the accessory was connected, Send a connection notification as the system does when the accessory is connected
           print("Lifecycle Print: // Since the app was started after the accessory was connected, send a connection notification as the system does when the accessory is connected")
//            var accessoryKey:[EAAccessoryKey: EAAccessory]
           print("Lifecycle Print: assigning firstAccessory to accessoryKey:NSDictionary")
           let accessoryKey:NSDictionary = ["EAAccessoryKey" : firstAccessory]
           print("Lifecycle Print: assigning NSNotification to notif:NSNotification")
           let notif:NSNotification = NSNotification(name: NSNotification.Name(rawValue: "fakeAccessoryNotif") , object: nil, userInfo: (accessoryKey as! [AnyHashable : Any])) // Original userInfo was "userInfo:@{EAAccessoryKey: firstAccessory}" This was an NSDictionary, correct?
           print("Lifecycle Print: calling didConnectNotif")
           didConnectNotif(notification: notif)
       } else {print("Lifecycle Print: sharedAccessoryManager.connectedAccessories.count is 0")}
   }

    // MARK: - Core location
    func registerCoreLocation(){
        print("Lifecycle Print: NMEA's registerCoreLocation is called")
        
        // Original code checks for toggled switches on the UI before proceeding
        print("Lifecycle Print: set locationManager.delegate to self")
        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Included in most CLLocationManager web examples
        print("Lifecycle Print: locationManager.requestWhenInUseAuthorization()")
        locationManager.requestWhenInUseAuthorization()
        print("Lifecycle Print: locationManager.startUpdatingLocation()")
        locationManager.startUpdatingLocation()
    }
    
    
    func stopUpdatingArrowCoreLocation(){
        print("Lifecycle Print: NMEA's stopUpdatingArrowCoreLocation is called")
        print("Lifecycle Print: locationManager.stopUpdatingLocation()")
        locationManager.stopUpdatingLocation()
    }
    // end Core location
    
    // MARK: - EA notifications
    @objc func didConnectNotif(notification: NSNotification){
        print("Lifecycle Print: didConnectNotif is called")
        
        // [O] Accessory just get connected
        print("Lifecycle Print: // Accessory just get connected")
        print("Lifecycle Print: let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory")
        let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory
        print("Lifecycle Print: let selectedBTAccessory = notification.userInfo?[EAAccessorySelectedKey] as? EAAccessory")
        let selectedBTAccessory = notification.userInfo?[EAAccessorySelectedKey] as? EAAccessory
        let noValueFoundMsg:NSString = "No value found"
        
        print("Lifecycle Print: if ((accessory != nil) && (accessory?.isConnected != nil)) {")
        if ((accessory != nil) && (accessory?.isConnected != nil)) {
            print("accessory Accessory : \(String(describing: accessory?.description))")
            
            print("Lifecycle Print: if (accessory?.protocolStrings.count == 0) {")
            if (accessory?.protocolStrings.count == 0) {
                print("No protocol declared yet")
                print("Lifecycle Print: }")
                return
            } else {print("Lifecycle Print: accessory?.protocolStrings.count is not 0")}
            print("Lifecycle Print: }")
            
            print("Lifecycle Print: if (self.accessorySession?.accessory?.connectionID == accessory?.connectionID) {")
            if (self.accessorySession?.accessory?.connectionID == accessory?.connectionID) {
                print("re entrance")
                print("Lifecycle Print: }")
                return
            }
            print("Lifecycle Print: }")
            
            // Code to raise alert announcing a connected accessory
            // [Original Obj-C code]
            
            print("Lifecycle Print: // Create a session. Get the first matching accessory thats supported by both the app (in info.plist) and the accessory and use it.")
            // [O] Create a session. Get the first matching accessory thats supported by both the app (in info.plist) and the accessory and use it.
            print("Lifecycle Print: set supportedProtocols to Bundle.main.infoDictionary?['UISupportedExternalAccessoryProtocols'] as? NSArray")
            let supportedProtocols = Bundle.main.infoDictionary?["UISupportedExternalAccessoryProtocols"] as? NSArray
            print("Lifecycle Print: set theProtocol to supportedProtocols?.firstObjectCommon(with: accessory?.protocolStrings ?? [noValueFoundMsg]) as? NSString")
            let theProtocol = supportedProtocols?.firstObjectCommon(with: accessory?.protocolStrings ?? [noValueFoundMsg]) as? NSString
            
            print("Lifecycle Print: if (theProtocol == nil){")
            if (theProtocol == nil){
                print("Error, incompatible protocol")
                // Code to raise alert announcing a connected accessory
                // [Original Obj-C code]
                return
            } else {print("Lifecycle Print: theProtocol is not nil")}
            print("Lifecycle Print: }")
            
            print("Using protocol \(theProtocol ?? noValueFoundMsg)")
            self.protocolText = theProtocol ?? "No Protocol"
            
            print("BEFORE accessorySession = EASession(accessory: (accessory)!, forProtocol: theProtocol! as String):")
            print(accessory)
            print(theProtocol! as String)
            
            // Start accessory sesion?
            accessorySession = EASession(accessory: (accessory)!, forProtocol: theProtocol! as String)
            
            print("AFTER accessorySession = EASession(accessory: (accessory)!, forProtocol: theProtocol! as String):")
            print(accessory)
            print(theProtocol! as String)
            print(accessorySession)
            
            
            print("Lifecycle Print: if (accessorySession == nil) {")
            if (accessorySession == nil) {
                audio.playAccessorySessionIsNil()
                print("Error, accessory can't communicate")
                callRestartFunc = true
                loopToRestart()
                // Alert accessory can't communicate
                // [Original Obj-C code]
            } else {print(
                "Lifecycle Print: accessorySession is not nil")
                callRestartFunc = false
                audio.playArrowConnRegained()
            }
            print("Lifecycle Print: }")
            
            // [O] link stream to the com thread
            print("Lifecycle Print: // link stream to the com thread")
            print("Lifecycle Print: accessorySession?.inputStream?.delegate = self")
            accessorySession?.inputStream?.delegate = self
//            let comThreadRunloop = RunLoop() /* Swift-translated line. Original code: "NSRunLoop *comThreadRunloop = [[self.comThread threadDictionary] objectForKey:kComThreadRunloop];"  It's grabbing the runloop based on the dict key value of "kComThreadRunloop". (Could grabbing the app's current active RunLoop work?) */
            print("Lifecycle Print: accessorySession?.inputStream?.schedule(in: runLoop!, forMode: .default)")
            accessorySession?.inputStream?.schedule(in: runLoop!, forMode: .default)
            
            // [O] start our stream, this will launch callbacks
            print("Lifecycle Print: // start our stream, this will launch callbacks")
            print("Lifecycle Print: accessorySession?.inputStream?.open()")
            accessorySession?.inputStream?.open() // Should trigger the stream function
        }
        print("Lifecycle Print: }")
        
        print("Lifecycle Print: if (selectedBTAccessory != nil) {")
        if (selectedBTAccessory != nil) {
            print("selectedBTAccessory accessory: \(selectedBTAccessory?.description ?? "No selectedBTAccessory found")")
        } else {print("Lifecycle Print: selectedBTAccessory is nil")}
        print("Lifecycle Print: }")
    }
    
    @objc func didDisconnectNotif(notification: NSNotification){
        print("Lifecycle Print: didDisconnectNotif is called")
        
        // [O] An accessory just get disconnected
        print("Lifecycle Print: // An accessory just got disconnected")
        print("Lifecycle Print: let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory")
        let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory
        print("Checking to stop stream for accessory : \(String(describing: accessory?.description))")
        
        print("if (self.accessorySession?.accessory?.connectionID == accessory?.connectionID) {")
        if (self.accessorySession?.accessory?.connectionID == accessory?.connectionID) {
            // [O] stop stream
            print("Lifecycle Print: // stop stream")
            print("Lifecycle Print: calling endStreaming()")
            endStreaming()
            print("Lifecycle Print: self.accessorySession = nil")
            self.accessorySession = nil
            
            self.protocolText = "No Protocol"
        }
        print("Lifecycle Print: }")
        
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
        print("Lifecycle Print: createComThread is called")
        // [O] create a com thread dedicated to accessory I/O
        print("// Creating a com thread dedicated to accessory I/O")
        print("""
                let aThread = Thread(target: self, selector: #selector(initComThread), object: nil)
                self.comThread = aThread
                self.comThread?.name = "Com thread"
                self.comThread?.threadPriority = 0.8
                self.comThread?.start()
        """)
        let aThread = Thread(target: self, selector: #selector(initComThread), object: nil)
        self.comThread = aThread
        self.comThread?.name = "Com thread"
        self.comThread?.threadPriority = 0.8
        self.comThread?.start()
        print("Com thread started")
        
    }
    
    @objc func initComThread(){
        print("Lifecycle Print: initComThread is called")
        print("New com thread starting")
        /* When we write swift code that is entirely swift, then there is no need for for autoreleasepool. We should however keep autoreleasepool in mind when we use Objective-C objects.
         */
        print("Getting into runloop")
        // [O] create infinte runloop for thread
//        let exitNow:Bool = false  // commented out for class-wide runLoop attempt
        print("Lifecycle Print: // create infinte runloop for thread")
        print("Lifecycle Print: self.runLoop = RunLoop.current")
        self.runLoop = RunLoop.current
//        let runLoop = RunLoop.current  // Original line
        
        // [O] add exitNow bool in thread dictionnary
        // Swift-translated code was commented out for class-wide runLoop attempt:
//        let threadDict:NSMutableDictionary = Thread.current.threadDictionary
//        threadDict.setValue(exitNow, forKey: "ThreadShouldExitNow") // If the original code commented out this key's call, is this dict necesssary?
//        threadDict.setObject(runLoop, forKey: kComThreadRunloop! as NSCopying)
        
        print("""
        // [O] create a timer which will fire in centuries to keep the runloop until input stream is added
        let myTimer = Timer(fireAt: .distantFuture, interval: 0, target: self, selector: #selector(timerCall), userInfo: nil, repeats: false)
        runLoop!.add(myTimer, forMode: .common)
        runLoop!.run()
""")
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
        
//        if callRestartFunc {
//            tempCounter += 1
//            print(tempCounter)
//            restartNMEA()
//        }
        
        print("stream function has been auto-called. Per Apple docs, when declared verbatum it 'is a delegate that recieves a message when a given event has occured in a given stream.'")
        // Original method signature was: "- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {" It is a delegate that recieves the handleEvent message when a given event has occured in a given stream. Swift's handleEvent equiv is stream(_:handle:)
        
        print("Lifecycle Print: // Main io stream event manager")
        // [O] Main io stream event manager
//        print("\(Thread.current.name ?? "No thread name") enter with \(aStream == self.accessorySession?.inputStream ? "input" : "output") stream and event \(eventCode)") UNCOMMENT FOR STREAM INFO
        print("Lifecycle Print: if ((self.accessorySession?.inputStream) != nil){")
        if ((self.accessorySession?.inputStream) != nil){
            print("""
            // [O] input stream
            var buf = [UInt8](repeating: 0, count: 1024)// original Obj-c line: uint8_t buf[1024];
            var dataLength:Int? // original type was NSUInteger
""")
            // [O] input stream
            var buf = [UInt8](repeating: 0, count: 1024)// original Obj-c line: uint8_t buf[1024];
            var dataLength:Int? // original type was NSUInteger
            
            print("Lifecycle Print: switch (eventCode) {")
            switch (eventCode) {
            case Stream.Event.openCompleted:
                print("Lifecycle Print: case Stream.Event.openCompleted:")
                print("openCompleted (NSStreamEventOpenCompleted)")
                break;
            case Stream.Event.hasBytesAvailable:
                print("Lifecycle Print: case Stream.Event.hasBytesAvailable:")
                print("Lifecycle Print: // got bytes to read")
                // [O] got bytes to read
                print("Lifecycle Print: dataLength = self.accessorySession?.inputStream?.read(&buf, maxLength: 1024) ?? 0")
                dataLength = self.accessorySession?.inputStream?.read(&buf, maxLength: 1024) ?? 0 // When Address Sanitizer is enabled: Stack buffer overflow on self.accessorySession?.inputStream?.read
                print("Lifecycle Print: if (dataLength != nil){")
                if (dataLength != nil){
                    print("Lifecycle Print: let theData:NSData = NSData(bytes: &buf, length: dataLength ?? 0)")
//                    print("Read \(dataLength ?? 0) bytes") UNCOMMENT FOR STREAM INFO
                    let theData:NSData = NSData(bytes: &buf, length: dataLength ?? 0)
                    // [O] show on screen
                    // [Original Objective-C code]
                    
                    // [O] NMEA parsing - If you want to parse data using the included NMEA parser lib.
                    print("Lifecycle Print: // NMEA parsing - If you want to parse data using the included NMEA parser lib.")
                    print("Lifecycle Print: let res:Int32 = parseNMEA(data: theData)")
                    let res:Int32 = parseNMEA(data: theData)
                    print("Lifecycle Print: if (res > 0) {")
                    if (res > 0) {
                        // [O] found some NMEA sentences !
//                        self.performSelector(onMainThread: #selector(updateNMEAUI), with: nil, waitUntilDone: false)  // Original Obj-c code
                        // 1st attempt at swift-translated code: "self.performSelector(onMainThread: NSSelectorFromString("updateNMEAUI"), with: nil, waitUntilDone: false)". May need to switch call to #selector?
                        
                        // Try a basic function call instead:
                        print("Lifecycle Print: calling updateNMEAUI()")
                        updateNMEAUI()
                    } else {
                        print("Lifecycle Print: res = 0")
                        print("Lifecycle Print: calling setHasNMEAStreamStoppedToTrue()")
                        setHasNMEAStreamStoppedToTrue()
                    }
                    print("Lifecycle Print: }")
                }
                else {
                    print("Nothing to read...")
                    setHasNMEAStreamStoppedToTrue()
                }
                print("Lifecycle Print: }")
                break;
            case Stream.Event.errorOccurred:
                print("Lifecycle Print: case Stream.Event.errorOccurred:")
                print("errorOccurred (NSStreamEventErrorOccurred)")
                let theError:NSError = aStream.streamError! as NSError
                print ("Error is \(theError.localizedDescription)")
                // [O] kill the streaming
                print("Lifecycle Print: calling endStreaming()")
                endStreaming()
                break;
            case Stream.Event.endEncountered:
                print("Lifecycle Print: case Stream.Event.endEncountered:")
                print("endEncountered (NSStreamEventEndEncountered)")
//                print("Lifecycle Print: calling endStreaming()")
                callRestartFunc = true
                loopToRestart()
//                endStreaming()
                break;
            default:
                print("Unused event \(eventCode)")
                break;
            }
        }
        print("}")
    }
    
    func endStreaming(){
        
        audio.playArrowEndStreamingCalled()
        
        print("Lifecycle Print: endStreaming is called")
        
        print("Lifecycle Print: calling setHasNMEAStreamStoppedToTrue()")
        setHasNMEAStreamStoppedToTrue()
        
        print("""
        // [O] kill stream
        accessorySession?.inputStream?.close()
        accessorySession?.inputStream?.remove(from: .current, forMode: .default)
""")
        // [O] kill stream
        accessorySession?.inputStream?.close()
        accessorySession?.inputStream?.remove(from: .current, forMode: .default)
        
        // Can accessorySession be reset/cleared?
//        self.accessorySession = nil
//        accessorySession = EASession()

        // [O] exit thread (Code was commented out in the original)
        //NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
        //[threadDict setValue:[NSNumber numberWithBool:TRUE] forKey:@"ThreadShouldExitNow"];
        
        // kill com thread?
//        self.comThread?.cancel()
        // kill run loop? (How to stop it?)
//        self.runLoop = nil
//        runLoop!.remove(<#T##aPort: Port##Port#>, forMode: .common)
        
    }
    // end Com thread
    
    // MARK: - NMEA
    @objc func initNMEAParser(){
        print("Lifecycle Print: initNMEAParser is called")
        /* UnsafeMutablePointer answer: Instantiate the classes */
        
        print("Lifecycle Print: // reset info for results")
        print("Lifecycle Print: nmea_zero_INFO(&infoInitialized)")
        nmea_zero_INFO(&infoInitialized) // [O] reset info for results
        
        print("Lifecycle Print: if (parserInitialized.buffer != nil) {")
        if (parserInitialized.buffer != nil) {
            print("// destroy previously created parser")
            print("Lifecycle Print: nmea_parser_destroy(&parserInitialized)")
            nmea_parser_destroy(&parserInitialized) // [O] destroy previously created parser
        } else {print("Lifecycle Print: parserInitialized.buffer is nil")}
        print("Lifecycle Print: }")
        print("Lifecycle Print: // init parser")
        print("Lifecycle Print: nmea_parser_init(&parserInitialized)")
        nmea_parser_init(&parserInitialized) // [O] init parser
    }
    
    func parseNMEA(data: NSData) -> Int32{
        print("Lifecycle Print: parseNMEA is called")
//        print("Enter with \(data.length) bytes") UNCOMMENT FOR STREAM INFO
        
        // [O] let's get a C buffer from data
        let buff:String = String(decoding: data, as: UTF8.self)
        // Original line was char *buff = (char *)[data bytes]; (converting the bytes into an array of characters (string))
        
        let res:Int32 = nmea_parse(&parserInitialized, buff, Int32(data.length), &infoInitialized) // [O]  updates info
        
        // [O] small resumé
//        print("Analysed \(res) sentences");
//        print("Mask is 0x\(infoInitialized.smask)");
//        print("sig is \(infoInitialized.sig), fix is \(infoInitialized.fix)");
//        print("GPS satellites in view \(infoInitialized.GPSsatinfo.inview), in use \(infoInitialized.GPSsatinfo.inuse)");
//        print("GLONASS satellites in view \(infoInitialized.GLONASSsatinfo.inview), in use \(infoInitialized.GLONASSsatinfo.inuse)");  UNCOMMENT FOR STREAM INFO
        
        return res
    }
    
    @objc func updateNMEAUI(){
        print("Lifecycle Print: updateNMEAUI is called")
        // [Original code to update the view's fields with alt, lat, long, accuracy, etc]
        // May need to create properties in this class and assign values to them. @State (or @ObjectiveState) should allow view to auto-update.

        print("""
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
            self.hasNMEAStreamStopped = false
        }
""")
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
            self.hasNMEAStreamStopped = false
        }
    }
    // end NMEA
    
    func setHasNMEAStreamStoppedToTrue(){
        
        audio.playSetHasNMEAStreamStoppedToTrue()
        
        print("Lifecycle Print: setHasNMEAStreamStoppedToTrue is called")
        print("""
        DispatchQueue.main.async { [self] in
            self.hasNMEAStreamStopped = true
            // set vars to 0
            self.latitude = "0.00000000"
            self.longitude = "0.00000000"
            self.altitude = "0.00"
            self.accuracy = "0.00"
            self.gpsUsed = "No GPS"
        }
""")
        DispatchQueue.main.async { [self] in
            self.hasNMEAStreamStopped = true
            // set vars to 0
            self.latitude = "0.00000000"
            self.longitude = "0.00000000"
            self.altitude = "0.00"
            self.accuracy = "0.00"
            self.gpsUsed = "No GPS"
        }
    }
}
