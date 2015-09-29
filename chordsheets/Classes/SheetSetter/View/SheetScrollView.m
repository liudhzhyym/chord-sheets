//
//  Sheet.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Sheet.h"

#import "SheetScrollView.h"
#import "SheetLayer.h"
#import "BarLayer.h"
#import "SheetSetterViewController.h"


NSString *SHEET_COLOR_SCHEME_POSITIVE = @"positive";
NSString *SHEET_COLOR_SCHEME_NEGATIVE = @"negative";
NSString *SHEET_COLOR_SCHEME_PRINT = @"print";

NSString *SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE = @"playback_positive";
NSString *SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE = @"playback_negative";


BOOL isDragging, isZooming, isAnimating;


@interface SheetScrollView (Private)

- (void) setup;

- (void) drawShadowAroundRect: (CGRect) rect;

- (void) leaveInDirection: (int) leavingDirection;
- (void) completeLeavingSheet;

@end


@implementation SheetScrollView


- (id) initWithCoder: (NSCoder*) coder {
    self = [super initWithCoder: coder];
    if (self) {
		[self setup];
		
	}
	return self;
	
}

- (id) initWithFrame: (CGRect) frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setup];
		
	}
    return self;
	
}

- (void) setup {
	doubleTapRecognizer = [[UITapGestureRecognizer alloc]
		initWithTarget: self action: @selector (handleDoubleTap:)];
	doubleTapRecognizer.delaysTouchesBegan = YES;
	doubleTapRecognizer.numberOfTapsRequired = 2;
	[self addGestureRecognizer: doubleTapRecognizer];
	
	tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector (handleTap:)];
	[tapRecognizer requireGestureRecognizerToFail: doubleTapRecognizer];
	[self addGestureRecognizer: tapRecognizer];
		
	[self.pinchGestureRecognizer addTarget: self action: @selector (handlePinchGesture:)];
	[self.panGestureRecognizer addTarget: self action: @selector (handleSwipe:)];
	
	[self reset];
	
	[self updateBackgroundForOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
	
	canLeaveToLeft = YES;
	canLeaveToRight = YES;
	
}

- (void) reset {
	[self setOpaque: YES];
	
	sheetView = [[SheetView alloc] initWithFrame: CGRectMake (0.f, 0.f, 1.f, 1.f)];
	[self addSubview: sheetView];
	
	self.delegate = self;
	
	self.alwaysBounceHorizontal = YES;
	self.alwaysBounceVertical = YES;
	self.decelerationRate = UIScrollViewDecelerationRateFast;
	
	self.minimumZoomScale = MIN_SCALE;
	self.maximumZoomScale = MAX_SCALE;
	
	self.bouncesZoom = YES;
	
	SheetLayer* sheetLayer = self.sheetLayer;
	sheetLayer.sheetScrollView = self;
	
	// extern float navigationBarHeight;
	extern float bottomBarHeight;
	self.scrollIndicatorInsets = UIEdgeInsetsMake (navigationBarHeight, 0, bottomBarHeight, 0);
	
}

- (SheetView*) sheetView {
	return sheetView;
	
}

- (SheetLayer*) sheetLayer {
	return sheetView.sheetLayer;
	
}

- (Sheet*) sheet {
	return sheetView.sheetLayer.modelObject;
	
}


float navigationBarHeight = 65.f - 1;
float bottomBarHeight = 44.f;


- (void) setSheet: (Sheet*) _sheet {
	if (sheet == _sheet)
		return;
	
	[sheet release];
	sheet = [_sheet retain];
	
	self.sheetLayer.modelObject = sheet;
	
}

- (NSString*) colorScheme {
	return colorScheme;
	
}

- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[colorScheme release];
	colorScheme = [_colorScheme retain];
	
	BOOL isPositive = ![_colorScheme isEqualToString: SHEET_COLOR_SCHEME_NEGATIVE];
	
	self.backgroundColor = isPositive ?
		[UIColor colorWithRed: .95f green: .95f blue: .95f alpha: 1.f] :
		[UIColor colorWithRed: .125f green: .125f blue: .125f alpha: 1.f];
	
	self.indicatorStyle = isPositive ?
		UIScrollViewIndicatorStyleBlack : UIScrollViewIndicatorStyleWhite;
	
	[sheetView setColorScheme: _colorScheme];
	
}

- (void) setKeyboardSpace: (float) _keyboardSpace {
	if (keyboardSpace == _keyboardSpace)
		return;
	
	keyboardSpace = _keyboardSpace;

}

- (void) updateBackgroundForOrientation: (UIInterfaceOrientation) orientation {
	
}

