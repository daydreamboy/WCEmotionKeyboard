//
//  WCEmojiPage.m
//  HelloEmoji
//
//  Created by wesley chen on 15/4/21.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import "WCEmotionKeyboard-Prefix.h"

@interface WCEmotionPage ()

@property (nonatomic, assign) NSUInteger maxRows;
@property (nonatomic, assign) NSUInteger maxColumns;

@property (nonatomic, strong) UIImageView *magnifier;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign) CGSize keySize;

@property (nonatomic, assign) NSUInteger numberOfEmotion;

@property (nonatomic, strong) NSMutableArray *keyBeans;
@property (nonatomic, strong) NSMutableArray *keys;

@property (nonatomic, assign) NSInteger lastIndex;

@end

@implementation WCEmotionPage

#pragma mark - Public Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = NO;
        
        _keys = [NSMutableArray array];
        
        UIImage *image = [UIImage imageNamed:ImageBundled(@"emotion_magnifier")];
        _magnifier = [[UIImageView alloc] initWithImage:image];
        
        _lastIndex = -1;
    }
    
    return self;
}

- (void)displayIcons:(NSArray *)icons withMaxRows:(NSUInteger)maxRows maxColumns:(NSUInteger)maxColumns {
    _keySize = CGSizeMake(CGRectGetWidth(self.bounds) / maxColumns, CGRectGetHeight(self.bounds) / maxRows);
    _keyBeans = [NSMutableArray arrayWithArray:icons];
    _numberOfEmotion = _keyBeans.count;
    
    _maxRows = maxRows;
    _maxColumns = maxColumns;
    
    NSUInteger numberOfKeys = _keyBeans.count + 1;
    NSUInteger numberOfRows = numberOfKeys / maxColumns + (numberOfKeys % maxColumns ? 1 : 0);
    NSMutableArray *arrM = [NSMutableArray arrayWithArray:_keys];
    
    NSUInteger index = 0;
    for (NSInteger i = 0; i < numberOfRows; i++) {
        
        NSUInteger numberOfColumns = (i == numberOfRows - 1 && numberOfKeys % maxColumns) ? numberOfKeys % maxColumns : maxColumns;
        
        for (NSInteger j = 0; j < numberOfColumns; j++) {
            index = i * maxColumns + j;
            
            CGPoint origin;
            WCEmotionBean *emojiBean;
            
            if (index == numberOfKeys - 1) {
                emojiBean = [[WCEmotionBean alloc] init];
                emojiBean.png = @"emotion_delete";
                emojiBean.type = WCEmotionBeanTypeAccessoryIcon;
                origin = CGPointMake((maxColumns - 1) * _keySize.width, (maxRows - 1) * _keySize.height);
                
                [_keyBeans addObject:emojiBean];
            }
            else {
                emojiBean = icons[index];
                emojiBean.type = WCEmotionBeanTypeApple;
                
                origin = CGPointMake(j * _keySize.width, i * _keySize.height);
            }
            
            CGRect frame = { origin, _keySize };
            
            WCEmotionKey *key;
            if (index < arrM.count) {
                key = arrM[index];
            }
            else {
                key = [[WCEmotionKey alloc] init];
                
                [self addSubview:key];
                [_keys addObject:key];
            }
            
            key.frame = frame;
            [self configureKey:key withBean:emojiBean];
        }
    }
    
    if (index + 1 < _keys.count) {
        for (NSUInteger i = index + 1; i < _keys.count; i++) {
            ((WCEmotionKey *)_keys[i]).hidden = YES;
        }
    }
    
    [self resetMagnifier];
}

#pragma mark - 

