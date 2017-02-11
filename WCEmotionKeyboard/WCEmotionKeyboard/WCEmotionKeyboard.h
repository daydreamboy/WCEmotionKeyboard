//
//  WCEmojiKeyboard.h
//  HelloEmoji
//
//  Created by wesley chen on 15/4/21.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WCEmotionKeyboard : UIView

- (instancetype)init;
+ (instancetype)sharedInstance;
+ (void)resetSharedInstance;

@end
