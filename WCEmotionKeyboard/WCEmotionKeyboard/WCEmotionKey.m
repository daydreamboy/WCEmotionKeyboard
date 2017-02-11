//
//  WCEmotionKey.m
//  Lottery360
//
//  Created by wesley chen on 15/5/5.
//  Copyright (c) 2015年 Qihoo. All rights reserved.
//

#import "WCEmotionKeyboard-Prefix.h"

@interface WCEmotionKey () <UIInputViewAudioFeedback>
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UIEvent *currentEvent;
/*!
 *  Default is YES
 */
@property (nonatomic, assign) BOOL dispatchTouchesToSuperview;
@end

@implementation WCEmotionKey

@synthesize bean = _bean;

- (instancetype)init {
    self = [super init];
    if (self) {
        _icon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        [self addSubview:_icon];
        _dispatchTouchesToSuperview = YES;
    }
    
    return self;
}

#pragma mark - Setters and Getters

- (WCEmotionBean *)bean {
    return _bean;
}

- (void)setBean:(WCEmotionBean *)bean {
    
    [self cancelTrackingWithEvent:_currentEvent];
    _bean = bean;
    
    [self setImage:nil forState:UIControlStateNormal];
    [self setImage:nil forState:UIControlStateHighlighted];
    _icon.hidden = YES;
    
    if (bean.type == WCEmotionBeanTypeAccessoryIcon) {
        NSString *imageName = ImageBundled(bean.png);
        NSString *imageNameHighlight = [NSString stringWithFormat:@"%@_h", imageName];
        
        [self setContentMode:UIViewContentModeCenter];
        [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:imageNameHighlight] forState:UIControlStateHighlighted];
        _dispatchTouchesToSuperview = NO;
    }
    else {
        _icon.hidden = NO;
        _icon.image = [UIImage imageNamed:IconBundled(bean.png)];
        _icon.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _dispatchTouchesToSuperview = YES;
    }
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_dispatchTouchesToSuperview) {
        [[self superview] touchesBegan:touches withEvent:event];
    }
    
    [super touchesBegan:touches withEvent:event];
    _currentEvent = event;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_dispatchTouchesToSuperview) {
        [[self superview] touchesMoved:touches withEvent:event];
    }
    [super touchesMoved:touches withEvent:event];
    _currentEvent = event;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_dispatchTouchesToSuperview) {
        [[self superview] touchesEnded:touches withEvent:event];
    }
    [super touchesEnded:touches withEvent:event];
    _currentEvent = event;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_dispatchTouchesToSuperview) {
        [[self superview] touchesCancelled:touches withEvent:event];
    }
    [super touchesCancelled:touches withEvent:event];
    _currentEvent = event;
}

@end