- (float) keyboardSpace {
	return keyboardSpace;
	
}

- (void) zoomToRect: (CGRect) rect animated: (BOOL) animated {
	if (!sheetView.isEditing)
		[sheetView presentStaticLayer];
	
	[super zoomToRect: rect animated: animated];
	
}

CGRect currentViewRect;

- (void) layoutSubviews {
	// NSLog (@"sheet layout subviews");
	
    CGSize boundsSize = self.bounds.size;
	boundsSize.height -= navigationBarHeight + bottomBarHeight;
	
	CGSize contentSize = originalContentSize;
    CGRect frameToCenter = CGRectMake (0, 0, contentSize.width, contentSize.height);
	
	if (contentSize.width == 0.f)
		return;
	
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
      frameToCenter.origin.x = 0;
	
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
	
	// NSLog (@" content inset %f; %f", frameToCenter.origin.x, frameToCenter.origin.x);
	
	UIEdgeInsets targetInsets = UIEdgeInsetsMake (
		frameToCenter.origin.y / 1 + navigationBarHeight,
		frameToCenter.origin.x,
		MAX (frameToCenter.origin.y / 1, keyboardSpace > 0 ? 8192 : 0) + bottomBarHeight,
		frameToCenter.origin.x
		
	);

	CGPoint contentOffset = self.contentOffset;
	
	if (keyboardSpace == 0 && !isAnimating && !UIEdgeInsetsEqualToEdgeInsets (currentInsets, targetInsets)) {
		[self setContentInset: targetInsets];
		currentInsets = targetInsets;
		
		if ((contentOffset.x < 0 || contentOffset.y < 0) &&
			(frameToCenter.size.width < boundsSize.width ||
			frameToCenter.size.height < boundsSize.height)) {
			[self setContentOffset: contentOffset];
			
		}
		
		CGPoint clampedContentOffset = self.contentOffset;
		if (!isDragging && !isZooming && !CGPointEqualToPoint (contentOffset, clampedContentOffset)) {
			[self setContentOffset: contentOffset];
			[self setContentOffset: clampedContentOffset animated: YES];
			
		}
		
	}
	
	if (!isAnimating && isZooming)
		[self centerContentAnimated: NO];
	
	double zoomScale = self.zoomScale;
	double sheetScale = sheetView.scale * zoomScale;
	
	currentViewRect = [self currentViewRect];
	
	renderQueueCenter = CGPointMake (
		(CGFloat) ((contentOffset.x + boundsSize.width / 2) / sheetScale),
		(CGFloat) ((contentOffset.y + boundsSize.height / 3) / sheetScale)
		
	);
	
	if (!sheetView.willBeginEditing && self.scrollEnabled) {
		if (!self.sheetLayer -> didRenderStatic)
			[self.sheetLayer updateLayerVisibilityInRect: [self currentViewRect]];
		if (!isDragging && !isZooming)
			[self.sheetLayer updateRenderQueueState: self.sheetLayer.hidden];
		
	}
	self.bouncesZoom = zoomScale > 1;
	
	if (needsCenteringOnLayout) {
		needsCenteringOnLayout = NO;
		
		self.contentOffset = CGPointMake(0, -navigationBarHeight);
		[self centerContentAnimated: NO];
		
	}
	
	// check if leaving sheet
	
	if (isDragging && !isZooming && !sheetView.isEditing && !isAnimating && !lockSwipeAfterEditing &&
		!sheetView.editingDelegate.isShowingKeys) {
		CGRect contentRect = CGRectMake (
			contentOffset.x, contentOffset.y,
			contentSize.width * 1, contentSize.height * 1
			
		);
		
		const float overdrag =
			UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 120 : 80;
		int overdragDelta = 0;
		
		if (canLeaveToRight) {
			double leftBound =
				contentSize.width < boundsSize.width ?
				(boundsSize.width - contentSize.width) / 2 : 0;
			
			if (-contentRect.origin.x > leftBound + overdrag)
				overdragDelta = -1;
			
		}
		if (canLeaveToLeft) {
			double rightBound =
				contentSize.width < boundsSize.width ?
				boundsSize.width - (boundsSize.width - contentSize.width) / 2 : boundsSize.width;
			
			if (-contentRect.origin.x + contentRect.size.width < rightBound - overdrag)
				overdragDelta = 1;
			
		}
		
		if (overdragDelta)
			[self leaveInDirection: overdragDelta];
		
	}
	
}

