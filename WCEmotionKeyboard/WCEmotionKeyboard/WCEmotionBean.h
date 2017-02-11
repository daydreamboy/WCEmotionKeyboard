//
//  WCEmojiBean.h
//  HelloEmoji
//
//  Created by wesley chen on 15/4/22.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WCEmotionBeanType) {
    WCEmotionBeanTypeRecentUsed = 0,
    WCEmotionBeanTypeAccessoryIcon,
    WCEmotionBeanTypeApple,
};

@interface WCEmotionBean : NSObject <NSCoding>

@property (nonatomic, copy) NSString *code;
@property (nonatomic, assign) WCEmotionBeanType type;
@property (nonatomic, copy) NSString *group;
@property (nonatomic, copy) NSString *chs;
@property (nonatomic, copy) NSString *png;
@property (nonatomic, copy) NSString *gif;
@property (nonatomic, copy) NSString *icon;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
