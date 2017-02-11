//
//  ViewController.m
//  WCEmotionKeyboard
//
//  Created by wesley chen on 15/5/7.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import "ViewController.h"
#import "WCEmotionKeyboard-Prefix.h"

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

// @sa http://stackoverflow.com/questions/5029267/is-there-any-way-of-asking-an-ios-view-which-of-its-children-has-first-responder
+ (id)currentFirstResponder {
	currentFirstResponder = nil;
	[[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
	return currentFirstResponder;
}

- (void)findFirstResponder:(id)sender {
	currentFirstResponder = self;
}

@end

@interface ViewController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) UIToolbar *inputAccessoryView;
@property (nonatomic, strong) UIView *inputView;

@property (nonatomic, strong) UIBarButtonItem *imageButtonItem;
@property (nonatomic, strong) UIBarButtonItem *cameraButtonItem;
@property (nonatomic, strong) UIBarButtonItem *emojiButtonItem;

@property (nonatomic, strong) id previousResponder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 40, screenSize.width - 2 * 20, 30)];
    textField.delegate = self;
    textField.backgroundColor = [UIColor colorWithRed:0.506 green:0.813 blue:1.000 alpha:1.000];
    textField.placeholder = @"Type here...";
    textField.inputView = [WCEmotionKeyboard sharedInstance];
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:textField];
    self.textField = textField;
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(20, 100, screenSize.width - 2 * 20, 150)];
    textView.delegate = self;
    textView.backgroundColor = [UIColor colorWithRed:1.000 green:0.879 blue:0.656 alpha:1.000];
    textView.font = [UIFont systemFontOfSize:15];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:textView];
    self.textView = textView;
    
//    [self.textField becomeFirstResponder];
    [self.textView becomeFirstResponder];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

//- (UIView *)inputView {
//    return [WCEmotionKeyboard sharedInstance];
//}

- (UIView *)inputAccessoryView {
    if (!_inputAccessoryView) {
        self.imageButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pic_n"] style:UIBarButtonItemStylePlain target:self action:@selector(barItemClicked:)];
        self.cameraButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"photo_n"] style:UIBarButtonItemStylePlain target:self action:@selector(barItemClicked:)];
        self.emojiButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"emoji_n"] style:UIBarButtonItemStylePlain target:self action:@selector(barItemClicked:)];
        
        NSArray *barButtonItems = [NSArray arrayWithObjects:
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   self.imageButtonItem,
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   self.cameraButtonItem,
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   self.emojiButtonItem,
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   nil];
        
        _inputAccessoryView = [self toolbarWithBarButtonItemArray:barButtonItems];
        
    }
    
    return _inputAccessoryView;
}

- (UIToolbar *)toolbarWithBarButtonItemArray:(NSArray *)barButtonItemArray {
    
    UIBarStyle barStyle = UIBarStyleDefault;
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    toolbar.barStyle = barStyle;
    toolbar.translucent = YES;
    toolbar.items = barButtonItemArray;
    [toolbar sizeToFit];
    
    return toolbar;
}

#pragma mark - Actions

- (void)viewTapped:(UITapGestureRecognizer *)recognizer {
    UIView *tappedView = recognizer.view;
    if (tappedView == self.view) {
        
        if (![self isFirstResponder]) {
            
            // Don't keep track of self
            _previousResponder = [UIResponder currentFirstResponder];
            NSLog(@"%@", _previousResponder);
        }
        
        [self.textField resignFirstResponder];
        [self.textView resignFirstResponder];
    }
}

- (void)barItemClicked:(UIBarButtonItem *)sender {
    if (sender == self.imageButtonItem) {
    }
    else if (sender == self.cameraButtonItem) {
        
    }
    else if (sender == self.emojiButtonItem) {
        
        if ([self.textField isFirstResponder]) {
            [self toggleEmotionKeyboard:self.textField];
        }
        else if ([self.textView isFirstResponder]) {
            [self toggleEmotionKeyboard:self.textView];
        }
        else {
            //[self resignFirstResponder];
//            id currentFirstResponder = [UIResponder currentFirstResponder];
//            NSLog(@"%@", currentFirstResponder);
            
            // Let previous responder become first responder
            [_previousResponder becomeFirstResponder];
        }
    }
}

- (void)toggleEmotionKeyboard:(UIResponder *)textEditView {
    
    if ([textEditView isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)textEditView;
        
        if (textField.inputView) {
            textField.inputView = nil;
        }
        else {
            textField.inputView = [WCEmotionKeyboard sharedInstance];
        }
        [textField reloadInputViews];
    }
    else if ([textEditView isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)textEditView;
     
        if (textView.inputView) {
            textView.inputView = nil;
        }
        else {
            textView.inputView = [WCEmotionKeyboard sharedInstance];
        }
        [textView reloadInputViews];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSLog(@"range: %@, string: %@", NSStringFromRange(range), string);
    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSLog(@"range: %@, text: %@", NSStringFromRange(range), text);
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    NSLog(@"textViewDidChange");
}

@end