- (CGRect) currentViewRect {
	CGSize boundsSize = self.bounds.size;
	CGPoint contentOffset = self.contentOffset;
	CGFloat sheetScale = sheetView.scale * self.zoomScale;
	
	return CGRectMake (
		contentOffset.x / sheetScale,
		contentOffset.y / sheetScale,
		boundsSize.width / sheetScale,
		boundsSize.height / sheetScale
		
	);
	
}

- (void) updateContentSize {
	CGSize contentSize = sheetView.sheetLayer.contentSize;
	originalContentSize = contentSize;
	
	[self setContentSize: CGSizeMake (
		contentSize.width,
		contentSize.height
		
	)];
	
	[sheetView setFrame: CGRectMake (
		0, 0,
		contentSize.width,
		contentSize.height
		
	)];
	
	[self setNeedsLayout];
	
}

- (void) expandInset {
	const float expandedInset = 2048;
	UIEdgeInsets targetInsets = UIEdgeInsetsMake (
		expandedInset, expandedInset, expandedInset, expandedInset
		
	);
	if (!UIEdgeInsetsEqualToEdgeInsets (currentInsets, targetInsets)) {
		[self setContentInset: targetInsets];
		currentInsets = targetInsets;
		
	}
	
}

- (void) centerContentAnimated: (BOOL) animated clampToZero: (BOOL) clamp {
	double scale = self.zoomScale;
	CGSize contentSize = originalContentSize;
	CGSize boundsSize = self.bounds.size;
	
	boundsSize.height -= navigationBarHeight + bottomBarHeight;
	
	// NSLog(@"center content %i, %f x %f", animated, boundsSize.width, boundsSize.height);
	
	CGPoint contentOffset = self.contentOffset;
	if (contentSize.width * scale < boundsSize.width + .25) {
		contentOffset.x = (CGFloat) (contentSize.width * scale - boundsSize.width) / 2;
		
	} else if (contentOffset.x < 0) {
		contentOffset.x = 0;
		
	}
	
	if (contentSize.height * scale < boundsSize.height + .25) {
		contentOffset.y = (CGFloat) (contentSize.height * scale - boundsSize.height) / 2 - navigationBarHeight;
	
	} else if (contentSize.height * scale - (contentOffset.y + navigationBarHeight) < boundsSize.height) {
		contentOffset.y = (CGFloat) (contentSize.height * scale - boundsSize.height - navigationBarHeight);
		
	} else if (contentOffset.y < -navigationBarHeight) {
		contentOffset.y = -navigationBarHeight;
		
	}
	
	if (clamp && contentOffset.y < -navigationBarHeight)
		contentOffset.y = -navigationBarHeight;
	
	if (!CGPointEqualToPoint (self.contentOffset, contentOffset)) {
		if (animated) {
			[UIView beginAnimations: @"scrollView" context: nil];
			
			self.contentOffset = contentOffset;
			[UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
			[UIView setAnimationDuration: .3];
			[UIView commitAnimations];
			
		} else {
			self.contentOffset = contentOffset;
			
		}
		
	}

}

- (void) centerContentAnimated: (BOOL) animated {
	[self centerContentAnimated: animated clampToZero: NO];
	
}

- (UIView*) viewForZoomingInScrollView: (UIScrollView*) scrollView {
    return sheetView;
	
}

- (BOOL) shouldCancelEditingOnInteraction {
	return
		(sheetView.isEditing && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ||
		[sheetView.editingLayer isKindOfClass: [TextLayer class]]; // && !sheetView.willBeginEditing
	
}

- (void) scrollViewWillBeginDragging: (UIScrollView*) scrollView {
	if ([self shouldCancelEditingOnInteraction]) {
		[sheetView setEditingLayer: nil andCollapse: NO];
		
		lockSwipeAfterEditing = YES;
		
	} else if (sheetView.isEditing) {
		CGSize size = self.bounds.size;
		size.height -= navigationBarHeight + bottomBarHeight;
		
		float insetLeft = (float) MAX (0,
			(size.width - originalContentSize.width) / 2
			
		);
		float insetTop = (float) MAX (navigationBarHeight,
			(size.height - originalContentSize.height) / 2 + navigationBarHeight
			
		);
		float insetBottom = (float) MAX (bottomBarHeight,
			(size.height - originalContentSize.height) / 2 + bottomBarHeight
			
		);
		
		[self setContentInset: UIEdgeInsetsMake (
			insetTop, insetLeft, insetBottom, insetLeft
			
		)];
		
		self.scrollIndicatorInsets = UIEdgeInsetsMake (navigationBarHeight, 0, bottomBarHeight, 0);
		
//		[self layoutSubviews];
		
	}
	
	isDragging = YES;
	isAnimating = NO;
	
	[sheetView presentStaticLayer];
	
}

- (void) scrollViewDidEndDragging: (UIScrollView*) scrollView willDecelerate: (BOOL) decelerate {
	isDragging = NO;
	
	lockSwipeAfterEditing = NO;
	
	if (!decelerate) {
		[self.sheetLayer updateRenderQueueState: self.sheetLayer.hidden];
		[sheetView presentDynamicLayer];
		
	}
	
}

- (void) scrollViewDidEndDecelerating: (UIScrollView*) scrollView {
	isDragging = NO;
	
	[self.sheetLayer updateRenderQueueState: self.sheetLayer.hidden];
	[sheetView presentDynamicLayer];
	
}

- (void) handlePinchGesture: (UIGestureRecognizer*) gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan &&
		[self shouldCancelEditingOnInteraction]) {
		if (sheetView.isEditing && !sheetView.willBeginEditing) {
			[sheetView setEditingLayer: nil];
			[self setKeyboardSpace: 0];
			
		}
		
	}
	
}