- (void)configureKey:(WCEmotionKey *)key withBean:(WCEmotionBean *)emojiBean {

#if DEBUG_UI
    key.layer.borderWidth = 1;
    key.layer.borderColor = [UIColor redColor].CGColor;
#endif
    key.exclusiveTouch = YES;
    key.hidden = NO;
    key.bean = emojiBean;
    
    if (emojiBean.type == WCEmotionBeanTypeAccessoryIcon) {
        [key addTarget:self action:@selector(deleteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [key addTarget:self action:@selector(deleteButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    }
    else {
        [key removeTarget:self action:@selector(deleteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [key removeTarget:self action:@selector(deleteButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    _scrollView = (UIScrollView *)newSuperview;
}

/*!
 *  Index of emoji except delete button
 *
 *  @param point
 *
 *  @return started from 0. If -1, the index is invalid
 */
- (NSInteger)indexFromPoint:(CGPoint)point {
    NSInteger column = ceil(point.x / _keySize.width) - 1;
    NSInteger row = ceil(point.y / _keySize.height) - 1;
    
#if DEBUG_LOG
    NSLog(@"row: %ld, column: %ld", (unsigned long)row, (unsigned long)column);
#endif
    
    NSInteger index = -1;
    if (column >= 0 && column < _maxColumns
        && row >= 0 && row < _maxRows) {
        
        if (row * _maxColumns + column < _numberOfEmotion) {
            index = row * _maxColumns + column;
        }
    }
    
    return index;
}

- (void)resetMagnifier {
    [_magnifier.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_magnifier removeFromSuperview];
    _lastIndex = -1;
}

- (void)addMagnifierAtIndex:(NSInteger)index {
	if (_scrollView.decelerating) {
		return;
	}

	if (index >= 0 && index < _numberOfEmotion) {
		if (index != _lastIndex) {
            
            [self resetMagnifier];
            
			WCEmotionBean *emojiBean = _keyBeans[index];
			WCEmotionKey *key = _keys[index];

			UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:IconBundled(emojiBean.png)]];
			imageView.center = CGPointMake(CGRectGetWidth(_magnifier.frame) / 2.0, CGRectGetWidth(_magnifier.frame) / 2.0);
			[_magnifier addSubview:imageView];

			_magnifier.frame = CGRectMake(key.center.x - CGRectGetWidth(_magnifier.frame) / 2.0, key.center.y - CGRectGetHeight(_magnifier.frame), CGRectGetWidth(_magnifier.frame), CGRectGetHeight(_magnifier.frame));
			[self addSubview:_magnifier];
            [self bringSubviewToFront:_magnifier];

			_lastIndex = index;
		}
	}
}

#pragma mark - Actions

- (void)deleteButtonTouchDown:(WCEmotionKey *)sender {
    if (!_scrollView.decelerating) {
        [[UIDevice currentDevice] playInputClick];
    }
}

- (void)deleteButtonClicked:(WCEmotionKey *)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(keyTapped:)]) {
        [_delegate keyTapped:sender.bean];
    }
    [self resetMagnifier];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    
#if DEBUG_LOG
    NSLog(@"began pt: %@", NSStringFromCGPoint(pt));
#endif
    
    NSInteger index = [self indexFromPoint:pt];
    
    if (!_scrollView.decelerating) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf addMagnifierAtIndex:index];
        });
    }
    
    if (!_scrollView.decelerating && index != -1) {
        [[UIDevice currentDevice] playInputClick];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    
#if DEBUG_LOG
    NSLog(@"moved pt: %@", NSStringFromCGPoint(pt));
#endif
    
    NSInteger index = [self indexFromPoint:pt];
    [self addMagnifierAtIndex:index];
    if (index == -1) {
        [self touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    
#if DEBUG_LOG
    NSLog(@"ended pt: %@", NSStringFromCGPoint(pt));
#endif
    
    NSInteger index = [self indexFromPoint:pt];
    
    if (index >= 0 && index < _numberOfEmotion) {
        
        if (_delegate && [_delegate respondsToSelector:@selector(keyTapped:)]) {
            [_delegate keyTapped:_keyBeans[index]];
        }
    }
    
    __weak typeof (self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf resetMagnifier];
    });
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    
#if DEBUG_LOG
    NSLog(@"cancelled pt: %@", NSStringFromCGPoint(pt));
#endif
    
    [self indexFromPoint:pt];
    [self resetMagnifier];
}

@end
