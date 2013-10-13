//
//  TITokenField.m
//  TITokenField
//
//  Created by Tom Irving on 16/02/2010.
//  Copyright 2012 Tom Irving. All rights reserved.
//

#import "TITokenField.h"
#import <QuartzCore/QuartzCore.h>

NSString * const kTextEmpty = @"\u200B"; // Zero-Width Space
NSString * const kTextHidden = @"\u200D"; // Zero-Width Joiner

//==========================================================
#pragma mark - TITokenFieldView -
//==========================================================

@interface TITokenFieldView (Private)
- (void)setup;
- (NSString *)displayStringForRepresentedObject:(id)object;
@end

@implementation TITokenFieldView {
  CGFloat _maxHeight;
}

@dynamic delegate;
@synthesize showAlreadyTokenized = _showAlreadyTokenized;
@synthesize tokenField = _tokenField;
@synthesize separator = _separator;

#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])){
		[self setup];
	}
	
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self setup];
	}
	
	return self;
}

- (void)setup {
  _maxHeight = CGFLOAT_MAX;
  
  self.delegate = self;
  
	[self setBackgroundColor:[UIColor clearColor]];
	[self setDelaysContentTouches:YES];
	[self setMultipleTouchEnabled:NO];
	
	_showAlreadyTokenized = NO;
	
	_tokenField = [[TITokenField alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 42)];
	[_tokenField addTarget:self action:@selector(tokenFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
	[_tokenField addTarget:self action:@selector(tokenFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
	[_tokenField addTarget:self action:@selector(tokenFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
	[_tokenField addTarget:self action:@selector(tokenFieldFrameWillChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
	[_tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
	[_tokenField setDelegate:self];
	[self addSubview:_tokenField];
	
	CGFloat tokenFieldBottom = CGRectGetMaxY(_tokenField.frame);
	
	_separator = [[UIView alloc] initWithFrame:CGRectMake(0, tokenFieldBottom-1, self.bounds.size.width, 1)];
	[_separator setBackgroundColor:[UIColor colorWithWhite:0.7 alpha:1]];
	[self addSubview:_separator];
  
	[self bringSubviewToFront:_tokenField];
	[self bringSubviewToFront:_separator];
}

#pragma mark mrvincenzo additions

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat originY = self.contentOffset.y + self.frame.size.height-1;
  [_separator setFrame:((CGRect){{_separator.frame.origin.x, originY}, _separator.frame.size})];
}

// separator should be of 1 point height
- (void)setupSeparator:(UIView*)separator {
  [separator removeFromSuperview];
  _separator = separator;
	[self addSubview:_separator];
  
  [self updateSeparatorFrameOriginY];
}

- (void)setMaxNumberOfLines:(int)maxNumberOfLines {
  _maxHeight = [_tokenField getHeightWithNumberOfLines:maxNumberOfLines];
  [self setFrame:((CGRect){self.frame.origin, {self.frame.size.width, _maxHeight}})];
}

- (void)updateSeparatorFrameOriginY {
  CGFloat tokenFieldBottom = CGRectGetMaxY(_tokenField.frame)-1;
    
  [_separator setFrame:((CGRect){{_separator.frame.origin.x, tokenFieldBottom}, _separator.frame.size})];
  
	[self bringSubviewToFront:_separator];
}

#pragma mark Property Overrides

- (void)setFrame:(CGRect)frame {
  [super setFrame:((CGRect){frame.origin, {frame.size.width, MIN(frame.size.height, _maxHeight)}})];
	
	CGFloat width = frame.size.width;
	[_separator setFrame:((CGRect){_separator.frame.origin, {width, _separator.bounds.size.height}})];
	[_tokenField setFrame:((CGRect){_tokenField.frame.origin, {width, _tokenField.bounds.size.height}})];
    
	[self setNeedsLayout];
}

- (void)setContentOffset:(CGPoint)offset {
	[super setContentOffset:offset];
	[self setNeedsLayout];
}

- (NSArray *)tokenTitles {
	return _tokenField.tokenTitles;
}

#pragma mark Event Handling

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)becomeFirstResponder {
	return [_tokenField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [_tokenField resignFirstResponder];
}

#pragma mark TextField Methods

- (void)tokenFieldDidBeginEditing:(TITokenField *)field {
    [_tokenField setResultsModeEnabled:NO forcibly:YES animated:YES];
}

- (void)tokenFieldDidEndEditing:(TITokenField *)field {
    [_tokenField setResultsModeEnabled:NO forcibly:YES animated:YES];
}

- (void)tokenFieldTextDidChange:(TITokenField *)field {
    if ([_tokenField.text isEqualToString:kTextEmpty]) {
        [_tokenField setResultsModeEnabled:NO];
    } else {
        [_tokenField setResultsModeEnabled:YES];
    }
}

- (void)tokenFieldFrameWillChange:(TITokenField *)field {
    [self updateSeparatorFrameOriginY];
}

- (void)tokenFieldFrameDidChange:(TITokenField *)field {
//  [self setFrame:((CGRect){self.frame.origin, {_separator.frame.size.width, MIN(field.frame.size.height, _maxHeight)}})];
}

#pragma mark Results Methods
- (NSString *)displayStringForRepresentedObject:(id)object {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:displayStringForRepresentedObject:)]){
		return [_tokenField.delegate tokenField:_tokenField displayStringForRepresentedObject:object];
	}
	
	if ([object isKindOfClass:[NSString class]]){
		return (NSString *)object;
	}
	
	return [NSString stringWithFormat:@"%@", object];
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TITokenFieldView %p; Token count = %d>", self, self.tokenTitles.count];
}

- (void)dealloc {
	[self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenField -
//==========================================================
@interface TITokenFieldInternalDelegate ()
@property (nonatomic, weak) id <UITextFieldDelegate> delegate;
@property (nonatomic, weak) TITokenField * tokenField;
@end

@interface TITokenField ()
@property (nonatomic, readonly) CGFloat leftViewWidth;
@property (nonatomic, readonly) CGFloat rightViewWidth;
@property (weak, nonatomic, readonly) UIScrollView * scrollView;
@end

@interface TITokenField (Private)
- (void)setup;
- (CGFloat)layoutTokensInternal;
@end

@implementation TITokenField {
	id __weak delegate;
	TITokenFieldInternalDelegate * _internalDelegate;
	NSMutableArray * _tokens;
	CGPoint _tokenCaret;
    UILabel * _placeHolderLabel;
}
@synthesize delegate = delegate;
@synthesize editable = _editable;
@synthesize removesTokensOnEndEditing = _removesTokensOnEndEditing;
@synthesize numberOfLines = _numberOfLines;
@synthesize selectedToken = _selectedToken;
@synthesize tokenizingCharacters = _tokenizingCharacters;

#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])){
		[self setup];
    }
	
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self setup];
	}
	
	return self;
}

- (void)setup {
	
	[self setBorderStyle:UITextBorderStyleNone];
	[self setFont:[UIFont systemFontOfSize:14]];
	[self setBackgroundColor:[UIColor whiteColor]];
	[self setAutocorrectionType:UITextAutocorrectionTypeNo];
	[self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[self setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
	
	[self addTarget:self action:@selector(didBeginEditing) forControlEvents:UIControlEventEditingDidBegin];
	[self addTarget:self action:@selector(didEndEditing) forControlEvents:UIControlEventEditingDidEnd];
	[self addTarget:self action:@selector(didChangeText) forControlEvents:UIControlEventEditingChanged];
	
	[self.layer setShadowColor:[[UIColor blackColor] CGColor]];
	[self.layer setShadowOpacity:0.6];
	[self.layer setShadowRadius:12];
	
	[self setPromptText:@"To:"];
	[self setText:kTextEmpty];
	
	_internalDelegate = [[TITokenFieldInternalDelegate alloc] init];
	[_internalDelegate setTokenField:self];
	[super setDelegate:_internalDelegate];
	
	_tokens = [NSMutableArray array];
	_editable = YES;
	_removesTokensOnEndEditing = YES;
	_tokenizingCharacters = [NSCharacterSet characterSetWithCharactersInString:@","];
}

#pragma mark Property Overrides
- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self.layer setShadowPath:[[UIBezierPath bezierPathWithRect:self.bounds] CGPath]];
	[self layoutTokensAnimated:NO];
}

- (void)setText:(NSString *)text {
	[super setText:(text.length == 0 ? kTextEmpty : text)];
}

- (void)setFont:(UIFont *)font {
	[super setFont:font];
	
	if ([self.leftView isKindOfClass:[UILabel class]]){
		[self setPromptText:((UILabel *)self.leftView).text];
	}
}

- (void)setDelegate:(id<TITokenFieldDelegate>)del {
	delegate = del;
	[_internalDelegate setDelegate:delegate];
}

- (NSArray *)tokens {
	return [_tokens copy];
}

- (NSArray *)tokenTitles {
	
	NSMutableArray * titles = [NSMutableArray array];
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		if (token.title) [titles addObject:token.title];
	}];
	return titles;
}

- (NSArray *)tokenObjects {
	
	NSMutableArray * objects = [NSMutableArray array];
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		if (token.representedObject) [objects addObject:token.representedObject];
		else if (token.title) [objects addObject:token.title];
	}];
	return objects;
}