- (void) scrollViewWillBeginZooming: (UIScrollView*) scrollView withView: (UIView*) view {
	isZooming = YES;
	
	if (sheetView.isEditing && !sheetView.willBeginEditing) {
		[sheetView setEditingLayer: nil];
		
	}
    
    [self expandInset];
	[sheetView presentStaticLayer];
	
}

- (void) scrollViewDidEndZooming: (UIScrollView*) scrollView withView: (UIView*) view atScale: (CGFloat) scale {
	isAnimating = NO;
    
	if (!sheetView.isPlayingBack)
		[self enableGestureRecognizers: YES];
	
	if (scale != 1.) {
		sheetView.scale = (float) (sheetView.scale * scale);
		[self.sheetLayer updateLayout];
		
		self.minimumZoomScale = MIN (1, MIN_SCALE / sheetView.scale);
		self.maximumZoomScale = MAX_SCALE / sheetView.scale;
		
		if (sheetView.isEditing) {
			if (!self.sheetLayer -> didRenderStatic)
				[self.sheetLayer updateLayerVisibilityInRect: [self currentViewRect]];
			
			if (sheetView.willBeginEditing)
				[sheetView setUpControls];
			
		}
		
		[self updateContentSize];
		
	}
	
	[self layoutSubviews];
	[self centerContentAnimated: NO];
	
	isZooming = NO;
	
    [sheetView presentDynamicLayer];
	
}

- (void) scrollViewDidEndScrollingAnimation: (UIScrollView*) scrollView {
	if (!self.scrollEnabled) {
		[self completeLeavingSheet];
		return;
		
	}
	
	isAnimating = NO;
	
	if (!sheetView.isPlayingBack)
		[self enableGestureRecognizers: YES];
	
	if (sheetView.isEditing) {
		if (!self.sheetLayer -> didRenderStatic)
			[self.sheetLayer updateLayerVisibilityInRect: [self currentViewRect]];
		[sheetView setUpControls];
		
	} else {
		[self setKeyboardSpace: 0];
		
	}
	[sheetView presentDynamicLayer];
	
}

- (void) handleTap: (UITapGestureRecognizer*) gestureRecognizer {
	if (sheetView.willBeginEditing)
		return;
	
	[sheetView handleTap: gestureRecognizer];
	
}

- (void) handleDoubleTap: (UITapGestureRecognizer*) gestureRecognizer {
	[sheetView handleDoubleTap: gestureRecognizer];
	
}

- (void) handleSwipe: (UIPanGestureRecognizer*) gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		int overdragDelta = 0;
		
		if (self.scrollEnabled && !sheetView.isEditing && !lockSwipeAfterEditing
			&& !sheetView.editingDelegate.isShowingKeys) {
			CGPoint contentOffset = self.contentOffset;
			CGSize contentSize = originalContentSize;
			CGSize boundsSize = self.bounds.size;
			
			if (canLeaveToLeft) {
				double rightBound =
					contentSize.width < boundsSize.width ?
					boundsSize.width - (boundsSize.width - contentSize.width) / 2 : boundsSize.width;
				
				if (-contentOffset.x + contentSize.width <= rightBound + 10)
					overdragDelta |= UISwipeGestureRecognizerDirectionLeft;
				
			}
			
			if (canLeaveToRight) {
				double leftBound =
					contentSize.width < boundsSize.width ?
					(boundsSize.width - contentSize.width) / 2 : 0;
				
				if (-contentOffset.x >= leftBound - 10)
					overdragDelta |= UISwipeGestureRecognizerDirectionRight;
				
			}
			
		}
		lockedSwipingDirection = overdragDelta;
		
    }
	
	if (lockedSwipingDirection && gestureRecognizer.state < UIGestureRecognizerStateEnded) {
		CGPoint v = [gestureRecognizer velocityInView: self];
        
		if (fabs (v.x) >= 1200) {
			if (v.x > 0 && (lockedSwipingDirection & UISwipeGestureRecognizerDirectionRight))
				[self leaveInDirection: -1];
			else if (v.x < 0 && (lockedSwipingDirection & UISwipeGestureRecognizerDirectionLeft))
				[self leaveInDirection: 1];
			
            lockedSwipingDirection = 0;
			
		}
		
	}

}

