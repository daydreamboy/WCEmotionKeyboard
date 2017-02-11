//
//  WCEmojiPage.h
//  HelloEmoji
//
//  Created by wesley chen on 15/4/21.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WCEmotionPageDelegate <NSObject>
@required
- (void)keyTapped:(id)keyData;
@end

@interface WCEmotionPage : UIView

@property (nonatomic, weak) id<WCEmotionPageDelegate> delegate;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign, getter=isPortrait) BOOL portrait;

- (void)displayIcons:(NSArray *)icons withMaxRows:(NSUInteger)maxRows maxColumns:(NSUInteger)maxColumns;

@end