- (UIScrollView *)scrollView {
	return ([self.superview isKindOfClass:[UIScrollView class]] ? (UIScrollView *)self.superview : nil);
}

#pragma mark Event Handling
- (BOOL)becomeFirstResponder {
	return (_editable ? [super becomeFirstResponder] : NO);
}

- (void)didBeginEditing {
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[self addToken:token];}];
}

- (void)didEndEditing {
	
	[_selectedToken setSelected:NO];
	_selectedToken = nil;
	
	[self tokenizeText];
	
	if (_removesTokensOnEndEditing){
		
		[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[token removeFromSuperview];}];
		
		NSString * untokenized = kTextEmpty;
		if (_tokens.count){
			
			NSArray * titles = self.tokenTitles;
			untokenized = [titles componentsJoinedByString:@", "];
			
			CGSize untokSize = [untokenized sizeWithFont:[UIFont systemFontOfSize:14]];
			CGFloat availableWidth = self.bounds.size.width - self.leftView.bounds.size.width - self.rightView.bounds.size.width;
			
			if (_tokens.count > 1 && untokSize.width > availableWidth){
				untokenized = [NSString stringWithFormat:@"%d recipients", titles.count];
			}
			
		}
		
		[self setText:untokenized];
	}
	
	[self setResultsModeEnabled:NO];
}

