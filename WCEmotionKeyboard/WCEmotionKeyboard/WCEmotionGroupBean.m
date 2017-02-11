//
//  WCEmojiGroupBean.m
//  HelloEmoji
//
//  Created by wesley chen on 15/4/22.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import "WCEmotionKeyboard-Prefix.h"

@implementation WCEmotionGroupBean

+ (WCEmotionGroupBean *)beanWithEmotionGroupName:(NSString *)emotionGroupName {
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"EmotionIcons" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *path = [bundle pathForResource:[NSString stringWithFormat:@"%@/info", emotionGroupName] ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    WCEmotionGroupBean *groupBean = [[WCEmotionGroupBean alloc] init];
    groupBean.emotion_group_identifier = dict[STR_PROP(emotion_group_identifier)];
    groupBean.emotion_group_type = dict[STR_PROP(emotion_group_type)];
    
    NSMutableArray *emojiBeans = [NSMutableArray array];
    NSArray *arr = dict[STR_PROP(emotion_group_icons)];
    for (NSDictionary *dict in arr) {
        WCEmotionBean *bean = [[WCEmotionBean alloc] initWithDict:dict];
        [emojiBeans addObject:bean];
    }
    groupBean.emotion_group_icons = emojiBeans;

    return groupBean;
}

@end
