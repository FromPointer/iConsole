//
//  iConsole.m
//  iConsoleDemo
//
//  Created by zuopengl on 11/18/15.
//  Copyright © 2015 Apple. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Foundation/NSThread.h>
#import <stdarg.h>
#import <string.h>

#import "iConsole.h"


//
#define EDITFIELD_HEIGHT 28
#define ACTION_BUTTON_WIDTH 28


//
#define IC_MainWindow ([[iConsole sharedConsole] mainWindow])


@interface iConsole()
<
UITextFieldDelegate,
UIActionSheetDelegate
>

@property (nonatomic, assign) BOOL animating;

@property (nonatomic, assign) NSUInteger maxLogItems;
// control
@property (nonatomic, strong) UITextView  *consoleView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton    *actionButton;

//
@property (nonatomic, copy)   NSString *inputPlaceholderString;

// log string
@property (nonatomic, strong) NSString *infoString;
@property (nonatomic, strong) NSMutableArray<NSString *> *logs;

//
- (void)saveSettings;
- (void)showConsole;
- (void)hideConsole;
- (void)clearConsole;
- (void)sendLogToEmail;
- (void)resetLog;

@end

void iConsoleUncaughtExceptionHandler(NSException *exception) {
    
    [iConsole crash:@"%@", exception];
    
    [[iConsole sharedConsole] saveSettings];
}


@implementation iConsole

+ (void)load {
    [iConsole performSelectorOnMainThread:@selector(sharedConsole) withObject:nil waitUntilDone:NO];
}


+ (iConsole *)sharedConsole {
    @synchronized(self) {
        static iConsole *consoleInst = nil;
        if (consoleInst == nil) {
            consoleInst = [[[self class] alloc] init];
        }
        return consoleInst;
    }
}


- (instancetype)init {
    self = [super init];
    if (self) {
        [self _baseInit];
    }
    return self;
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _baseInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _baseInit];
    }
    return self;
}


- (void)_baseInit {
    
    NSSetUncaughtExceptionHandler(&iConsoleUncaughtExceptionHandler);
    
    _enabled = YES;
    _animating = NO;
    
    _backgroundColor = [UIColor blackColor];
    _textColor = [UIColor whiteColor];
    _indicatorStyle = UIScrollViewIndicatorStyleDefault;
    
    _inputPlaceholderString = @"please enter command...";
    
    _infoString = @"iConsole: copy from ****";
    _logs = [NSMutableArray array];
    
    _maxLogItems = 1000;
    
    _simulatorTouchesToShow = 2;
    _deviceTouchesToShow = 2;
    _enabledTouchesToShow = YES;
    _enabledSimulatorShakeToShow = YES;
    _enabledDeviceShakeToShow = YES;
    
    _saveToDisk = YES;
    
    _logLevel = iConsoleLogInfo;
    
    _logSubmissionEmail = @"471347111@qq.com";
    
    [self registerStatusBarNotifications];
}


- (void)dealloc {
    [self unregisterStatusBarNotifications];
}


- (void)registerStatusBarNotifications {
    if (UIApplicationDidEnterBackgroundNotification) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveSettings)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveSettings)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rotateView:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resizeView:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}


- (void)unregisterStatusBarNotifications {
    if (UIApplicationDidEnterBackgroundNotification) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:self];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}


- (void)unregisterKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - view load

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.view.autoresizesSubviews = YES;
    
    _consoleView = [[UITextView alloc] initWithFrame:self.view.frame];
    _consoleView.font = [UIFont fontWithName:@"Menlo-Bold" size:10];
    _consoleView.textColor = _textColor;
    _consoleView.backgroundColor = [UIColor clearColor];
    _consoleView.indicatorStyle = _indicatorStyle;
    _consoleView.editable = NO;
    _consoleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_consoleView];
    
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_actionButton setTitle:@"⚙" forState:UIControlStateNormal];
    [_actionButton setTitleColor:_textColor forState:UIControlStateNormal];
    [_actionButton setTitleColor:[_textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
    _actionButton.titleLabel.font = [_actionButton.titleLabel.font fontWithSize:ACTION_BUTTON_WIDTH];
    _actionButton.frame = CGRectMake(self.view.frame.size.width - ACTION_BUTTON_WIDTH - 5,
                                     self.view.frame.size.height - EDITFIELD_HEIGHT - 5,
                                     ACTION_BUTTON_WIDTH, EDITFIELD_HEIGHT);
    [_actionButton addTarget:self action:@selector(didTapActionButton:) forControlEvents:UIControlEventTouchUpInside];
    _actionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:_actionButton];
    
    
    if (_delegate) {
        _inputField = [[UITextField alloc] initWithFrame:CGRectMake(5, self.view.frame.size.height - EDITFIELD_HEIGHT - 5,
                                                                    self.view.frame.size.width - 15 - ACTION_BUTTON_WIDTH,
                                                                    EDITFIELD_HEIGHT)];
        _inputField.backgroundColor = [UIColor whiteColor];
        _inputField.inputView.backgroundColor = [UIColor whiteColor];
        _inputField.font = [UIFont fontWithName:@"Menlo-Bold" size:10];
        _inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _inputField.autocorrectionType = UITextAutocorrectionTypeNo;
        _inputField.borderStyle = UITextBorderStyleRoundedRect;
        _inputField.returnKeyType = UIReturnKeyDone;
        _inputField.enablesReturnKeyAutomatically = NO;
        _inputField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _inputField.placeholder = _inputPlaceholderString;
        _inputField.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _inputField.delegate = self;

        [self.view addSubview:_inputField];
        
        [self registerKeyboardNotifications];
    }
    
    [_consoleView scrollRangeToVisible:NSMakeRange([_consoleView.text length], 0)];
}