- (void)didChangeText {
	if (!self.text.length) {
    [self setText:kTextEmpty];
  }
  
  [self showOrHidePlaceHolderLabel];
  
  if ([self.delegate respondsToSelector:@selector(tokenField:didChangeText:)]){
    [delegate tokenField:self didChangeText:self.text];
  }
}

- (void) showOrHidePlaceHolderLabel {
  if (([self.text isEqualToString:kTextEmpty]) && ([_tokens count] == 0)) {
    [_placeHolderLabel setHidden:NO];
  } else {
    [_placeHolderLabel setHidden:YES];
  }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	
	// Stop the cut, copy, select and selectAll appearing when the field is 'empty'.
	if (action == @selector(cut:) || action == @selector(copy:) || action == @selector(select:) || action == @selector(selectAll:))
		return ![self.text isEqualToString:kTextEmpty];
	
	return [super canPerformAction:action withSender:sender];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	
	if (_selectedToken && touch.view == self) [self deselectSelectedToken];
	return [super beginTrackingWithTouch:touch withEvent:event];
}

#pragma mark Token Handling
- (TIToken *)addTokenWithTitle:(NSString *)title {
	return [self addTokenWithTitle:title representedObject:nil];
}

- (TIToken *)addTokenWithTitle:(NSString *)title representedObject:(id)object {
	
	if (title.length){
		TIToken * token = [[TIToken alloc] initWithTitle:title representedObject:object font:self.font];
		[self addToken:token];
		return token;
	}
	
	return nil;
}

- (void)addToken:(TIToken *)token {
	
	BOOL shouldAdd = YES;
	if ([delegate respondsToSelector:@selector(tokenField:willAddToken:)]){
		shouldAdd = [delegate tokenField:self willAddToken:token];
	}
	
	if (shouldAdd){
		
		[self becomeFirstResponder];
		
		[token addTarget:self action:@selector(tokenTouchDown:) forControlEvents:UIControlEventTouchDown];
		[token addTarget:self action:@selector(tokenTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:token];
		
		if (![_tokens containsObject:token]) {
			[_tokens addObject:token];
            
			if ([delegate respondsToSelector:@selector(tokenField:didAddToken:)]){
				[delegate tokenField:self didAddToken:token];
			}
            
      [self showOrHidePlaceHolderLabel];
		}
		
		[self setResultsModeEnabled:NO forcibly:YES animated:YES];
		[self deselectSelectedToken];
	}
}

- (void)removeToken:(TIToken *)token {
	
	if (token == _selectedToken) [self deselectSelectedToken];
	
	BOOL shouldRemove = YES;
	if ([delegate respondsToSelector:@selector(tokenField:willRemoveToken:)]){
		shouldRemove = [delegate tokenField:self willRemoveToken:token];
	}
	
	if (shouldRemove){
		
		[token removeFromSuperview];
		[_tokens removeObject:token];
		
		if ([delegate respondsToSelector:@selector(tokenField:didRemoveToken:)]){
			[delegate tokenField:self didRemoveToken:token];
		}
        
    [self showOrHidePlaceHolderLabel];
    [self setResultsModeEnabled:NO forcibly:YES animated:YES];
  }
}

- (void)removeAllTokens {
	
	[_tokens enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop) {
		[self removeToken:token];
	}];
	
    [self setText:@""];
}

