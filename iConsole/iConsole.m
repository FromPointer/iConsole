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


#define EDITFIELD_HEIGHT 28
#define ACTION_BUTTON_WIDTH 28


@interface iConsole()
<
UITextFieldDelegate,
UIActionSheetDelegate
>

@property (nonatomic, strong) UITextView *consoleView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *actionButton;

@property(nonatomic, strong) UIColor *textColor;
@property(nonatomic, assign) UIScrollViewIndicatorStyle indicatorStyle;
@property(nonatomic, copy)   NSString *inputPlaceholderString;

@end

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
    _textColor = [UIColor redColor];
    _indicatorStyle = UIScrollViewIndicatorStyleDefault;
    _inputPlaceholderString = @"please input keyword";
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
        _inputField.font = [UIFont fontWithName:@"Menlo-Bold" size:10];
        _inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _inputField.autocorrectionType = UITextAutocorrectionTypeNo;
        _inputField.returnKeyType = UIReturnKeyDone;
        _inputField.enablesReturnKeyAutomatically = NO;
        _inputField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _inputField.placeholder = _inputPlaceholderString;
        _inputField.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _inputField.delegate = self;

        [self.view addSubview:_inputField];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    
    [_consoleView scrollRangeToVisible:NSMakeRange([_consoleView.text length], 0)];
}


#pragma mark - event for action

- (void)didTapActionButton:(id)sender {
    NSLog(@"didTapActionButton");
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear log" otherButtonTitles:@"Send by Email", @"Close Console", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [actionSheet showInView:self.view];
}


#pragma mark - keyboard show/hidden

- (void)keyboardWillShow:(NSNotification *)not {
    
}


- (void)keyboardWillHide:(NSNotification *)not {
    
}


#pragma mark - show/hidden

+ (void)showConsole {
    
}


+ (void)hideConsole {
    
}


+ (void)clearConsole {
    
}


+ (void)sendLogToEmail {
    
}


#pragma mark - logger

+ (void)info:(NSString *)fmt, ... {
    va_list argList;
    va_start(argList, fmt);
    [self infoWithFormat:fmt arguments:argList];
    va_end(argList);
    
}

+ (void)infoWithFormat:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogInfo) {
        [self log:[@"INFO: " stringByAppendingString:fmt] arguments:argList];
    }
}


+ (void)warn:(NSString *)fmt, ... {
    va_list argList;
    va_start(argList, fmt);
    [self warnWithFormat:fmt arguments:argList];
    va_end(argList);
}

+ (void)warnWithFormat:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogWarning) {
        [self log:[@"WARNING: " stringByAppendingString:fmt] arguments:argList];
    }
}

+ (void)error:(NSString *)fmt, ... {
    va_list argList;
    va_start(argList, fmt);
    [self errorWithFormat:fmt arguments:argList];
    va_end(argList);
}

+ (void)errorWithFormat:(NSString *)fmt arguments:(va_list)argList {
    if ([self sharedConsole].logLevel >= iConsoleLogError) {
        [self log:[@"ERROR: " stringByAppendingString:fmt] arguments:argList];
    }
}

+ (void)crash:(NSString *)fmt, ... {
    va_list argList;
    va_start(argList, fmt);
    [self crashWithFormat:fmt arguments:argList];
    va_end(argList);
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
    
}


#pragma mark - delegate for UITextFieldDelegate



#pragma mark - delegate for UIActionSheetDelegate

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    [iConsole hideConsole];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [iConsole clearConsole];
    } else if (buttonIndex != actionSheet.cancelButtonIndex) {
        if (buttonIndex == 1) {
            [iConsole sendLogToEmail];
        } else {
            [iConsole hideConsole];
        }
    }
}

@end


/**
 *  implementation for iConsoleWindow
 */
@implementation iConsoleWindow


@end
