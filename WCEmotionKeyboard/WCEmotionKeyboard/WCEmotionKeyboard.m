//
//  WCEmojiKeyboard.m
//  HelloEmoji
//
//  Created by wesley chen on 15/4/21.
//  Copyright (c) 2015年 wesley chen. All rights reserved.
//

#import "WCEmotionKeyboard-Prefix.h"

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

+ (id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

- (void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end

@interface WCEmotionKeyboard () <WCEmotionPageDelegate, UIScrollViewDelegate, UIInputViewAudioFeedback>

// Views
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) id<UITextInput> focusedEditableView;

// All data
@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger numberOfIcons;
@property (nonatomic, strong) NSArray *icons;

@property (nonatomic, assign) CGSize keyboardSize;
@property (nonatomic, assign) CGSize sytemKeyboardSize; // include accessoryView
@property (nonatomic, assign) BOOL keyboardSizeChanged;

@property (nonatomic, assign) BOOL pageControlIsChangingPage;

// Size per page
@property (nonatomic, assign) NSUInteger maxIconsPerPage;
@property (nonatomic, assign) NSUInteger maxRowsPerPage;
@property (nonatomic, assign) NSUInteger maxColumnsPerPage;

@property (nonatomic, strong) NSMutableSet *recycledPages;
@property (nonatomic, strong) NSMutableSet *visiblePages;

@end

@implementation WCEmotionKeyboard

static WCEmotionKeyboard *sharedInstance = nil;
static dispatch_once_t onceToken;


#pragma mark - Public Methods

+ (instancetype)sharedInstance {
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WCEmotionKeyboard alloc] init];
    });
    return sharedInstance;
}

+ (void)resetSharedInstance {
    [[NSNotificationCenter defaultCenter] removeObserver:sharedInstance name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:sharedInstance name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:sharedInstance name:UIKeyboardWillChangeFrameNotification object:nil];
    
    sharedInstance = nil;
    onceToken = 0;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        WCEmotionGroupBean *groupBean = [WCEmotionGroupBean beanWithEmotionGroupName:@"emoji_people"];
        _icons = groupBean.emotion_group_icons;
        _numberOfIcons = [_icons count];
        
        _visiblePages = [NSMutableSet set];
        _recycledPages = [NSMutableSet set];
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        CGFloat pageControlHeight = 40;
        
        // If it's iPhone 6+, make keyboard height taller
        _keyboardSize = screenSize.height > 667 ? CGSizeMake(screenSize.width, 226) : CGSizeMake(screenSize.width, 216);
        self.bounds = CGRectMake(0, 0, _keyboardSize.width, _keyboardSize.height);
        // Let super view adjust its size
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.clipsToBounds = NO;
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _keyboardSize.width, _keyboardSize.height - pageControlHeight)];
        scrollView.pagingEnabled = YES;
        scrollView.alwaysBounceHorizontal = YES;
        scrollView.clipsToBounds = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.backgroundColor = UICOLOR_ARGB(0xFFCFD3D8);
#if DEBUG_UI
        scrollView.backgroundColor = [UIColor orangeColor];
#endif
        scrollView.contentSize = CGSizeMake(_keyboardSize.width * _numberOfPages, _keyboardSize.height - pageControlHeight);
        scrollView.delegate = self;
        [self addSubview:scrollView];
        _scrollView = scrollView;
        
        UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(scrollView.frame), _keyboardSize.width, pageControlHeight)];
        pageControl.numberOfPages = _numberOfPages;
        pageControl.currentPage = 0;
        pageControl.backgroundColor = UICOLOR_ARGB(0xFFCFD3D8);
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
            pageControl.pageIndicatorTintColor = UICOLOR_ARGB(0xFFA5A9AD);
            pageControl.currentPageIndicatorTintColor = UICOLOR_ARGB(0xFF67686B);
        }
        [pageControl addTarget:self action:@selector(pageControlTapped:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:pageControl];
        _pageControl = pageControl;
        
        // Register notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    
    return self;
}

#pragma mark -

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self retrieveFocusedEditableView];
    [self configureKeyboard];
    [self scrollToPage:[self currentPageOfScrollView:_scrollView] animated:NO];
}

- (void)retrieveFocusedEditableView {
    UIResponder *currentResponder = [UIResponder currentFirstResponder];
#if DEBUG_LOG
    NSLog(@"%@", currentResponder);
#endif

    if ([currentResponder isKindOfClass:[UITextView class]] ||
        [currentResponder isKindOfClass:[UITextField class]]) {
        _focusedEditableView = (id<UITextInput>)currentResponder;
    }
}

