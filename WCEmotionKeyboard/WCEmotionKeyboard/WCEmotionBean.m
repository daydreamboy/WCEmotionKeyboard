//
//  WCEmojiBean.m
//  HelloEmoji
//
//  Created by wesley chen on 15/4/22.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import "WCEmotionKeyboard-Prefix.h"

@implementation WCEmotionBean

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _code = dict[STR_PROP(code)];
        _type = (WCEmotionBeanType)[dict[STR_PROP(type)] integerValue];
        _group = dict[STR_PROP(group)];
        _chs = dict[STR_PROP(chs)];
        _png = dict[STR_PROP(png)];
        _gif = dict[STR_PROP(gif)];
        _icon = dict[STR_PROP(icon)];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _code = [aDecoder decodeObjectForKey:STR_PROP(code)];
        _type = (WCEmotionBeanType)[[aDecoder decodeObjectForKey:STR_PROP(type)] integerValue];
        _group = [aDecoder decodeObjectForKey:STR_PROP(group)];
        _chs = [aDecoder decodeObjectForKey:STR_PROP(chs)];
        _png = [aDecoder decodeObjectForKey:STR_PROP(png)];
        _gif = [aDecoder decodeObjectForKey:STR_PROP(gif)];
        _icon = [aDecoder decodeObjectForKey:STR_PROP(icon)];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_code forKey:STR_PROP(code)];
    [aCoder encodeObject:[NSNumber numberWithInteger:_type] forKey:STR_PROP(type)];
    [aCoder encodeObject:_group forKey:STR_PROP(group)];
    [aCoder encodeObject:_chs forKey:STR_PROP(chs)];
    [aCoder encodeObject:_png forKey:STR_PROP(png)];
    [aCoder encodeObject:_gif forKey:STR_PROP(gif)];
    [aCoder encodeObject:_icon forKey:STR_PROP(icon)];
}

@end