- (void) enableGestureRecognizers: (BOOL) doEnable {
	for (UIGestureRecognizer* recognizer in self.gestureRecognizers)
		recognizer.enabled = doEnable;
	
}

- (void) completeShiftSheetOutAnimation: (NSString*) animationId finished: (NSNumber*) finished context: (id) context {
	[self completeLeavingSheet];
	
}

- (void) leaveInDirection: (int) _leavingDirection {
	leavingDirection = _leavingDirection;
	
	CGPoint contentOffset = self.contentOffset;
	
	[self enableGestureRecognizers: NO];
	
	isAnimating = YES;
	
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.scrollEnabled = NO;
	
	self.showsHorizontalScrollIndicator = NO;
	self.showsVerticalScrollIndicator = NO;
	
	self.contentOffset = contentOffset;
	
	[UIView beginAnimations: @"scrollView" context: nil];
	[UIView setAnimationCurve: UIViewAnimationCurveLinear];
	[UIView setAnimationDuration: .125];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector:
		@selector(completeShiftSheetOutAnimation:finished:context:)];
	
	CGSize boundsSize = self.bounds.size;
	self.contentOffset = CGPointMake (
		_leavingDirection < 0 ?
			-boundsSize.width + 8 :
			originalContentSize.width * self.zoomScale + 8,
		contentOffset.y
		
	);
	
	[UIView commitAnimations];
	
}

- (void) completeLeavingSheet {
	[self.sheetLayer.renderQueue flushQueue];
	
	[sheetView stopPlaybackAndCenterContent: NO];
	[sheetView removeFromSuperview];
	[sheetView release];
	
	
	SheetSetterViewController* controller = (SheetSetterViewController*) sheetView.editingDelegate;
	[controller swapSheet: leavingDirection];
	
	[self enableGestureRecognizers: YES];
	
	//
	
	[self expandInset];
	
    CGSize boundsSize = self.bounds.size;
	boundsSize.height -= navigationBarHeight + bottomBarHeight;
	
	CGSize contentSize = originalContentSize;
	CGPoint contentOffset = self.contentOffset;
	
	CGFloat scale = self.zoomScale;
	contentOffset.y = MIN (0, (contentSize.height * scale - boundsSize.height) / 2) - navigationBarHeight;
	
	int overdragDelta = leavingDirection;
	
//	[UIView setAnimationsEnabled: NO];

	[self setContentOffset: CGPointMake (
		overdragDelta >= 0 ? -boundsSize.width - 8 : contentSize.width * scale + 8,
		contentOffset.y
		
	) animated: NO];

//	[UIView setAnimationsEnabled: YES];
	
	contentOffset.x = MIN (0, (contentSize.width * scale - boundsSize.width) / 2);
	
	[UIView beginAnimations: @"scrollView" context: nil];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration: .33];
	self.contentOffset = contentOffset;

/*
	[UIView performWithoutAnimation: ^{
		self.contentOffset = contentOffset;
		
	}];
*/
//	[self setContentOffset: contentOffset animated: NO];
	
	[UIView commitAnimations];
	
	isAnimating = NO;
	isDragging = NO;
	
	self.scrollEnabled = YES;
	self.minimumZoomScale = MIN_SCALE;
	self.maximumZoomScale = MAX_SCALE;

	self.showsHorizontalScrollIndicator = YES;
	self.showsVerticalScrollIndicator = YES;
	
}

- (void) dealloc {
	[sheetView removeFromSuperview];
	
	[sheetView release];
	[sheet release];
	[colorScheme release];
	
	if (tapRecognizer) {
		[self removeGestureRecognizer: tapRecognizer];
		[tapRecognizer release];
		
	}
	if (doubleTapRecognizer) {
		[self removeGestureRecognizer: doubleTapRecognizer];
		[doubleTapRecognizer release];
		
	}
	[super dealloc];
	
}

@end