- (void)configureKeyboard {
    
    _keyboardSize = self.bounds.size;
    BOOL isPortrait = [self isPortrait];
    
#if DEBUG_LOG
    NSLog(@"size: %@", NSStringFromCGSize(_keyboardSize));
    NSLog(@"isPortrait: %@", isPortrait ? @"YES" : @"NO");
#endif
    
    _maxRowsPerPage = isPortrait ? 3 : 2;
    _maxColumnsPerPage = isPortrait ? 7 : 11;
    _maxIconsPerPage = _maxRowsPerPage * _maxColumnsPerPage - 1;
    _numberOfPages = _numberOfIcons / _maxIconsPerPage + (_numberOfIcons % _maxIconsPerPage ? 1 : 0);
    
    CGFloat pageControlHeight = isPortrait ? 40 : 30;
    _scrollView.frame = CGRectMake(0, 0, _keyboardSize.width, _keyboardSize.height - pageControlHeight);
    _scrollView.contentSize = CGSizeMake(_keyboardSize.width * _numberOfPages, _keyboardSize.height - pageControlHeight);
    
    _pageControl.frame = CGRectMake(0, CGRectGetMaxY(_scrollView.frame), _keyboardSize.width, pageControlHeight);
    _pageControl.numberOfPages = _numberOfPages;
    _pageControl.currentPage = [self currentPageOfScrollView:_scrollView];
}

- (void)scrollToPage:(NSUInteger)page animated:(BOOL)animated {
    
    NSAssert(page >= 0 && page < _numberOfPages, @"page %lu out of bounds[0...%lu]", (unsigned long)page, (unsigned long)_numberOfPages);
    
    CGPoint pt = CGPointMake(page * CGRectGetWidth(_scrollView.bounds), 0);
    [_scrollView setContentOffset:pt animated:animated];
    [self tilePages];
}

- (NSUInteger)currentPageOfScrollView:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    page = MAX(page, 0);
    page = MIN(page, _numberOfPages - 1);
    
    return page;
}

- (void)tilePages {
    CGRect visibleBounds = _scrollView.bounds;
    
    NSInteger firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    NSInteger lastNeededPageIndex = floorf((CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds));
    
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, _numberOfPages - 1);
    
    for (WCEmotionPage *page in self.visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            [self.recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [self.visiblePages minusSet:self.recycledPages];
    
    for (NSUInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            WCEmotionPage *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[WCEmotionPage alloc] init];
            }
#if DEBUG_LOG
            NSLog(@"configurePage");
#endif
            [self configurePage:page forIndex:index];
            [self.scrollView addSubview:page];
            [self.visiblePages addObject:page];
        }
        else {
            WCEmotionPage *page = [self displayingPageForIndex:index];
            // Reconfigure page when portrait/lanscape or keyboard size changed
            if (page.portrait != [self isPortrait] || _keyboardSizeChanged) {
#if DEBUG_LOG
                NSLog(@"configurePage2");
#endif
                [self configurePage:page forIndex:index];
            }
        }
    }
    
    // Reset _keyboardSizeChanged after keyboardWillChangeFrame: triggered
    // Don't reset it on UIKeyboardDidChangeFrameNotification
    _keyboardSizeChanged = NO;
}

- (void)configurePage:(WCEmotionPage *)page forIndex:(NSUInteger)index {
    
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    page.delegate = self;
    page.portrait = [self isPortrait];
#if DEBUG_UI
    page.backgroundColor = [UIColor greenColor];
#endif
    
    [page displayIcons:[self iconsOfPageAtIndex:index] withMaxRows:_maxRowsPerPage maxColumns:_maxColumnsPerPage];
}

