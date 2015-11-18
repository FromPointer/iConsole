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
    iConsoleLogNone = 0,
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


+ (iConsole *)sharedConsole;
+ (void)showConsole;
+ (void)hideConsole;


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