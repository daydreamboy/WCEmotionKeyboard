//
//  WCEmojiGroupBean.h
//  HelloEmoji
//
//  Created by wesley chen on 15/4/22.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WCEmotionGroupBean : NSObject

@property (nonatomic, strong) NSArray *emotion_group_icons;
@property (nonatomic, copy) NSString *emotion_group_identifier;
@property (nonatomic, strong) NSNumber *emotion_group_type;

+ (WCEmotionGroupBean *)beanWithEmotionGroupName:(NSString *)emotionGroupName;

@end
