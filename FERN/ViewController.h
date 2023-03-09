//
//  ViewController.h
//  FERN
//
//  Added by Hopp, Dan on 3/9/23.
//  From EosEADataEnt development kit.

#ifndef ViewController_h // added from file creation
#define ViewController_h // added from file creation

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIButton *BTAccessoriesButton;

@property (nonatomic, weak) IBOutlet UILabel *latitude;
@property (nonatomic, weak) IBOutlet UILabel *longitude;
@property (nonatomic, weak) IBOutlet UILabel *altitude;
@property (nonatomic, weak) IBOutlet UILabel *XYAccuracy;
@property (nonatomic, weak) IBOutlet UILabel *GPSUsed;

@property (nonatomic, weak) IBOutlet UILabel *protocol;
@property (nonatomic, weak) IBOutlet UISwitch *requestLocationSwitch;
@property (nonatomic, weak) IBOutlet UITextView *receiveTextView;
@property (nonatomic, weak) IBOutlet UIButton *pause;

@end

#endif /* ViewController_h */