- (NSArray *)iconsOfPageAtIndex:(NSUInteger)index {
    
    NSUInteger startIndex = index * _maxIconsPerPage;
    NSUInteger count = MIN(_numberOfIcons - startIndex, _maxIconsPerPage);
    NSArray *iconsOfPage = [_icons subarrayWithRange:NSMakeRange(startIndex, count)];
    
    return iconsOfPage;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect pagingScrollViewFrame = _scrollView.frame;
    CGFloat marigin = 10;
    
    CGRect pageFrame = pagingScrollViewFrame;
    pageFrame.size.width -= (2 * marigin);
    pageFrame.size.height -= (2 * marigin);
    pageFrame.origin.x = (pagingScrollViewFrame.size.width * index) + marigin;
    pageFrame.origin.y = marigin;
    
    return pageFrame;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    BOOL foundPage = NO;
    for (WCEmotionPage *page in self.visiblePages) {
        if (page.index == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (WCEmotionPage *)displayingPageForIndex:(NSUInteger)index {
    for (WCEmotionPage *page in self.visiblePages) {
        if (page.index == index) {
            return page;
        }
    }
    return nil;
}

- (WCEmotionPage *)dequeueRecycledPage {
    WCEmotionPage *page = [self.recycledPages anyObject];
    if (page) {
        [self.recycledPages removeObject:page];
    }
    return page;
}

- (void)didMoveToSuperview {
    [self.superview bringSubviewToFront:self];
}

#pragma mark - Helper

- (BOOL)isPortrait {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown);
}

/*!
 *  Get NSRange from UITextField
 *
 *  @param textField
 *
 *  @sa http://stackoverflow.com/questions/21149767/convert-selectedtextrange-uitextrange-to-nsrange
 */
- (NSRange)selectedRange:(id<UITextInput>)editableView {
    UITextPosition *beginning = editableView.beginningOfDocument;
    
    UITextRange *selectedRange = editableView.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    
    NSInteger location = [editableView offsetFromPosition:beginning toPosition:selectionStart];
    NSInteger length = [editableView offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (NSRange)selectedRangeForDeletebackward:(id<UITextInput>)editableView {
    
    UITextRange *selectedRange = editableView.selectedTextRange;
    
    if (selectedRange.empty) {
        // Delete backward
        return [self rangeOfLastOneComposedCharacterSequence:editableView];
    }
    else {
        // Delete selection
        return [self selectedRange:editableView];
    }
}

/*!
 *  Get correct range of last one 'character', such as normal character with length of 1 and emojis with length of 2 or 4
 *
 *  @param editableView UITextField or UITextView
 *
 *  @warning If the editableView param is not a UITextField or UITextView object will raise an exception
 */
- (NSRange)rangeOfLastOneComposedCharacterSequence:(id<UITextInput>)editableView {
	NSString *text;
	if ([editableView isKindOfClass:[UITextField class]]) {
		text = ((UITextField *)editableView).text;
	}
	else if ([editableView isKindOfClass:[UITextView class]]) {
		text = ((UITextView *)editableView).text;
	}
	else {
		NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
		                                                 reason:[NSString stringWithFormat:@"Unsupported object %@", editableView]
		                                               userInfo:nil];
		[exception raise];
	}

	if (text.length < 1) {
		// Empty text for delete backward
		return NSMakeRange(0, 0);
	}
	else if (text.length < 2) {
		// Only one character in text for delete backward
		return NSMakeRange(0, 1);
	}
	else {
		// Two or more than two characters in text for delete backward

		id <UITextInputTokenizer> tokenizer = [editableView tokenizer];

		UITextPosition *pos1 = editableView.selectedTextRange.end;
		UITextPosition *pos2 = [editableView positionFromPosition:pos1 offset:-2]; // Shift 2 utf8 units

		UITextRange *range1 = [tokenizer rangeEnclosingPosition:pos1 withGranularity:UITextGranularityCharacter inDirection:UITextStorageDirectionBackward];
		UITextRange *range2 = [tokenizer rangeEnclosingPosition:pos2 withGranularity:UITextGranularityCharacter inDirection:UITextStorageDirectionBackward];

		NSString *twoUTF8Units1 = [editableView textInRange:range1];
		NSString *twoUTF8Units2 = [editableView textInRange:range2];
#if DEBUG_LOG
		NSLog(@"%@", twoUTF8Units1);
		NSLog(@"%@", twoUTF8Units2);
#endif
		BOOL bool1 = [self isRegionalIndicatorSymbol:twoUTF8Units1];
		BOOL bool2 = [self isRegionalIndicatorSymbol:twoUTF8Units2];

		NSInteger loc, len;
		if (bool1 && bool2) {
			// It's flag emojis, delete twoUTF8Units1 and twoUTF8Units2

            loc = text.length - (twoUTF8Units1.length + twoUTF8Units2.length);
            len = twoUTF8Units1.length + twoUTF8Units2.length;
		}
		else {
            // delete twoUTF8Units1
            loc = text.length - twoUTF8Units1.length;
            len = twoUTF8Units1.length;
		}
#if DEBUG_LOG
        NSLog(@"loc: %ld, len: %ld", (long)loc, (long)len);
#endif
		return NSMakeRange(loc, len);
	}
}

#define REGIONAL_INDICATOR_SYMBOLS_A    0x1F1E6
#define REGIONAL_INDICATOR_SYMBOLS_Z    0x1F1FF

- (BOOL)isRegionalIndicatorSymbol:(NSString *)unicodeCharacters {
    
    if (unicodeCharacters.length < 2) {
        // one unicode character or empty
        return NO;
    }
    else {
        // composed unicode characters
        NSData *data = [unicodeCharacters dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
        
        // a normal emoji or a regional indicator symbol with length of 2
        // but emoji flags has two regional indicator symbol, e.g. 🇦🇺 == 🇦+ 🇺
        const int size = 1;
        uint32_t utf8[size];
        
        [data getBytes:&utf8 length:sizeof(uint32_t) * size];
        
        NSLog(@"0x%x", utf8[0]);
        
        if (utf8[0] >= REGIONAL_INDICATOR_SYMBOLS_A && utf8[0] <= REGIONAL_INDICATOR_SYMBOLS_Z) {
            return YES;
        }
        else {
            return NO;
        }
    }
}

#pragma mark - WCEmotionPageDelegate

- (void)keyTapped:(id)keyData {
	WCEmotionBean *bean = (WCEmotionBean *)keyData;
#if DEBUG_LOG
	NSLog(@"%@", bean.icon);
#endif

	if (bean.type == WCEmotionBeanTypeAccessoryIcon) {
		// Delete
		if ([_focusedEditableView hasText]) {
			if ([_focusedEditableView isKindOfClass:[UITextView class]]) {
				UITextView *textView = (UITextView *)_focusedEditableView;

				if (![textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)] ||
                    // Bug: pass wrong range when delete backward but delete selection is OK
                    [textView.delegate textView:textView shouldChangeTextInRange:[self selectedRangeForDeletebackward:textView] replacementText:@""]) {
					
                    [textView deleteBackward];

					if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
						if ([textView.delegate respondsToSelector:@selector(textViewDidChange:)]) {
							[textView.delegate textViewDidChange:textView];
						}
					}
				}
			}
            else if ([_focusedEditableView isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField *)_focusedEditableView;
                
                if (![textField.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)] ||
                    // Bug: pass wrong range when delete backward but delete selection is OK
                    [textField.delegate textField:textField shouldChangeCharactersInRange:[self selectedRangeForDeletebackward:textField] replacementString:@""]) {
                    
                    [textField deleteBackward];
                }
            }
		}
	}
	else {
		// Insert
		if ([_focusedEditableView isKindOfClass:[UITextView class]]) {
			
            UITextView *textView = (UITextView *)_focusedEditableView;
            
			if (![textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)] ||
                [textView.delegate textView:textView shouldChangeTextInRange:textView.selectedRange replacementText:bean.icon]) {
                
				[textView insertText:bean.icon];

				if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
					if ([textView.delegate respondsToSelector:@selector(textViewDidChange:)]) {
						[textView.delegate textViewDidChange:textView];
					}
				}
			}
		}
        else if ([_focusedEditableView isKindOfClass:[UITextField class]]) {
            
            UITextField *textField = (UITextField *)_focusedEditableView;
            
            if (![textField.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)] ||
                [textField.delegate textField:textField shouldChangeCharactersInRange:[self selectedRange:textField] replacementString:bean.icon]) {
                
                [textField insertText:bean.icon];
            }
        }
	}
}