- (void)selectToken:(TIToken *)token {
	
	[self deselectSelectedToken];
	
	_selectedToken = token;
	[_selectedToken setSelected:YES];
	
	[self becomeFirstResponder];
	[self setText:kTextHidden];
}

- (void)deselectSelectedToken {
	
	[_selectedToken setSelected:NO];
	_selectedToken = nil;
	
	[self setText:kTextEmpty];
}

- (void)tokenizeText {
	
	__block BOOL textChanged = NO;
	
	if (![self.text isEqualToString:kTextEmpty] && ![self.text isEqualToString:kTextHidden]){
		[[self.text componentsSeparatedByCharactersInSet:_tokenizingCharacters] enumerateObjectsUsingBlock:^(NSString * component, NSUInteger idx, BOOL *stop){
			[self addTokenWithTitle:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			textChanged = YES;
		}];
	}
	
	if (textChanged) [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)tokenTouchDown:(TIToken *)token {
	
	if (_selectedToken != token){
		[_selectedToken setSelected:NO];
		_selectedToken = nil;
	}
}

- (void)tokenTouchUpInside:(TIToken *)token {
	if (_editable) [self selectToken:token];
}

- (CGFloat)layoutTokensInternal {
	
	CGFloat topMargin = floor(self.font.lineHeight * 4 / 7);
	CGFloat leftMargin = self.leftViewWidth + 12;
	CGFloat hPadding = 8;
	CGFloat rightMargin = self.rightViewWidth + hPadding;
	CGFloat lineHeight = self.font.lineHeight + topMargin + 5;
	
	_numberOfLines = 1;
	_tokenCaret = (CGPoint){leftMargin, (topMargin - 1)};
	
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		
		[token setFont:self.font];
		[token setMaxWidth:(self.bounds.size.width - rightMargin - (_numberOfLines > 1 ? hPadding : leftMargin))];
		
		if (token.superview){
			
			if (_tokenCaret.x + token.bounds.size.width + rightMargin > self.bounds.size.width){
				_numberOfLines++;
				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
				_tokenCaret.y += lineHeight;
			}
			
			[token setFrame:(CGRect){_tokenCaret, token.bounds.size}];
			_tokenCaret.x += token.bounds.size.width + 4;
			
			if (self.bounds.size.width - _tokenCaret.x - rightMargin < 50){
				_numberOfLines++;
				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
				_tokenCaret.y += lineHeight;
			}
		}
	}];
	
	return _tokenCaret.y + lineHeight;
}