- (void)viewDidUnload {
    [self unregisterKeyboardNotifications];
    _consoleView = nil;
    _inputField = nil;
    _actionButton = nil;
    
    [super viewDidUnload];
    
}


#pragma mark - event for action

- (void)didTapActionButton:(id)sender {
    
    [self findAndResignFirstResponseInView:self.view];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear log" otherButtonTitles:@"Send by Email", @"Close Console", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [actionSheet showInView:self.view];
}


#pragma mark - delegate for UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [iConsole clear];
    } else if (buttonIndex != actionSheet.cancelButtonIndex) {
        if (buttonIndex == 1) {
            [[iConsole sharedConsole] sendLogToEmail];
        } else {
            [iConsole hide];
        }
    }
}


#pragma mark - Notification events (keyboard show/hidden)

- (void)keyboardWillShow:(NSNotification *)not {
    if (self.view.superview == nil) {
        return;
    }
    
    CGRect frame = [[not.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [[not.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[not.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    
    CGRect bounds = [self onScreenFrame];
    switch ([[UIApplication sharedApplication] statusBarOrientation])
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            bounds.origin.y += frame.size.height;
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            bounds.size.width -= frame.size.width;
            break;
        case UIInterfaceOrientationLandscapeRight:
            bounds.origin.x += frame.size.width;
            bounds.size.width -= frame.size.width;
            break;
    }
    
    self.view.frame = bounds;
    
    [UIView commitAnimations];
}


- (void)keyboardWillHide:(NSNotification *)not {
    if (self.view.superview == nil) {
        return;
    }
    
    CGFloat duration = [[not.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[not.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    
    self.view.frame = [self onScreenFrame];
    
    [UIView commitAnimations];
}


#pragma mark - Notification events (status bar change)

- (void)rotateView:(NSNotification *)not {
    if (self.view.superview == nil) {
        return;
    }
    
    self.view.transform = [self viewTransform];
    self.view.frame = [self onScreenFrame];
    
    if (_delegate) {
        CGRect frame = self.view.frame;
        frame.size.height -= EDITFIELD_HEIGHT + 10;
        self.consoleView.frame = frame;
    }
}


- (void)resizeView:(NSNotification *)not {
    if (self.view.superview == nil) {
        return;
    }
    
    CGRect frame = [[not.userInfo objectForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
            bounds.origin.y += frame.size.height;
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            bounds.size.height -= frame.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            bounds.origin.x += frame.size.width;
            bounds.size.width -= frame.size.width;
            break;
        case UIInterfaceOrientationLandscapeRight:
            bounds.size.width -= frame.size.width;
            break;
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.35];
    self.view.frame = bounds;
    [UIView commitAnimations];
}


#pragma mark - show/hide/clear (public method)

+ (void)show {
    [[iConsole sharedConsole] showConsole];
}

+ (void)hide {
    [[iConsole sharedConsole] hideConsole];
}

+ (void)clear {
    [[iConsole sharedConsole] clearConsole];
}


- (BOOL)findAndResignFirstResponseInView:(UIView *)view {
    if ([view isFirstResponder]) {
        [view resignFirstResponder];
        return YES;
    }
    
    for (UIView *subView in view.subviews) {
        if ([self findAndResignFirstResponseInView:subView]) {
            return YES;
        }
    }
    
    return NO;
}


- (void)findAndDelegateFirstResponse {
    if (_delegate) {
        [_inputField becomeFirstResponder];
    }
}

#pragma mark - compute frame and offset

- (CGRect)offScreenFrame {
    CGRect sFrame = [self onScreenFrame];
    
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationPortrait: { // home button on the bottom
            sFrame.origin.y = sFrame.size.height;
        }
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown: { // home button on the top
            sFrame.origin.y = -sFrame.size.height;
        }
            break;
            
        case UIInterfaceOrientationLandscapeLeft: { // home button on the left
            sFrame.origin.y = sFrame.size.width;
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight: { // home button on the right
            sFrame.origin.y = -sFrame.size.width;
        }
            break;
            
        default: { //UIInterfaceOrientationUnknown
            sFrame.origin.y = sFrame.size.height;
        }
            break;
    }
    
    return sFrame;
}


- (CGRect)onScreenFrame {
    return [[UIScreen mainScreen] bounds];
}


- (CGAffineTransform)viewTransform {
    CGFloat angle = 0;
    
    switch ([UIApplication sharedApplication].statusBarOrientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
            angle = 0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
    }
    
    return CGAffineTransformMakeRotation(angle);
}


#pragma mark - private method

- (NSString *)URLEncodedString:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}

- (void)sendLogToEmail {
    NSString *URLSafeName = [self URLEncodedString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    NSString *URLSafeLog = [self URLEncodedString:[_logs componentsJoinedByString:@"\n"]];
    NSMutableString *URLString = [NSMutableString stringWithFormat:@"mailto:%@?subject=%@%%20Console%%20Log&body=%@",
                                  _logSubmissionEmail ?: @"", URLSafeName, URLSafeLog];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
}


- (void)showConsole {
    if (self.enabled) {
        if (!_animating && self.view.superview == nil) {
            [self setConsoleText];
            [self findAndResignFirstResponseInView:self.view];
            
            self.animating = YES;
            self.view.frame = [self offScreenFrame];
            [[self mainWindow] addSubview:self.view];
            
            __weak typeof(self) wself = self;
            [UIView animateWithDuration:0.4 animations:^{
                wself.view.frame = [self onScreenFrame];
                wself.view.transform = [wself viewTransform];
            } completion:^(BOOL finished) {
                wself.animating = NO;
                [wself findAndDelegateFirstResponse];
            }];
        }
    }
}


- (void)hideConsole {
    if (self.enabled) {
        if (!_animating && self.view.superview) {
            [self findAndResignFirstResponseInView:self.view];
            
            self.animating = YES;
            
            __weak typeof(self) wself = self;
            [UIView animateWithDuration:0.4 animations:^{
                wself.view.frame = [self offScreenFrame];
            } completion:^(BOOL finished) {
                wself.animating = NO;
                [wself.view removeFromSuperview];
            }];
        }
    }
}


- (void)clearConsole {
    [self resetLog];
    [[iConsole sharedConsole] setConsoleText];
}


- (void)resetLog {
    if (self.logs == nil) {
        self.logs = [NSMutableArray array];
    }
    [self.logs removeAllObjects];
}


- (void)setConsoleText {
    NSString *consoleString = _infoString;
    NSUInteger touches = TARGET_OS_SIMULATOR ? _simulatorTouchesToShow : _deviceTouchesToShow;
    
    if (touches >0 && touches < 10) {
        consoleString = [consoleString stringByAppendingFormat:@"\nSwipe down with %zd finger%@ to hide console", touches, (touches != 1) ? @"s" : @""];
    } else {
        consoleString = [consoleString stringByAppendingFormat:@"\nShake Device to hide console"];
    }
    consoleString = [consoleString stringByAppendingString:@"\n------------------------------------------------\n"];
    consoleString = [consoleString stringByAppendingString:[[_logs arrayByAddingObject:@">"] componentsJoinedByString:@"\n"]];
    
    _consoleView.text = consoleString;
    [_consoleView scrollRangeToVisible:NSMakeRange(consoleString.length, 0)];
}


- (void)saveSettings {
    if (_saveToDisk) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (UIWindow *)mainWindow {
    UIWindow *mWindow = nil;
    if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)]) {
        mWindow =  [[UIApplication sharedApplication].delegate window];
    } else {
        mWindow = [[UIApplication sharedApplication] keyWindow];
    }
    return mWindow;
}


#pragma mark - logger

+ (void)info:(NSString *)fmt, ... {
    va_list marker;
    va_start(marker, fmt);
    [self infoWithFormat:fmt arguments:marker];
    va_end(marker);
}

+ (void)infoWithFormat:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogInfo) {
        [self log:[@"INFO: " stringByAppendingString:fmt] arguments:argList];
    }
}


+ (void)warn:(NSString *)fmt, ... {
    va_list marker;
    va_start(marker, fmt);
    [self warnWithFormat:fmt arguments:marker];
    va_end(marker);
}

+ (void)warnWithFormat:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogWarning) {
        [self log:[@"WARNING: " stringByAppendingString:fmt] arguments:argList];
    }
}

+ (void)error:(NSString *)fmt, ... {
    va_list marker;
    va_start(marker, fmt);
    [self errorWithFormat:fmt arguments:marker];
    va_end(marker);
}

+ (void)errorWithFormat:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogError) {
        [self log:[@"ERROR: " stringByAppendingString:fmt] arguments:argList];
    }
}

