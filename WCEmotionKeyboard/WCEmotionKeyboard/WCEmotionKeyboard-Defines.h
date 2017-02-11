//
//  WCEmotionKeyboard-Defines.h
//  WCEmotionKeyboard
//
//  Created by wesley chen on 15/5/7.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#ifndef WCEmotionKeyboard_WCEmotionKeyboard_Defines_h
#define WCEmotionKeyboard_WCEmotionKeyboard_Defines_h

#define DEBUG_LOG 0
#define DEBUG_UI 0

#ifndef STR_PROP
#define STR_PROP(property) NSStringFromSelector(@selector(property))
#endif

#ifndef SYSTEM_VERSION_LESS_THAN
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#endif

#ifndef UICOLOR_ARGB
#define UICOLOR_ARGB(color) [UIColor colorWithRed : (((color) >> 16) & 0xFF) / 255.0 green : (((color) >> 8) & 0xFF) / 255.0 blue : ((color) & 0xFF) / 255.0 alpha : (((color) >> 24) & 0xFF) / 255.0]
#endif

#define EmotionBundleName @"EmotionIcons.bundle"
#define ImageBundled(imageName) [NSString stringWithFormat:@"%@/%@", EmotionBundleName, imageName]
#define IconBundled(iconName) [NSString stringWithFormat:@"%@/%@/%@", EmotionBundleName, @"emoji", iconName]

#endif
