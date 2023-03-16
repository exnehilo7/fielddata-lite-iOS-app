//
//  ViewController.m
//  FERN
//
//  Added by Hopp, Dan on 3/9/23.
//  From EosEADataEnt development kit.

#import "ViewController.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import <CoreLocation/CoreLocation.h>
#import "DLog.h"
#import "NSData+hexa.h"
#import "nmeaApi.h"
#import "FERN-Bridging-Header.h"
//#import "FERN-EoS-Bridge.swift"

static NSString * const kComThreadRunloop = @"kComThreadRunloop";
static NSString * const kRequestLocation = @"kRequestLocation";


@interface ViewController () <UITextViewDelegate, NSStreamDelegate> {
    nmeaINFO info;
    nmeaPARSER parser;
}

// Connect to SwiftUI bridge
//UIViewController *gpsFeedViewController = [[GPSFeedViewFactory new] bridgeGPSFeedUI:@"Sarita"];
//[self ViewController:gpsFeedViewController animated:YES];

@property (nonatomic, assign) BOOL rxInPause;
@property (nonatomic, strong) EASession *accessorySession;
@property (nonatomic, strong) NSThread *comThread;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // register for EA notif
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didConnectNotif:) name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDisconnectNotif:) name:EAAccessoryDidDisconnectNotification object:nil];
    
    // BT button - If you want users to be able to pair to the receivers from inside your apps. Otherwise users can use Settings>bluetooth to initiate the pairing.
    [self.BTAccessoriesButton addTarget:self action:@selector(showBTSelector) forControlEvents:UIControlEventTouchUpInside];
    
    // RequestLocation - You can choose to initialize or not iniialize the core location services
    NSNumber *requestLocationConf = [[NSUserDefaults standardUserDefaults] objectForKey:kRequestLocation];
    if (!requestLocationConf) {
        // first init, on by default
        requestLocationConf = [NSNumber numberWithBool:YES];
        [[NSUserDefaults standardUserDefaults] setObject:requestLocationConf forKey:kRequestLocation];
    }
    self.requestLocationSwitch.on = [requestLocationConf boolValue];
    [self.requestLocationSwitch addTarget:self action:@selector(requestLocationChanged) forControlEvents:UIControlEventValueChanged];
    // Pause
    [self.pause addTarget:self action:@selector(pauseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // Rx
    self.receiveTextView.delegate = self;
    self.receiveTextView.text = @"";
    
    // init once only
    static dispatch_once_t comToken;
    dispatch_once(&comToken, ^{
        [self initNMEAParser];
        [self registerCoreLocation];
        [self createComThread];
    });
    
    // Did we start with an accessory already connected ?
    if ([EAAccessoryManager sharedAccessoryManager].connectedAccessories.count) {
        DLog(@"already connected accessories");
        // get first accessory
        EAAccessory *firstAccessory = [EAAccessoryManager sharedAccessoryManager].connectedAccessories.firstObject;
        DLog(@"accessory : %@", [firstAccessory description]);
        
        // Since the app was started after the accessory was connected, Send a connection notification as the system does when the accessory is connected
        NSNotification *notif = [[NSNotification alloc] initWithName:@"fakeAccessoryNotif" object:nil userInfo:@{EAAccessoryKey: firstAccessory}];
        [self didConnectNotif:notif];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    // Always unregister when dealloc ...
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Core location

- (void)registerCoreLocation {
    // check config
    if (!self.requestLocationSwitch.on) {
        // if switch is off, do not start CoreLocation
        return;
    }
    if(![CLLocationManager locationServicesEnabled] ||
       ( [CLLocationManager authorizationStatus]!=kCLAuthorizationStatusAuthorized && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"The location service is not allowed for this app. Please enable location service on settings app to enable GPS cable communication."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        self.locationManager = [[CLLocationManager alloc] init];
        
        // Check for iOS 7 vs 8+ API
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            
            DLog(@"request authorization");
            [self.locationManager requestAlwaysAuthorization];
        }
        
        if (self.requestLocationSwitch.on) {
            DLog(@"startUpdatingLocation");
            [self.locationManager startUpdatingLocation];
        }
    }
}

#pragma mark - EA notifications

- (void)didConnectNotif:(NSNotification *)notification {
    // Accessory just get connected
    DLog(@"");
    EAAccessory *accessory = [notification.userInfo objectForKey:EAAccessoryKey];
    EAAccessory *selectedBTAccessory = [notification.userInfo objectForKey:EAAccessorySelectedKey];
    if (accessory && accessory.connected) {
        DLog(@"accessory : %@", [accessory description]);
        if (accessory.protocolStrings.count == 0) {
            DLog(@"no protocol declared yet");
            return;
        }
        if (self.accessorySession.accessory.connectionID == accessory.connectionID) {
            DLog(@"re entrance");
            return;
        }

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected Accessory"
                                                        message:[accessory description]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        
        // Create a session with it!
        // Get the first matching accessory thats supported by both the app (in info.plist) and the accessory and use it.
        NSArray *supportedProtocols = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedExternalAccessoryProtocols"];
        NSString *protocol = [[accessory protocolStrings] firstObjectCommonWithArray:supportedProtocols];
        if (!protocol) {
            DLog(@"error, incompatible protocols");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Incompatible protocol"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        DLog(@"Using protocol %@", protocol);
        self.protocol.text = protocol;
        
        //
        self.accessorySession = [[EASession alloc] initWithAccessory:accessory forProtocol:protocol];
        if (!self.accessorySession) {
            DLog(@"error, accessory can't communicate");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Can't communicate with this accessory / protocol"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        // link stream to the com thread
        [self.accessorySession.inputStream setDelegate:self];
        NSRunLoop *comThreadRunloop = [[self.comThread threadDictionary] objectForKey:kComThreadRunloop];
        [self.accessorySession.inputStream scheduleInRunLoop:comThreadRunloop forMode:NSDefaultRunLoopMode];
        
        // start our stream, this will launch callbacks
        [self.accessorySession.inputStream open];
    }
    
    if (selectedBTAccessory) {
        DLog(@"BT accessory selected: %@", [selectedBTAccessory description]);
    }
}

- (void)didDisconnectNotif:(NSNotification *)notification {
    // An accessory just get disconnected
    EAAccessory *accessory = [notification.userInfo objectForKey:EAAccessoryKey];
    DLog(@"accessory : %@", [accessory description]);
    
    if (self.accessorySession.accessory.connectionID == accessory.connectionID) {
        // stop stream
        [self endStreaming];
        self.accessorySession = nil;
        
        self.protocol.text = @"Protocol";
    }
}

#pragma mark - Buttons

- (void)showBTSelector {
    // Show the system bluetooth accessory discovery view
    DLog(@"");
    [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:nil completion:^(NSError *error) {
        if (error) {
            DLog(@"%@", [error localizedDescription]);
        }
    }];
}

- (void)requestLocationChanged {
    // User can disable CoreLocation
    DLog(@"");
    if (self.requestLocationSwitch.on) {
        [self registerCoreLocation];
    }
    else {
        [self.locationManager stopUpdatingLocation];
    }
    // save state
    [[NSUserDefaults standardUserDefaults] setBool:self.requestLocationSwitch.on forKey:kRequestLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)pauseButtonTapped {
    // Pause the receive screen
    self.rxInPause = !self.rxInPause;
    if (self.rxInPause) {
        [self.pause setTitle:@"Go" forState:UIControlStateNormal];
    }
    else {
        [self.pause setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

#pragma mark - RX Text

- (void)updateRxTextWith:(NSData *)data {
    DLog(@"");
    if (!self.rxInPause) {
        // create rx window string
        NSString *currentString = self.receiveTextView.text;
        if (currentString==nil) {
            currentString = @"";
            
        }
        // create new string
        NSMutableString *nextRxString = [NSMutableString stringWithString:currentString];
        if (data==nil) {
            // nothing to get from data ?
            return;
        }
        
        // data to ascii. If not decoded, use hex presentation
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        if (dataString) {
            [nextRxString appendString:dataString];
        }
        else {
            [nextRxString appendString:[data hexadecimalString]];
        }
        
        //limit to 3000 bytes in the Rx window
        if(nextRxString.length > 3000)
        {
            NSUInteger curLength = [data length];
            NSRange arange = NSMakeRange(0, curLength);   // delete firsts characters to insert our string
            [nextRxString deleteCharactersInRange:arange];
        }
        
        // change rx string
        self.receiveTextView.text = nextRxString;
        
        // scroll text view to end
        //[self.rxText scrollRangeToVisible:NSMakeRange(self.rxText.text.length, 0)];   // still make insertion
    }
}

#pragma mark - Com thread

- (void)createComThread {
    // create a com thread dedicated to accessory I/O
    DLog(@"");
    NSThread *aThread = [[NSThread alloc] initWithTarget:self selector:@selector(initComThread) object:nil];
    self.comThread = aThread;
    [self.comThread setName:@"Com thread"];
    [self.comThread setThreadPriority:0.8];
    [self.comThread start];
}

- (void)initComThread {
    DLog(@"new com thread starting");
    @autoreleasepool {
        DLog(@"getting into runloop");
        // create infinte runloop for thread
        BOOL exitNow = FALSE;
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        // add exitNow bool in thread dictionnary
        NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
        [threadDict setValue:@(exitNow) forKey:@"ThreadShouldExitNow"];
        [threadDict setObject:runLoop forKey:kComThreadRunloop];
        // create a timer which will fire in centuries to keep the runloop until input stream is added
        NSTimer *myTimer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:0 target:self selector:@selector(timerCall) userInfo:nil repeats:NO];
        [runLoop addTimer:myTimer forMode:NSRunLoopCommonModes];
        
        [runLoop run];
        
        // should never come here ... or at app end
        DLog(@"exiting com thread");
    }
}

- (void)timerCall {
    // should never be called !!
    DLog(@"enter");
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    // Main io stream event manager
    DLog(@"%@ enter with %@ stream and event %lu", [[NSThread currentThread] name], aStream==self.accessorySession.inputStream ? @"input" : @"output", (unsigned long)eventCode);
    if (aStream == self.accessorySession.inputStream) {
        // input stream
        uint8_t buf[1024];
        NSUInteger dataLength = 0;
        
        switch (eventCode) {
            case NSStreamEventOpenCompleted:
                DLog(@"NSStreamEventOpenCompleted");
                break;
            case NSStreamEventHasBytesAvailable:
                // got bytes to read
                dataLength = [self.accessorySession.inputStream read:buf maxLength:1024];
                if (dataLength) {
                    DLog(@"read %lu bytes", (unsigned long)dataLength);
                    NSData *data = [NSData dataWithBytes:buf length:dataLength];
                    // show on screen
                    [self performSelectorOnMainThread:@selector(updateRxTextWith:) withObject:data waitUntilDone:NO];
                    // NMEA parsing - If you want to parse data using the included NMEA parser lib.
                    NSUInteger res = [self parseNMEA:data];
                    if (res > 0) {
                        // found some NMEA sentences !
                        [self performSelectorOnMainThread:@selector(updateNMEAUI) withObject:nil waitUntilDone:NO];
                    }
                }
                else {
                    DLog(@"nothing to read...");
                    // ??
                }
                break;
            case NSStreamEventErrorOccurred: {
                DLog(@"NSStreamEventErrorOccurred");
#ifdef DEBUG
                NSError *theError = [aStream streamError];
                DLog(@"error is %@", [theError localizedDescription]);
#endif
                // kill the streaming
                [self endStreaming];
                break;
            }
            case NSStreamEventEndEncountered:
                DLog(@"NSStreamEventEndEncountered");
                [self endStreaming];
                break;
            default:
                DLog(@"unused event %lu", (unsigned long)eventCode);
                break;
        }
    }
}

- (void)endStreaming {
    DLog(@"enter");
    // kill stream
    [self.accessorySession.inputStream close];
    [self.accessorySession.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // exit thread
    //NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    //[threadDict setValue:[NSNumber numberWithBool:TRUE] forKey:@"ThreadShouldExitNow"];
}

#pragma mark - NMEA

- (void)initNMEAParser {
    DLog(@"enter");
    nmea_zero_INFO(&info);              // reset info for results
    if (parser.buffer != NULL) {
        nmea_parser_destroy(&parser);   // destroy previously created parser
    }
    nmea_parser_init(&parser);          // init parser
}

- (NSUInteger)parseNMEA:(NSData *)data {
    DLog(@"enter with %lu bytes", (unsigned long)[data length]);
    // let's get a C buffer from data
    char *buff = (char *)[data bytes];
    NSUInteger res = nmea_parse(&parser, buff, (int)[data length], &info);    // updates info
    
    // small resumé
    DLog(@"analysed %lu sentences", (unsigned long)res);
    DLog(@"mask is 0x%02X", info.smask);
    DLog(@"sig is %i, fix is %i", info.sig, info.fix);
    DLog(@"GPS satellites in view %i, in use %i", info.GPSsatinfo.inview, info.GPSsatinfo.inuse);
    DLog(@"GLONASS satellites in view %i, in use %i", info.GLONASSsatinfo.inview, info.GLONASSsatinfo.inuse);
    
    return res;
}

- (void)updateNMEAUI {
    // altitude
    self.altitude.text = [NSString stringWithFormat:@"%0.2f", info.elv];
    // latitude
    double latdeg = nmea_ndeg2degree(info.lat);
    self.latitude.text = [NSString stringWithFormat:@"%0.8f", latdeg];
    // long
    double londeg = nmea_ndeg2degree(info.lon);
    self.longitude.text = [NSString stringWithFormat:@"%0.8f", londeg];
    
    // gst precision
    if (info.smask & GPGST) {
        self.XYAccuracy.text = [NSString stringWithFormat:@"%0.2f M", info.dev_xy];
    }
    
    self.GPSUsed.text = [NSString stringWithFormat:@"%2i", info.GPSsatinfo.inuse];
}

@end