+ (void)crash:(NSString *)fmt, ... {
    va_list marker;
    va_start(marker, fmt);
    [self crashWithFormat:fmt arguments:marker];
    va_end(marker);
}

+ (void)crashWithFormat:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogCrash) {
        [self log:[@"CRASH: " stringByAppendingString:fmt] arguments:argList];
    }
}


+ (void)log:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogNone) {
        
        if ([self sharedConsole].enabled) {
            NSString *message = [(NSString *)[NSString alloc] initWithFormat:fmt arguments:argList];
            
            // Add date info to log message
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSS"];
            NSString *currentDate = [dateFormatter stringFromDate:[NSDate date]];
            NSString *messageWithDate = [NSString stringWithFormat:@"%@ %@", currentDate, message];
            
            if ([NSThread currentThread] == [NSThread mainThread]) {
                [[self sharedConsole] logOnMainThread:messageWithDate];
            } else {
                [[self sharedConsole] performSelectorOnMainThread:@selector(logOnMainThread:) withObject:messageWithDate waitUntilDone:NO];
            }
        }
     }
}


- (void)logOnMainThread:(NSString *)message {
    [_logs addObject:[@"> " stringByAppendingString:message]];
    
    if ([_logs count] > _maxLogItems) {
        [_logs removeObjectAtIndex:0];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:_logs forKey:@"iConsoleLog"];
    
    if (self.view.superview) {
        [self setConsoleText];
    }
}