#pragma mark View Handlers
- (CGFloat)layoutTokensAnimated:(BOOL)animated {
	
	CGFloat newHeight = [self layoutTokensInternal];
	if (self.bounds.size.height != newHeight){
		
		// Animating this seems to invoke the triple-tap-delete-key-loop-problem-thing™
		[UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
			[self setFrame:((CGRect){self.frame.origin, {self.bounds.size.width, newHeight}})];
			[self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
			
		} completion:^(BOOL complete){
			if (complete) [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
		}];
	}
    
    return newHeight;
}

- (void)setResultsModeEnabled:(BOOL)flag {
	[self setResultsModeEnabled:flag forcibly:NO animated:YES];
}

- (void)setResultsModeEnabled:(BOOL)flag forcibly:(BOOL)forcibly animated:(BOOL)animated {
	CGFloat contentHeight = [self layoutTokensAnimated:animated];
  
	if ((forcibly) || _resultsModeEnabled != flag){
		
		//Hide / show the shadow
		[self.layer setMasksToBounds:!flag];
		
		UIScrollView * scrollView = self.scrollView;
    
    [scrollView setScrollsToTop:!flag];
		[scrollView setScrollEnabled:!flag];
		
    // mrvincenzo: setting the content size and content offset correctly
    CGSize contentSize = scrollView.contentSize;
    CGFloat contentOffset;
    if (flag) {
      contentOffset = MAX((CGFloat)0, _tokenCaret.y - (CGFloat)floor(self.font.lineHeight * 4 / 7) + 1);
      contentSize.height = contentOffset+scrollView.frame.size.height;
      
    } else {
      contentOffset = MAX(0, contentHeight - scrollView.frame.size.height);
      contentSize.height = contentHeight;
    }
    
    [UIView animateWithDuration:animated?0.3:0 animations:^{
      scrollView.contentSize = contentSize;
      scrollView.contentOffset = CGPointMake(0, contentOffset);
      [(TITokenFieldView*)scrollView updateSeparatorFrameOriginY];
    }];
	}
  
	_resultsModeEnabled = flag;
}

#pragma mark mrvincenzo additions

- (CGFloat)getHeightWithNumberOfLines:(int)numberOfLines {
    // Adapted from Joe Hewitt's Three20 layout method.
	CGFloat topMargin = (CGFloat)floor(self.font.lineHeight * 4 / 7);
	CGFloat linePadding = topMargin + 5;
    CGFloat height = topMargin - 1;
    height += numberOfLines * (self.font.lineHeight + linePadding);
    return height;
}

#pragma mark Left / Right view stuff
- (void)setPromptText:(NSString *)text {
	
	if (text){
		
		UILabel * label = (UILabel *)self.leftView;
		if (!label || ![label isKindOfClass:[UILabel class]]){
			label = [[UILabel alloc] initWithFrame:CGRectZero];
			[label setTextColor:[UIColor colorWithWhite:0.5 alpha:1]];
			[self setLeftView:label];
            
			[self setLeftViewMode:UITextFieldViewModeAlways];
		}
		
		[label setText:text];
		[label setFont:[UIFont systemFontOfSize:(self.font.pointSize + 1)]];
		[label sizeToFit];
	}
	else
	{
		[self setLeftView:nil];
	}
	
	[self layoutTokensAnimated:YES];
}

- (void)setPlaceholder:(NSString *)placeholder {
	
	if (placeholder){
        
        UILabel * label =  _placeHolderLabel;
		if (!label || ![label isKindOfClass:[UILabel class]]){
			label = [[UILabel alloc] initWithFrame:CGRectMake(_tokenCaret.x + 3, _tokenCaret.y + 2, self.rightView.bounds.size.width, self.rightView.bounds.size.height)];
			[label setTextColor:[UIColor colorWithWhite:0.75 alpha:1]];
            _placeHolderLabel = label;
            [self addSubview: _placeHolderLabel];
		}
		
		[label setText:placeholder];
		[label setFont:[UIFont systemFontOfSize:(self.font.pointSize + 1)]];
		[label sizeToFit];
	}
	else
	{
		[_placeHolderLabel removeFromSuperview];
		_placeHolderLabel = nil;
	}
    
    [self layoutTokensAnimated:YES];
}

#pragma mark Layout
- (CGRect)textRectForBounds:(CGRect)bounds {
	
	if ([self.text isEqualToString:kTextHidden]) return CGRectMake(0, -20, 0, 0);
	
	CGRect frame = CGRectOffset(bounds, _tokenCaret.x + 2, _tokenCaret.y + 3);
	frame.size.width -= (_tokenCaret.x + self.rightViewWidth + 10);
	
	return frame;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
	return ((CGRect){{8, ceilf(self.font.lineHeight * 4 / 7)}, self.leftView.bounds.size});
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
	return ((CGRect){{bounds.size.width - self.rightView.bounds.size.width - 6,
		bounds.size.height - self.rightView.bounds.size.height - 6}, self.rightView.bounds.size});
}

- (CGFloat)leftViewWidth {
	
	if (self.leftViewMode == UITextFieldViewModeNever ||
		(self.leftViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
		(self.leftViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
	
	return self.leftView.bounds.size.width;
}

- (CGFloat)rightViewWidth {
	
	if (self.rightViewMode == UITextFieldViewModeNever ||
		(self.rightViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
		(self.rightViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
	
	return self.rightView.bounds.size.width;
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TITokenField %p; prompt = \"%@\">", self, ((UILabel *)self.leftView).text];
}

- (void)dealloc {
	[self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenFieldInternalDelegate -
//==========================================================
@implementation TITokenFieldInternalDelegate
@synthesize delegate = _delegate;
@synthesize tokenField = _tokenField;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]){
		return [_delegate textFieldShouldBeginEditing:textField];
	}
	
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]){
		[_delegate textFieldDidBeginEditing:textField];
	}
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]){
		return [_delegate textFieldShouldEndEditing:textField];
	}
	
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldDidEndEditing:)]){
		[_delegate textFieldDidEndEditing:textField];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if (_tokenField.tokens.count && [string isEqualToString:@""] && [_tokenField.text isEqualToString:kTextEmpty]){
		[_tokenField selectToken:[_tokenField.tokens lastObject]];
		return NO;
	}
	
	if ([textField.text isEqualToString:kTextHidden]){
		[_tokenField removeToken:_tokenField.selectedToken];
		return (![string isEqualToString:@""]);
	}
	
	if ([string rangeOfCharacterFromSet:_tokenField.tokenizingCharacters].location != NSNotFound){
		[_tokenField tokenizeText];
		return NO;
	}
	
	if ([_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]){
		return [_delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
	}
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[_tokenField tokenizeText];
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldReturn:)]){
		return [_delegate textFieldShouldReturn:textField];
	}
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldClear:)]){
		return [_delegate textFieldShouldClear:textField];
	}
	
	return YES;
}

