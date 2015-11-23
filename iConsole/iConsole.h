//
//  iConsole.h
//  iConsoleDemo
//
//  Created by zuopengl on 11/18/15.
//  Copyright © 2015 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  protocol iConsoleDelegate
 */
@protocol iConsoleDelegate <NSObject>

@optional
- (void)handleConsoleWithCommand:(NSString *)command;

@end



typedef NS_ENUM(NSUInteger, iConsoleLogLevel) {
    iConsoleLogNone      = 0,
    iConsoleLogCrash     = 1,
    iConsoleLogError     = 2,
    iConsoleLogWarning   = 3,
    iConsoleLogInfo      = 4,
};

/**
 *  iConsole
 */
@interface iConsole : UIViewController

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) iConsoleLogLevel logLevel;
@property (nonatomic, weak) id<iConsoleDelegate> delegate;



// style
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, assign) UIScrollViewIndicatorStyle indicatorStyle;

// control activation
@property (nonatomic, assign) NSUInteger simulatorTouchesToShow;
@property (nonatomic, assign) NSUInteger deviceTouchesToShow;
@property (nonatomic, assign) BOOL enabledTouchesToShow;
@property (nonatomic, assign) BOOL enabledSimulatorShakeToShow;
@property (nonatomic, assign) BOOL enabledDeviceShakeToShow;

@property (nonatomic, assign) BOOL saveToDisk;

@property (nonatomic, copy) NSString *logSubmissionEmail;


+ (iConsole *)sharedConsole;
+ (void)show;
+ (void)hide;
+ (void)clear;


#pragma mark - logger

+ (void)info:(NSString *)fmt, ...;
+ (void)warn:(NSString *)fmt, ...;
+ (void)error:(NSString *)fmt, ...;
+ (void)crash:(NSString *)fmt, ...;


@end



/**
 *  iConsoleWindow
 */
@interface iConsoleWindow : UIWindow

@end