#pragma mark - Actions

- (void)pageControlTapped:(UIPageControl *)sender {
    NSInteger page = sender.currentPage;
    
    // Update the scroll view to the appropriate page
    CGRect frame = _scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [_scrollView scrollRectToVisible:frame animated:YES];
    
    _pageControlIsChangingPage = YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    [self tilePages];
    
    if (_pageControlIsChangingPage) {
        return;
    }
    
    _pageControl.currentPage = [self currentPageOfScrollView:_scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _pageControlIsChangingPage = NO;
}

#pragma mark - NSNotification

- (void)textViewDidBeginEditing:(NSNotification *)notification {
    id obj = [notification object];
    
    if ([obj isKindOfClass:[UITextView class]]) {
        _focusedEditableView = (id<UITextInput>)obj;
    }
}

- (void)textFieldDidBeginEditing:(NSNotification *)notification {
    id obj = [notification object];
    
    if ([obj isKindOfClass:[UITextField class]]) {
        _focusedEditableView = (id<UITextInput>)obj;
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    
    // Re-layoutSubviews when keyboard size changed even though WCEmotionKeyboard because multi-UITextField/UITextView switched
    CGSize keyboardSize = [[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    if (!CGSizeEqualToSize(_sytemKeyboardSize, keyboardSize)) {
        
        // Just mark _keyboardSizeChanged YES which is used in layoutSubviews
        _keyboardSizeChanged = YES;
        _sytemKeyboardSize = keyboardSize;
        
        // setNeedsLayout not work here
        //[self setNeedsLayout];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            [self setNeedsLayout];
        }
    }
}

#pragma mark - UIInputViewAudioFeedback

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

@end