@end


//==========================================================
#pragma mark - TIToken -
//==========================================================

CGFloat const hTextPadding = 14;
CGFloat const vTextPadding = 8;
CGFloat const kDisclosureThickness = 2.5;
UILineBreakMode const kLineBreakMode = UILineBreakModeTailTruncation;

@interface TIToken (Private)
CGPathRef CGPathCreateTokenPath(CGSize size, BOOL innerPath);
CGPathRef CGPathCreateDisclosureIndicatorPath(CGPoint arrowPointFront, CGFloat height, CGFloat thickness, CGFloat * width);
- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha;
@end

@implementation TIToken
@synthesize title = _title;
@synthesize representedObject = _representedObject;
@synthesize font = _font;
@synthesize tintColor = _tintColor;
@synthesize textColor = _textColor;
@synthesize highlightedTextColor = _highlightedTextColor;
@synthesize accessoryType = _accessoryType;
@synthesize maxWidth = _maxWidth;

#pragma mark Init
- (instancetype)initWithTitle:(NSString *)aTitle {
	return [self initWithTitle:aTitle representedObject:nil];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object {
	return [self initWithTitle:aTitle representedObject:object font:[UIFont systemFontOfSize:14]];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object font:(UIFont *)aFont {
	
	if ((self = [super init])){
		
		_title = [aTitle copy];
		_representedObject = object;
		
		_font = aFont;
		_tintColor = [TIToken blueTintColor];
		_textColor = [UIColor blackColor];
		_highlightedTextColor = [UIColor whiteColor];
		
		_accessoryType = TITokenAccessoryTypeNone;
		_maxWidth = 200;
		
		[self setBackgroundColor:[UIColor clearColor]];
		[self sizeToFit];
	}
	
	return self;
}

#pragma mark Property Overrides
- (void)setHighlighted:(BOOL)flag {
	
	if (self.highlighted != flag){
		[super setHighlighted:flag];
		[self setNeedsDisplay];
	}
}

- (void)setSelected:(BOOL)flag {
	
	if (self.selected != flag){
		[super setSelected:flag];
		[self setNeedsDisplay];
	}
}

- (void)setTitle:(NSString *)newTitle {
	
	if (newTitle){
		_title = [newTitle copy];
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setFont:(UIFont *)newFont {
	
	if (!newFont) newFont = [UIFont systemFontOfSize:14];
	
	if (_font != newFont){
		_font = newFont;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setTintColor:(UIColor *)newTintColor {
	
	if (!newTintColor) newTintColor = [TIToken blueTintColor];
	
	if (_tintColor != newTintColor){
		_tintColor = newTintColor;
		[self setNeedsDisplay];
	}
}

- (void)setAccessoryType:(TITokenAccessoryType)type {
	
	if (_accessoryType != type){
		_accessoryType = type;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setMaxWidth:(CGFloat)width {
	
	if (_maxWidth != width){
		_maxWidth = width;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

#pragma Tint Color Convenience

+ (UIColor *)blueTintColor {
	return [UIColor colorWithRed:0.216 green:0.373 blue:0.965 alpha:1];
}

+ (UIColor *)redTintColor {
	return [UIColor colorWithRed:1 green:0.15 blue:0.15 alpha:1];
}

+ (UIColor *)greenTintColor {
	return [UIColor colorWithRed:0.333 green:0.741 blue:0.235 alpha:1];
}

#pragma mark Layout
- (CGSize)sizeThatFits:(CGSize)size {
	
	CGFloat accessoryWidth = 0;
	
	if (_accessoryType == TITokenAccessoryTypeDisclosureIndicator){
		CGPathRelease(CGPathCreateDisclosureIndicatorPath(CGPointZero, _font.pointSize, kDisclosureThickness, &accessoryWidth));
		accessoryWidth += floorf(hTextPadding / 2);
	}
	
	CGSize titleSize = [_title sizeWithFont:_font forWidth:(_maxWidth - hTextPadding - accessoryWidth) lineBreakMode:kLineBreakMode];
	CGFloat height = floorf(titleSize.height + vTextPadding);
	
    return (CGSize){MAX(floorf(titleSize.width + hTextPadding + accessoryWidth), height - 3), height};
}

#pragma mark Drawing
- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw the outline.
	CGContextSaveGState(context);
	CGPathRef outlinePath = CGPathCreateTokenPath(self.bounds.size, NO);
	CGContextAddPath(context, outlinePath);
	CGPathRelease(outlinePath);
	
	BOOL drawHighlighted = (self.selected || self.highlighted);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGPoint endPoint = CGPointMake(0, self.bounds.size.height);
	
	CGFloat red = 1;
	CGFloat green = 1;
	CGFloat blue = 1;
	CGFloat alpha = 1;
	[self getTintColorRed:&red green:&green blue:&blue alpha:&alpha];
	
	if (drawHighlighted){
		CGContextSetFillColor(context, (CGFloat[4]){red, green, blue, 1});
		CGContextFillPath(context);
	}
	else
	{
		CGContextClip(context);
		CGFloat locations[2] = {0, 0.95};
		CGFloat components[8] = {red + 0.2, green + 0.2, blue + 0.2, alpha, red, green, blue, 0.8};
		CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, locations, 2);
		CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
		CGGradientRelease(gradient);
	}
	
	CGContextRestoreGState(context);
	
	CGPathRef innerPath = CGPathCreateTokenPath(self.bounds.size, YES);
    
    // Draw a white background so we can use alpha to lighten the inner gradient
    CGContextSaveGState(context);
	CGContextAddPath(context, innerPath);
    CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});
    CGContextFillPath(context);
    CGContextRestoreGState(context);
	
	// Draw the inner gradient.
	CGContextSaveGState(context);
	CGContextAddPath(context, innerPath);
	CGPathRelease(innerPath);
	CGContextClip(context);
	
	CGFloat locations[2] = {0, (drawHighlighted ? 0.9 : 0.6)};
    CGFloat highlightedComp[8] = {red, green, blue, 0.7, red, green, blue, 1};
    CGFloat nonHighlightedComp[8] = {red, green, blue, 0.15, red, green, blue, 0.3};
	
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, (drawHighlighted ? highlightedComp : nonHighlightedComp), locations, 2);
	CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
	CGGradientRelease(gradient);
	CGContextRestoreGState(context);
	
	CGFloat accessoryWidth = 0;
	
	if (_accessoryType == TITokenAccessoryTypeDisclosureIndicator){
		CGPoint arrowPoint = CGPointMake(self.bounds.size.width - floorf(hTextPadding / 2), (self.bounds.size.height / 2) - 1);
		CGPathRef disclosurePath = CGPathCreateDisclosureIndicatorPath(arrowPoint, _font.pointSize, kDisclosureThickness, &accessoryWidth);
		accessoryWidth += floorf(hTextPadding / 2);
		
		CGContextAddPath(context, disclosurePath);
		CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});
		
		if (drawHighlighted){
			CGContextFillPath(context);
		}
		else
		{
			CGContextSaveGState(context);
			CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 1, [[[UIColor whiteColor] colorWithAlphaComponent:0.6] CGColor]);
			CGContextFillPath(context);
			CGContextRestoreGState(context);
			
			CGContextSaveGState(context);
			CGContextAddPath(context, disclosurePath);
			CGContextClip(context);
			
			CGGradientRef disclosureGradient = CGGradientCreateWithColorComponents(colorspace, highlightedComp, NULL, 2);
			CGContextDrawLinearGradient(context, disclosureGradient, CGPointZero, endPoint, 0);
			CGGradientRelease(disclosureGradient);
			
			arrowPoint.y += 0.5;
			CGPathRef innerShadowPath = CGPathCreateDisclosureIndicatorPath(arrowPoint, _font.pointSize, kDisclosureThickness, NULL);
			CGContextAddPath(context, innerShadowPath);
			CGPathRelease(innerShadowPath);
			CGContextSetStrokeColor(context, (CGFloat[4]){0, 0, 0, 0.3});
			CGContextStrokePath(context);
			CGContextRestoreGState(context);
		}
		
		CGPathRelease(disclosurePath);
	}
	
	CGColorSpaceRelease(colorspace);
	
	CGSize titleSize = [_title sizeWithFont:_font forWidth:(_maxWidth - hTextPadding - accessoryWidth) lineBreakMode:kLineBreakMode];
	CGFloat vPadding = floor((self.bounds.size.height - titleSize.height) / 2);
	CGFloat titleWidth = ceilf(self.bounds.size.width - hTextPadding - accessoryWidth);
	CGRect textBounds = CGRectMake(floorf(hTextPadding / 2), vPadding - 1, titleWidth, floorf(self.bounds.size.height - (vPadding * 2)));
	
	CGContextSetFillColorWithColor(context, (drawHighlighted ? _highlightedTextColor : _textColor).CGColor);
	[_title drawInRect:textBounds withFont:_font lineBreakMode:kLineBreakMode];
}

CGPathRef CGPathCreateTokenPath(CGSize size, BOOL innerPath) {
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGFloat arcValue = (size.height / 2) - 1;
	CGFloat radius = arcValue - (innerPath ? (1 / [[UIScreen mainScreen] scale]) : 0);
	CGPathAddArc(path, NULL, arcValue, arcValue, radius, (M_PI / 2), (M_PI * 3 / 2), NO);
	CGPathAddArc(path, NULL, size.width - arcValue, arcValue, radius, (M_PI  * 3 / 2), (M_PI / 2), NO);
	CGPathCloseSubpath(path);
	
	return path;
}

CGPathRef CGPathCreateDisclosureIndicatorPath(CGPoint arrowPointFront, CGFloat height, CGFloat thickness, CGFloat * width) {
	
	thickness /= cosf(M_PI / 4);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, arrowPointFront.x, arrowPointFront.y);
	
	CGPoint bottomPointFront = CGPointMake(arrowPointFront.x - (height / (2 * tanf(M_PI / 4))), arrowPointFront.y - height / 2);
	CGPathAddLineToPoint(path, NULL, bottomPointFront.x, bottomPointFront.y);
	
	CGPoint bottomPointBack = CGPointMake(bottomPointFront.x - thickness * cosf(M_PI / 4),  bottomPointFront.y + thickness * sinf(M_PI / 4));
	CGPathAddLineToPoint(path, NULL, bottomPointBack.x, bottomPointBack.y);
	
	CGPoint arrowPointBack = CGPointMake(arrowPointFront.x - thickness / cosf(M_PI / 4), arrowPointFront.y);
	CGPathAddLineToPoint(path, NULL, arrowPointBack.x, arrowPointBack.y);
	
	CGPoint topPointFront = CGPointMake(bottomPointFront.x, arrowPointFront.y + height / 2);
	CGPoint topPointBack = CGPointMake(bottomPointBack.x, topPointFront.y - thickness * sinf(M_PI / 4));
	
	CGPathAddLineToPoint(path, NULL, topPointBack.x, topPointBack.y);
	CGPathAddLineToPoint(path, NULL, topPointFront.x, topPointFront.y);
	CGPathAddLineToPoint(path, NULL, arrowPointFront.x, arrowPointFront.y);
	
	if (width) *width = (arrowPointFront.x - topPointBack.x);
	return path;
}

- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
	
	CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(_tintColor.CGColor));
	const CGFloat * components = CGColorGetComponents(_tintColor.CGColor);
	
	if (colorSpaceModel == kCGColorSpaceModelMonochrome || colorSpaceModel == kCGColorSpaceModelRGB){
		
		if (red) *red = components[0];
		if (green) *green = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[1]);
		if (blue) *blue = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[2]);
		if (alpha) *alpha = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[1] : components[3]);
		
		return YES;
	}
	
	return NO;
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TIToken %p; title = \"%@\"; representedObject = \"%@\">", self, _title, _representedObject];
}


@end