#pragma mark - delegate for UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (_inputField == textField) {
        [textField resignFirstResponder];
    }
    return YES;
}


- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (_inputField == textField) {
        if (![textField.text isEqualToString:@""]) {
            [iConsole info:@"%@", textField.text];
            if ([_delegate respondsToSelector:@selector(handleConsoleWithCommand:)]) {
                [_delegate handleConsoleWithCommand:textField.text];
            }
            textField.text = @"";
        }
    }
}

@end


/**
 *  implementation for iConsoleWindow
 */
@implementation iConsoleWindow

- (void)sendEvent:(UIEvent *)event {
    
    if ([iConsole sharedConsole].enabled && event.type == UIEventTypeTouches) {
        
        NSSet *touches = [event allTouches];
        
        if ([touches count] == (TARGET_IPHONE_SIMULATOR ? [iConsole sharedConsole].simulatorTouchesToShow: [iConsole sharedConsole].deviceTouchesToShow)) {
            
            BOOL allUp = YES;
            BOOL allDown = YES;
            BOOL allLeft = YES;
            BOOL allRight = YES;
            
            for (UITouch *touch in touches) {
                if ([touch locationInView:self].y <= [touch previousLocationInView:self].y) {
                    allDown = NO;
                }
                
                if ([touch locationInView:self].y >= [touch previousLocationInView:self].y) {
                    allUp = NO;
                }
                
                if ([touch locationInView:self].x <= [touch previousLocationInView:self].x) {
                    allLeft = NO;
                }
                
                if ([touch locationInView:self].x >= [touch previousLocationInView:self].x) {
                    allRight = NO;
                }
            }
            
            switch ([UIApplication sharedApplication].statusBarOrientation) {
                case UIInterfaceOrientationPortrait:
                case UIInterfaceOrientationUnknown: {
                    if (allUp) {
                        [iConsole show];
                    }  else if (allDown) {
                        [iConsole hide];
                    }
                    break;
                }
                
                case UIInterfaceOrientationPortraitUpsideDown: {
                    if (allDown) {
                        [iConsole show];
                    } else if (allUp) {
                        [iConsole hide];
                    }
                    break;
                }
                
                case UIInterfaceOrientationLandscapeLeft: {
                    if (allRight)  {
                        [iConsole show];
                    } else if (allLeft) {
                        [iConsole hide];
                    }
                    break;
                }
                
                case UIInterfaceOrientationLandscapeRight: {
                    if (allLeft) {
                        [iConsole show];
                    } else if (allRight) {
                        [iConsole hide];
                    }
                    break;
                }
            }
        }
    }
    
    return [super sendEvent:event];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if ([iConsole sharedConsole].enabled &&
        (TARGET_IPHONE_SIMULATOR ? [iConsole sharedConsole].enabledSimulatorShakeToShow: [iConsole sharedConsole].enabledDeviceShakeToShow)) {
       
        if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
            
            if ([iConsole sharedConsole].view.superview == nil) {
                [iConsole show];
            } else {
                [iConsole hide];
            }
        }
    }
    
    [super motionEnded:motion withEvent:event];
}

@end
