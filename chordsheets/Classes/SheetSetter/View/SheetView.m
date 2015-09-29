//
//  SheetView.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 03.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "SheetView.h"

#import "ChordLayer.h"
#import "SheetScrollView.h"
#import "spiral.h"

#import "Sheet.h"
#import "Bar.h"
#import "Chord.h"
#import "AttributedChord.h"
#import "ChordPlayer.h"

#import "LayerIterator.h"

#import "TextModel.h"

#import "BarLayer.h"
#import "OpeningBarLineLayer.h"

#import "SoundMixer.h"

#import "PlaybackSequence.h"


@interface SheetView (Private)

- (void) unhighlightCurrentLayerOverCursor;

- (CGRect) fixedTargetRect: (CGRect) concatenatedBounds forTargetScale: (float) targetScale;

- (Bar*) newBar;
- (Bar*) newBarUsingCurrentTimeSignature;

- (void) checkIfTimeSignatureChanged;

@end

@interface SheetView (Audio)

- (void) pausedPlaybackSoundMixer: (id) sender;

@end

@implementation SheetView

+ (Class) layerClass {
	return [CALayer class]; // [SheetLayer class];
	
}

- (id) initWithFrame: (CGRect) frame {
	
    if ((self = [super initWithFrame: frame])) {
		scale = 1.f;
		spiralBufferLength = spiral (TOUCH_EXTENT, spiralBuffer);
		
		[self setOpaque: YES];
				
		inputField = [[UITextField alloc] initWithFrame: CGRectMake (0.f, 0.f, 0.f, 0.f)];
		inputField.clearButtonMode = YES;
		inputField.returnKeyType = UIReturnKeyDone;
		inputField.delegate = self;
		
		sheetLayer = [[SheetLayer alloc] init];
		[sheetLayer setScale: (float) scale];
		
		[self presentDynamicLayer];
		if (!RENDER_IN_BACKGROUND_THREAD)
			[self.layer addSublayer: sheetLayer -> shadowLayer];
		
		editingIterator = [[LayerIterator alloc] init];
		playbackIterator = [[LayerIterator alloc] init];
		
		chordPlayer = [ChordPlayer sharedInstance];
		
		[[SoundMixer sharedInstance] addListener: self selector: @selector(pausedPlaybackSoundMixer:) forEvent: @"pausePlayback"];
		
    }
    return self;
	
}

+ (UIColor*) backgroundColorForScheme: (NSString*) colorScheme {
	return [colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE] ?
		[UIColor colorWithRed: 1.f green: 1.f blue: 1.f alpha: 1.f] :
		[UIColor colorWithRed: 0x2c / 255.f green: 0x2c / 255.f blue: 0x2c / 255.f alpha: 1.f];
	
}

- (NSString*) colorScheme {
	return colorScheme;
	
}

- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[colorScheme release];
	colorScheme = [_colorScheme retain];
	
	[self setBackgroundColor: [[self class] backgroundColorForScheme: _colorScheme]];
	
	[sheetLayer setColorScheme: _colorScheme];
	
}

- (SheetLayer*) sheetLayer {
	return sheetLayer;
	
}

- (void) drawRect: (CGRect) dirtyRect {
	
}

- (void) setScale: (float) _scale {
	self -> scale = _scale;
	
	[self setTransform: CGAffineTransformIdentity];
	self.sheetLayer.scale = _scale;
	
}

- (float) scale	{
	return (float) self -> scale;
	
}

- (ScalableLayer*) hitLayerUnderTapRecognizer: (UITapGestureRecognizer*) gestureRecognizer {
	CGPoint location = [gestureRecognizer locationInView: self];
	CGPoint relativeLocation = CGPointMake (
		location.x / scale,
		location.y / scale
		
	);
	ScalableLayer* hitLayer = nil;
    
	for (int i = 0; i < spiralBufferLength; i++) {
		unsigned int offset = spiralBuffer [i];
		
		int xOff = offset % TOUCH_EXTENT - (TOUCH_EXTENT - 1) / 2;
		int yOff = offset / TOUCH_EXTENT - (TOUCH_EXTENT - 1) / 2;
		
		hitLayer = [self.sheetLayer editableLayerUnderPoint: CGPointMake (
			relativeLocation.x + xOff * 3, relativeLocation.y + yOff * 3
			
		)];
		
		if (hitLayer) {
			if (hitLayer.hidden)
				hitLayer = nil;
			else
				break;
			
		}
		
	}
	return hitLayer;
	
}

- (void) handleTapInNonPlaybackMode: (UITapGestureRecognizer*) gestureRecognizer {
	if (willBeginEditing)
		return;
	
	ScalableLayer* hitLayer = [self hitLayerUnderTapRecognizer: gestureRecognizer];
	
	if (editingLayer && [editingLayer isKindOfClass: [TimeSignatureLayer class]]) {
		TimeSignature* timeSignature = (TimeSignature*) editingLayer.modelObject;
		
		if (timeSignatureBeforeEditing.numerator !=
			timeSignature.numerator)
			hitLayer = nil;
		
	}
	
	[self setEditingLayer: hitLayer andCollapse: isEditing];
	
	if (hitLayer == nil) {
		if (editingDelegate.isShowingKeys)
			[editingDelegate endEditing];
		else
			[sheetLayer.sheetScrollView centerContentAnimated: YES];
		
	}
	
}


- (void) handleTapInPlaybackMode: (UITapGestureRecognizer*) gestureRecognizer {
	ScalableLayer* hitLayer = [self hitLayerUnderTapRecognizer: gestureRecognizer];
	
	if (hitLayer != nil) {
		ScalableLayer* hitChord = nil;
		
		if ([hitLayer isKindOfClass: [ChordLayer class]]) {
			hitChord = (ChordLayer*) hitLayer;
			
		} else if ([hitLayer isKindOfClass: [ClosingBarLineLayer class]]) {
			hitLayer = hitLayer.nextEditableElement;
			
		}
		
		if (hitChord == nil) {
			ScalableLayer* barLayer = hitLayer;
			
			while (barLayer != nil && ![barLayer isKindOfClass: [BarLayer class]]) {
				barLayer = barLayer -> designatedSuperlayer;
				
			}
			
			if (barLayer != nil) {
				NSArray* chords = ((BarLayer*) barLayer).chords;
				if ([chords count] > 0)
					hitChord = [chords objectAtIndex: 0];
				else
					hitChord = ((BarLayer*) barLayer).openingBarLine;
				
			}
			
		}
		
		if (hitChord != nil) {
			[self stopPlayback];
			editingLayer = hitChord;
			[self startPlaybackFromCurrentElement];
			
		}
		
	}
	
}

- (void) handleTap: (UITapGestureRecognizer*) gestureRecognizer {
	if (self.isPlayingBack)
		[self handleTapInPlaybackMode: gestureRecognizer];
	else
		[self handleTapInNonPlaybackMode: gestureRecognizer];
	
}

- (CGRect) scrollViewBounds {
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	CGRect scrollViewBounds = sheetScrollView.bounds;
	return scrollViewBounds;
	
}

- (void) drawTestRect: (CGRect) testRect {
	testRect = CGRectMake (
		testRect.origin.x * scale, testRect.origin.y * scale,
		testRect.size.width * scale, testRect.size.height * scale
		
	);
	testFrame = [[UIView alloc] initWithFrame: CGRectMake (0, 0, 10, 10)];
	[testFrame setBackgroundColor: [UIColor colorWithRed: 1.f green: 1.f blue: 0.f alpha: .6f]];
	[self addSubview: testFrame];
	[testFrame setOpaque: YES];
	[testFrame setFrame: testRect];
	
}

- (void) handleDoubleTap: (UITapGestureRecognizer*) gestureRecognizer {
	if (willBeginEditing)
		return;
	
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	
	if (isEditing) {
		[self setEditingLayer: nil andCollapse: NO];
		[sheetScrollView setKeyboardSpace: 0];
		[self leaveEditModeAndCollapse: NO];
		[sheetScrollView centerContentAnimated: YES];
		return;
		
	}
	
	if (self.isPlayingBack) {
		[self stopPlayback];
		return;
		
	}
	
	CGRect scrollViewBounds = [self scrollViewBounds];
	scrollViewBounds.size.height -= navigationBarHeight + bottomBarHeight;
	
	CGSize sheetSize = sheetLayer.contentSize;
	sheetSize.width /= scale;
	sheetSize.height /= scale;
	
	double targetScale = MIN (MAX_SCALE, scrollViewBounds.size.width / sheetSize.width);
	double altTargetScale = MIN (MAX_SCALE, scrollViewBounds.size.height / sheetSize.height);
	
	sheetSize.height = sheetSize.width / scrollViewBounds.size.width * scrollViewBounds.size.height;
	
	CGPoint location = [gestureRecognizer locationInView: self];
	
	CGPoint relativeLocation = CGPointMake (
		location.x / scale,
		location.y / scale
		
	);
	
	CGRect targetRect = CGRectMake (
		0,
		relativeLocation.y - sheetSize.height / 2,
		sheetSize.width,
		sheetSize.height
		
	);
	
	targetRect = [self fixedTargetRect: targetRect forTargetScale: (float) targetScale];
	CGRect viewBounds = self.scaledViewBounds;
	
/*
	NSLog (@"view bounds %f; %f; %f; %f",
		viewBounds.origin.x, viewBounds.origin.y, viewBounds.size.width, viewBounds.size.height);
	return;
*/
	
	const float minScrollDelta = 1.5f;
	
	if (fabs (targetScale - scale) > .01 && (ABS (viewBounds.origin.x - targetRect.origin.x) > minScrollDelta ||
		ABS (viewBounds.origin.y - targetRect.origin.y) > minScrollDelta ||
		fabs (viewBounds.size.width - targetRect.size.width) > minScrollDelta ||
		fabs (viewBounds.size.height - targetRect.size.height) > minScrollDelta)) {
		
		if (NO) { // && scale != targetScale) { // debug output
			[self drawTestRect: targetRect];
			//return;
			
		}
		
		zoomingRect = CGRectMake (
			(CGFloat) (targetRect.origin.x * scale),
			(CGFloat) (targetRect.origin.y * scale - navigationBarHeight / targetScale * scale),
			(CGFloat) (targetRect.size.width * scale),
			(CGFloat) (targetRect.size.height * scale + (navigationBarHeight + bottomBarHeight) / targetScale * scale)
			
		);
		
		[sheetScrollView expandInset];
		
		[self performSelector: @selector (zoomToSelected)
			withObject: nil afterDelay: .05];
		
	} else {
		targetScale = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
			1 / scale * MIN (2.f, MAX (.75f, altTargetScale)) :
			1.5f / scale;
		
		targetRect = CGRectMake (
			(CGFloat) (relativeLocation.x - sheetSize.width / 2 / targetScale),
			(CGFloat) (relativeLocation.y - sheetSize.height / 2 / targetScale),
			(CGFloat) (sheetSize.width / targetScale),
			(CGFloat) (sheetSize.height / targetScale)
			
		);
        
		 targetRect = [self fixedTargetRect: targetRect forTargetScale: (float) targetScale];
		
		if (NO) { // && scale != targetScale) { // debug output
			[self drawTestRect: targetRect];
			//return;
			
		}
		
		zoomingRect = CGRectMake (
			(CGFloat) (targetRect.origin.x * scale),
			(CGFloat) (targetRect.origin.y * scale - navigationBarHeight / targetScale),
			(CGFloat) (targetRect.size.width * scale),
			(CGFloat) (targetRect.size.height * scale + (navigationBarHeight + bottomBarHeight) / targetScale)
			
		);
		
		[sheetScrollView expandInset];
		
		[self performSelector: @selector (zoomToSelected)
			withObject: nil afterDelay: .05];
		
	}
	
}

- (float) fullContentScale {
	CGRect scrollViewBounds = [self scrollViewBounds];
	CGSize sheetSize = sheetLayer.contentSize;
	sheetSize.width /= scale;
	sheetSize.height /= scale;
	
	float targetScale = (float) MIN (2.f, MAX (
		scrollViewBounds.size.width / sheetSize.width,
		MIN_SCALE
		
	));
	return targetScale;
	
}

- (void) zoomToFullContent {
	[self setScale: [self fullContentScale]];
	[[self sheetLayer] updateLayout];
	
}


extern BOOL isAnimating;

- (void) zoomToSelected {
	
	isAnimating = YES;
	
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	if (!self.isPlayingBack)
		[sheetScrollView enableGestureRecognizers: NO];
	
	if (zoomingRect.size.width != 0.f && zoomingRect.size.height != 0.f) {
		[sheetScrollView zoomToRect: zoomingRect animated: YES];
		
	}
	
}

- (float) getTargetScale {
	if (self.isPlayingBack) {
		if (DRAW_AS_BANNER_WHEN_PLAYING_BACK)
			return 1.5f;
		else
			return [self fullContentScale];
		
	} else {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
			return (float) MAX (1.5f, MIN (2.f, scale));
		else
			return (float) MAX (.75f, MIN (2.f, scale));
		
	}
	
}

- (void) fixConcatenatedBounds: (CGRect*) concatenatedBounds
		onSheetBounds: (CGRect) sheetBounds forTargetScale: (float) targetScale inset: (float) inset {
	
	if (concatenatedBounds -> size.width > (sheetBounds.size.width - inset) / targetScale) {
		concatenatedBounds -> size.width = (sheetBounds.size.width - inset) / targetScale;
		
	}
	
}

extern float navigationBarHeight;
extern float bottomBarHeight;

- (CGRect) fixedTargetRect: (CGRect) targetRect forTargetScale: (float) targetScale {
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	/*
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	if (UIInterfaceOrientationIsLandscape (orientation)) {
		CGFloat swap = screenBounds.size.width;
		screenBounds.size.width = screenBounds.size.height;
		screenBounds.size.height = swap;
		
	}
	*/
	
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	CGRect sheetBounds = [self scrollViewBounds];
	sheetBounds.size.height -= navigationBarHeight;
	
	double sheetScreenBottom = sheetBounds.size.height;
	
	float keyboardHeight = bottomBarHeight;
	double keyboardTop = screenBounds.size.height - keyboardHeight;
	double keyboardSpace = MAX (0, sheetScreenBottom - keyboardTop);
	
	// NSLog(@"sheet bounds %f %f %f %f", sheetBounds.origin.x, sheetBounds.origin.y, sheetBounds.size.width, sheetBounds.size.height);
	// NSLog(@"sheet bottom %f keyboard top %f", sheetScreenBottom, keyboardTop);
	
	
	[sheetScrollView setKeyboardSpace: (float) keyboardSpace];
	
	sheetBounds.size.height -= keyboardSpace;
	
	CGSize frameSize = sheetScrollView -> originalContentSize; // self.frame.size;
	CGSize contentSize = CGSizeMake (frameSize.width / scale, frameSize.height / scale);
	
	/*
	NSLog (@"scale: %f target scale: %f", scale, targetScale);
	
	NSLog (@"scroll bounds size: %f; %f", sheetBounds.size.width, sheetBounds.size.height);
	NSLog (@"content size: %f; %f", contentSize.width, contentSize.height);
	NSLog (@"relative target rect: %f, %f, %f, %f",
		targetRect.origin.x, targetRect.origin.y, targetRect.size.width, targetRect.size.height);
	*/
	
	CGFloat spaceX = MAX (0,
		targetRect.size.width - contentSize.width
		
	);
	CGFloat insetLeft = -spaceX / (CGFloat) 2.;
	CGFloat insetRight = spaceX / (CGFloat) 2.;
	
	CGFloat spaceY = MAX (0,
		targetRect.size.height - contentSize.height
		
	);
	
	CGFloat insetTop = -spaceY / (CGFloat) 2.;
	CGFloat insetBottom = (CGFloat) MAX (keyboardSpace / 1, spaceY / 2);
	
	// NSLog (@"inset top %f; right %f; bottom %f; left %f", insetTop, insetRight, insetBottom, insetLeft);
	
	if (contentSize.width > targetRect.size.width) {
		if (targetRect.origin.x + targetRect.size.width > contentSize.width + insetRight)
			targetRect.origin.x = contentSize.width - targetRect.size.width + insetRight;
		if (targetRect.origin.x < insetLeft)
			targetRect.origin.x = insetLeft;
		
	} else {
		targetRect.origin.x = (contentSize.width - targetRect.size.width) / 2;
		
	}
	
	if (contentSize.height > targetRect.size.height && !willBeginEditing && !isEditing) { // sheet height bigger than view
		if (targetRect.origin.y + targetRect.size.height > contentSize.height + insetBottom)
			targetRect.origin.y = contentSize.height - targetRect.size.height + insetBottom;
		if (targetRect.origin.y < insetTop)
			targetRect.origin.y = insetTop;
		
		
		if (!willBeginEditing && !isEditing && targetRect.origin.y > contentSize.height)
			targetRect.origin.y = contentSize.height;
		
	} else {
		if (willBeginEditing || isEditing) {
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
				if (contentSize.height < sheetBounds.size.height / targetScale) {
					insetTop = (contentSize.height - sheetBounds.size.height / targetScale) / 2; // 0;
					targetRect.origin.y = insetTop;
					
				} else {
					insetTop = 0;
					
				}
				
			} else {
				if (contentSize.height < sheetBounds.size.height / targetScale) {
					insetTop = (contentSize.height - sheetBounds.size.height / targetScale) / 2;
					targetRect.origin.y = insetTop;
					
				} else {
					insetTop = 0;
					
				}
				
			}
			
		}
		if (keyboardSpace != 0) {
			if (targetRect.origin.y < insetTop)
				targetRect.origin.y = insetTop;
			if (targetRect.origin.y > contentSize.height)
				targetRect.origin.y = contentSize.height;
			
		} else {
			targetRect.origin.y = (contentSize.height - targetRect.size.height) / 2;
			
		}
		
	}
	
	if ((willBeginEditing || isEditing) && contentSize.height > sheetBounds.size.height / targetScale) {
		targetRect.origin.y = MIN (
			targetRect.origin.y,
			contentSize.height - sheetBounds.size.height / targetScale
			
		);
		
	}
	
	targetRect.origin.x = (CGFloat) round (targetRect.origin.x);
	targetRect.origin.y = (CGFloat) round (targetRect.origin.y);
	
	/*
	NSLog (@"fixed target rect: %f, %f, %f, %f",
		targetRect.origin.x, targetRect.origin.y, targetRect.size.width, targetRect.size.height);
	*/
	
	return targetRect;
	
}

- (void) setUpZoom: (ScalableLayer*) hitLayer {
	if (!hitLayer)
		return;
	
	float targetScale = [self getTargetScale];
	
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	CGRect concatenatedBounds = self.isPlayingBack ?
		hitLayer.concatenatedBoundsForPlayback :
		hitLayer.concatenatedBoundsForEditor;
	
	//
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL isInLandscape = UIInterfaceOrientationIsLandscape (orientation);
	
	extern float bottomBarHeight;
	
	if (isEditing || willBeginEditing) {
		BOOL willShowSoftkeyboard = [editingLayer isKindOfClass: [TextLayer class]];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			bottomBarHeight = willShowSoftkeyboard ? isInLandscape ?
				352.f + 64 + 39 :
				265.f + 64 + 39 :
				250 + 64;
			
		} else {
			bottomBarHeight = willShowSoftkeyboard ? 216.f + 64 + 37 : 250 + 9;
			
		}
		
	}
	
	sheetScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, bottomBarHeight, 0);
	CGRect sheetBounds = [self scrollViewBounds];
	sheetBounds.size.height -= navigationBarHeight + bottomBarHeight;
	
	[self fixConcatenatedBounds: &concatenatedBounds
		onSheetBounds: sheetBounds
		forTargetScale: targetScale inset: 54];
	
	CGFloat viewWidthOff = -sheetBounds.size.width / 2;
	
	float viewHeightOff = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
		isInLandscape ? -200 : -350 :
		-110;
	
	CGRect targetRect = CGRectMake (
		concatenatedBounds.origin.x + concatenatedBounds.size.width / 2 + viewWidthOff / targetScale,
		concatenatedBounds.origin.y + concatenatedBounds.size.height / 2 + viewHeightOff / targetScale,
		sheetBounds.size.width / targetScale,
		sheetBounds.size.height / targetScale
		
	);
	
	targetRect = [self fixedTargetRect: targetRect forTargetScale: targetScale];
	
	CGRect viewBounds = self.scaledViewBounds;
	
/*
	[self drawTestRect: targetRect];
	NSLog (@"view bounds %f; %f; %f; %f",
		viewBounds.origin.x, viewBounds.origin.y, viewBounds.size.width, viewBounds.size.height);
	
	return;
	
*/
	const float minScrollDelta = 1.5f;
	
	if (ABS (viewBounds.origin.x - targetRect.origin.x) > minScrollDelta ||
		ABS (viewBounds.origin.y - targetRect.origin.y + navigationBarHeight / targetScale) > minScrollDelta ||
		ABS (viewBounds.size.width - targetRect.size.width) > minScrollDelta ||
		ABS (viewBounds.size.height - targetRect.size.height - (navigationBarHeight + bottomBarHeight) / targetScale) > minScrollDelta) {
		
		setUpControlsImmediately = NO;
		
		zoomingRect = CGRectMake (
			(CGFloat) round (targetRect.origin.x * scale),
			(CGFloat) round (targetRect.origin.y * scale - navigationBarHeight / targetScale * scale),
			(CGFloat) round (targetRect.size.width * scale),
			(CGFloat) round (targetRect.size.height * scale + (navigationBarHeight + bottomBarHeight) / targetScale * scale));
		
		// NSLog(@"zooming rect %f, %f, %f, %f", targetRect.origin.x, targetRect.origin.y, targetRect.size.width, targetRect.size.height);
		
		[sheetScrollView expandInset];
		[self performSelector: @selector (zoomToSelected)
			withObject: nil afterDelay: .05];
		
	} else {
		setUpControlsImmediately = YES;
		
	}
	
	float editorYPadding = 0;
	if ([hitLayer isKindOfClass: [EditableTextLayer class]]) {
		editorYPadding = ((EditableTextLayer*) hitLayer) -> editorYPadding;
		
	}
	
	CGRect inputFieldFrame = inputField.frame;
	inputField.frame = CGRectMake (
		(CGFloat) round (inputFieldFrame.origin.x - targetRect.origin.x * targetScale + 0),
		(CGFloat) round (inputFieldFrame.origin.y - targetRect.origin.y * targetScale + 1) + editorYPadding,
		(CGFloat) round (inputFieldFrame.size.width),
		(CGFloat) round (inputFieldFrame.size.height)
		
	);
	
}

- (CGRect) scaledViewBounds {
	SheetScrollView* sheet = self.sheetLayer.sheetScrollView;
	CGRect sheetBounds = sheet.bounds;
	CGRect viewBounds = CGRectMake (
		sheet.contentOffset.x / scale, sheet.contentOffset.y / scale,
		sheetBounds.size.width / scale, sheetBounds.size.height / scale
		
	);
	return viewBounds;
	
}


- (ScalableLayer*) editingLayer {
	return editingLayer;
	
}

- (void) setEditingLayer: (ScalableLayer*) _editingView andCollapse: (BOOL) shouldCollapse {
	/*
	NSLog (@"set editing layer %@ with model object %@",
		_editingView, _editingView.modelObject);
	NSLog (@"isEditingAnnotation %i", isEditingAnnotation);
	*/
	
	didEdit = editingLayer != nil;
	
	if ([_editingView isKindOfClass: [TimeSignatureLayer class]]) {
		if (timeSignatureBeforeEditing)
			[timeSignatureBeforeEditing release];
		
		timeSignatureBeforeEditing = [_editingView.modelObject copy];
		
	}
	
	if (_editingView)
		willBeginEditing = YES;
	
	ScalableLayer* lastEditingLayer = editingLayer;
	if (editingLayer) {
		ScalableLayer* currentEditingLayer = editingLayer;
		
		if (isEditingAnnotation)
			[self leaveAnnotationEditingMode];
		
		[currentEditingLayer leaveEditMode];
		
		[self leaveEditModeAndCollapse: shouldCollapse];
		
	}
	
	if (_editingView) {		
		willBeginEditing = YES; // was reset in leaveEditModeAndCollapse:
		
		// [[hitLayer superlayer] addSublayer: hitLayer];
		
		SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
		sheetScrollView.scrollsToTop = NO;
		
		if ([_editingView isKindOfClass: [TextLayer class]]) {
			
			// [editingDelegate endEditing];
			
			CGRect sheetBounds = [self scrollViewBounds];
			CGSize layerBoundsSize = self.sheetLayer.bounds.size;
			
			
			CGFloat editorMinWidth = layerBoundsSize.width / scale - 28;
			((EditableTextLayer*) _editingView) -> editorMinWidth = (float) (layerBoundsSize.width / scale - 28);
			
			
			
			CGRect concatenatedBounds = _editingView.concatenatedBoundsForEditor;
			float targetScale = [self getTargetScale];
			
			
			[self fixConcatenatedBounds: &concatenatedBounds
					onSheetBounds: sheetBounds
					forTargetScale: targetScale inset: 54];
			
			if (concatenatedBounds.size.width > (sheetBounds.size.width - 36) / targetScale) {
				concatenatedBounds.size.width = (sheetBounds.size.width - 36) / targetScale;
				
			}
/*
			NSLog (@"concatenated bounds %f; %f; %f; %f",
				concatenatedBounds.origin.x, concatenatedBounds.origin.y,
				concatenatedBounds.size.width, concatenatedBounds.size.height);
*/
			
			TextLayer* textLayer = (TextLayer*) _editingView;
			
			inputField.font = [UIFont
				fontWithName: textLayer.fontName
				size: textLayer.fontSize * targetScale
				
			];
			inputField.textColor = [UIColor colorWithRed: textLayer -> fontColor [0]
				green: textLayer -> fontColor [1] blue: textLayer -> fontColor [2]
				alpha: textLayer -> fontColor [3]];
			inputField.text = textLayer.text;
			
			
			inputField.frame = CGRectMake (
				concatenatedBounds.origin.x * targetScale - 0,
				concatenatedBounds.origin.y * targetScale - 2,
				MIN (editorMinWidth * targetScale, MAX (64 * targetScale, concatenatedBounds.size.width * targetScale + 28)),
				concatenatedBounds.size.height * targetScale + 0
				
			);
			
		}
		editingLayer = _editingView;
		[self setUpZoom: _editingView];
		
	} else {
		// NSLog (@"did not hit layer");
		
	}
	
	editingLayer = _editingView;
	
	if (editingLayer) {
		[editingLayer retain];
		[editingLayer enterEditMode];
		
		[self enterEditMode];
		
		if ([editingLayer isKindOfClass: [ChordLayer class]]) {
			 [self playChord: editingLayer.modelObject];
			
		}
		
	} else {
		bottomBarHeight = 44;
		
		SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
		sheetScrollView.scrollIndicatorInsets = UIEdgeInsetsMake (navigationBarHeight, 0, bottomBarHeight, 0);
	
		if (sheetScrollView.keyboardSpace != 0) {
			if (willBeginEditing && lastEditingLayer)
				[self setUpZoom: lastEditingLayer];
			else
				[sheetScrollView setKeyboardSpace: 0];
			
		}
		
	}
	
	editingIterator.currentLayer = _editingView;
	
	if ([_editingView isKindOfClass: [AnnotationLayer class]]) {
		// BarLayer* barLayer = (BarLayer*) _editingView.superlayer;
		// layerBeforeEnteringAnnotationEditingMode = barLayer.openingBarLine;
		
		isEditingAnnotation = YES;
		
	}
	
	if (setUpControlsImmediately && _editingView)
		[self setUpControls];
	
	if (!_editingView)
		[sheetLayer cleanUpEmptyBars];
	
//	if (shouldCollapse)
//		[sheetLayer.sheetScrollView centerContentAnimated: YES];

	
	
}

- (void) setEditingLayer: (ScalableLayer*) _editingView {
	[self setEditingLayer: _editingView andCollapse: YES];
	
}

@synthesize willBeginEditing;
@synthesize isEditing;

- (void) enterEditMode {
	isEditing = YES;
	
	[self adjustCursorPosition];
	
}

- (void) leaveEditModeAndCollapse: (BOOL) shouldCollapse {
	[self checkIfTimeSignatureChanged];
	
	if ([editingLayer isKindOfClass: [TextLayer class]]) {
		[self commitTextEdit];
		[inputField resignFirstResponder];
		[inputField removeFromSuperview];
		
	}
	if (!willBeginEditing && editingDelegate) {
		if (editingDelegate.isShowingKeys)
			[editingDelegate endEditing];
		
	}
	
	isEditing = NO;
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	
	if (!willBeginEditing) {
		[self presentCursor: NO];
		sheetScrollView.scrollsToTop = YES;
		
	}
	
	willBeginEditing = NO;
	
	bottomBarHeight = 44;
	sheetScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(navigationBarHeight, 0, bottomBarHeight, 0);
	[sheetScrollView setNeedsLayout];
	
	if (shouldCollapse) {
	/*
		UIEdgeInsets insets = sheetScrollView.contentInset;
		[sheetScrollView setContentInset: UIEdgeInsetsMake (navigationBarHeight,0,bottomBarHeight,0)];
		sheetScrollView -> currentInsets = UIEdgeInsetsMake (navigationBarHeight,0,bottomBarHeight,0);
		[sheetScrollView layoutSubviews];
		[sheetScrollView centerContentAnimated: NO];
		[sheetScrollView setContentInset: insets];
		sheetScrollView -> currentInsets = insets;
		[sheetScrollView layoutSubviews];
	*/	
		isAnimating = NO;
		
	}
	
}

- (void) leaveEditMode {
	[self leaveEditModeAndCollapse: YES];
	
	[sheetLayer.sheetScrollView centerContentAnimated: YES];
	
}

- (void) setUpTextControl {
	willBeginEditing = NO;
	
	editingLayer.hidden = YES;
	[self.superview.superview addSubview: inputField];
			
			TextLayer* textLayer = (TextLayer*) editingLayer;
			CGRect concatenatedBounds = textLayer.concatenatedBoundsForEditor;
			
			CGRect inputFieldFrame = inputField.frame;
			CGPoint contentOffset = sheetLayer.sheetScrollView.contentOffset;
			
			inputField.frame = CGRectMake (
				(CGFloat) round (concatenatedBounds.origin.x * scale - contentOffset.x + 0),
				(CGFloat) round (concatenatedBounds.origin.y * scale - contentOffset.y + 0),
				inputFieldFrame.size.width,
				inputFieldFrame.size.height
				
			);
	
	[inputField becomeFirstResponder];
	
}

- (BOOL) textFieldShouldReturn: (UITextField*) _inputField {
	// NSLog (@"is editing annotation %i, '%@'", isEditingAnnotation, _inputField.text);
	
	NSString* contentText = [_inputField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (!isEditingAnnotation && ![contentText length])
		return NO;
	
	if (isEditingAnnotation) {
		[self leaveAnnotationEditingMode];
		[self setEditingLayer: layerBeforeEnteringAnnotationEditingMode andCollapse: NO];
		
	} else {
		[self setEditingLayer: nil andCollapse: NO];
		[sheetLayer.sheetScrollView centerContentAnimated: YES];
		
	}
	
	return YES;
	
}

- (void) setUpEditingDelegate {
	willBeginEditing = NO;
	
	[editingDelegate beginEditing];
	
}

- (void) setUpControls {
	if (editingDelegate) {
		if (editingLayer) {
			if (setUpControlsImmediately)
				[self setUpEditingDelegate];
			else
				[self performSelector: @selector (setUpEditingDelegate)
					withObject: nil afterDelay: .1];
			
		}
		
	}
	
	if ([editingLayer isKindOfClass: [TextLayer class]]) {
		if (setUpControlsImmediately)
			[self setUpTextControl];
		else
			[self performSelector: @selector (setUpTextControl)
				withObject: nil afterDelay: .1];
		
	} else {
		willBeginEditing = NO;
		
	}
	
	[self presentCursor: YES];
	
}

- (void) presentCursor: (BOOL) state {
	CursorLayer* cursor =  sheetLayer.cursor;
	if (state) {
		BOOL cursorWasHidden = cursor.hidden;
		if (cursorWasHidden) {
			cursor.hidden = NO;
			if (!didEdit || self.isPlayingBack)
				[CATransaction setDisableActions: YES];
			
		}
		
		if (self.isPlayingBack) {
			if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE]) {
				[cursor setColorScheme: SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE];
				
			} else {
				[cursor setColorScheme: SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE];
				
			}
			
		} else {
			[cursor setColorScheme: colorScheme];
			
		}
		
	} else {
		cursor.hidden = YES;		
		[self unhighlightCurrentLayerOverCursor];
		
	}
	
}

- (void) presentStaticLayer {
	// NSLog (@">>> present static layer");
	
	if (RENDER_IN_BACKGROUND_THREAD) {
		[self presentCursor: NO];
		
		[CATransaction setDisableActions: YES];
		[CATransaction lock];
		
		if (sheetLayer.superlayer)
			[sheetLayer removeFromSuperlayer];
		
		if (sheetLayer -> didRenderStatic) {
			[sheetLayer -> tileRenderQueue unpauseQueue];
			
		} else {
			[sheetLayer -> renderQueue flushQueue];
			[sheetLayer renderStatic];
			
		}
		
		[self.layer insertSublayer: sheetLayer -> barRowContainer atIndex: 0];
		[self.layer addSublayer: sheetLayer.staticLayer];
		
		// [self.layer addSublayer: sheetLayer -> shadowLayer];
		// [self.layer addSublayer: sheetLayer -> barRowContainer];
		
		[CATransaction unlock];
		[CATransaction setDisableActions: NO];
		
	}
	
}

- (void) presentDynamicLayer {
	// NSLog (@">>> present dynamic layer");
	// NSLog (@">>> sheet layer opaque %i", sheetLayer.opaque);
	
	[CATransaction setDisableActions: YES];
	[CATransaction lock];
	
	if (sheetLayer.staticLayer.superlayer)
		[sheetLayer.staticLayer removeFromSuperlayer];
	
	[sheetLayer -> tileRenderQueue pauseQueue];
	
	[CATransaction setDisableActions: YES];	
	[sheetLayer updateLayerVisibilityInRect:
		[sheetLayer.sheetScrollView currentViewRect]];
	[CATransaction setDisableActions: NO];
	
	[self.layer addSublayer: sheetLayer];
	[self.layer insertSublayer: sheetLayer -> barRowContainer atIndex: 0];
	// [self.layer insertSublayer: sheetLayer -> cursorContainer atIndex: 1];
	// [self.layer addSublayer: sheetLayer -> cursorContainer];
	
	[CATransaction unlock];
	[CATransaction setDisableActions: NO];
	
}

- (void) dealloc {
	editingDelegate = nil;
	
	if (self.editingLayer != nil)
		self.editingLayer = nil;
	
	if (timeSignatureBeforeEditing)
		[timeSignatureBeforeEditing release];
	
	if (inputField) {
		[inputField removeFromSuperview];
		[inputField release];
		
	}
	
	if (sheetLayer) {
		[sheetLayer removeFromSuperlayer];
		[sheetLayer release];
		
	}
	
	[editingIterator release];
	[playbackIterator release];
	
	[self stopPlayback];
	
	[[SoundMixer sharedInstance] removeListener: self selector: @selector(pausedPlaybackSoundMixer:) forEvent: @"pausePlayback"];
	if (playbackSequence)
		[playbackSequence release];
	
	[super dealloc];
	
}

@end


#import "KeySignature.h"
#import "KeySignatureLayer.h"

@implementation SheetView (Editing)

- (id <SheetEditingDelegate>) editingDelegate {
	return editingDelegate;
	
}

- (void) setEditingDelegate: (id <SheetEditingDelegate>) _editingDelegate  {
	editingDelegate = _editingDelegate;
	
}

- (UITextField*) inputField {
	return inputField;
	
}

- (ScalableLayer*) defaultFirstLayer {
	return sheetLayer.title.title;
	
}

- (id) currentElement {
	ScalableLayer* currentLayer = editingIterator.currentLayer;
	if (!currentLayer)
		return nil;
	
	return isEditingAnnotation ?
		currentLayer.annotationModelObject : currentLayer.modelObject;
	
}

- (void) commitChangeToCurrentElement {
	ScalableLayer* currentLayer = editingIterator.currentLayer;
	
	BOOL didChangeTitle = NO;
	BOOL didChangeArtist = NO;
	
	if ([currentLayer.designatedSuperlayer isKindOfClass: [BarLayer class]]) {
		BarLayer* barLayer = (BarLayer*) currentLayer.superlayer;
		
		if ([currentLayer isKindOfClass: [OpeningBarLineLayer class]]) {
			Bar* bar = barLayer.modelObject;
			
			OpeningBarLineLayer* openingBarLineLayer = (OpeningBarLineLayer*) currentLayer;
			
			NSString* barMarkKey = ((OpeningBarLine*) openingBarLineLayer.modelObject).barMark;
			if (barMarkKey) {
				if ([bar.chords count])
					[bar.chords removeAllObjects];
				
				[barLayer.closingBarLine updateFromModelObject];
				[barLayer updateFromModelObject];
				
				if ([barMarkKey isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE]) {
					
					bar.closingBarLine.repeatCount = 0;
					bar.closingBarLine.type = BAR_LINE_TYPE_SINGLE;
					
					[bar.closingBarLine removeAllRehearsalMarks];
					[barLayer.closingBarLine updateFromModelObject];
					[barLayer updateFromModelObject];
					
					BarLayer* nextBarLayer =
						(BarLayer*) barLayer.closingBarLine.nextEditableElement.designatedSuperlayer;
					Bar* nextBar = nextBarLayer.modelObject;
					
					if (!nextBarLayer) {
						nextBar = [self newBar];
						[sheetLayer appendBar: nextBar];
						[nextBar release];
						
						nextBarLayer = [sheetLayer -> bars lastObject];
						
					}
					NSString* nextBarMark = nextBar.openingBarLine.barMark;
					if ([nextBarMark isEqualToString: BAR_LINE_BAR_MARK_SIMILE] ||
						[nextBarMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE]) {
						BarLayer* nextNextBarLayer = [sheetLayer -> bars objectAtIndex: [sheetLayer -> bars indexOfObject: nextBarLayer] + 1];
						Bar* nextNextBar = nextNextBarLayer.modelObject;
						
						[nextNextBar adaptForTimeSignature: [self currentTimeSignature]];
						nextNextBarLayer -> isLocked = NO;
						[nextNextBarLayer updateFromModelObject];
						
						nextBar.openingBarLine.barMark = nil;
						
					}
					
					nextBarLayer -> isLocked = YES;
					
					nextBar.openingBarLine.timeSignature = nil;
					nextBar.openingBarLine.keySignature = nil;
					
					if ([nextBar.chords count]) {
						[nextBar.chords removeAllObjects];
						
					}
					nextBar.openingBarLine.repeatCount = 0;
					nextBar.openingBarLine.type = BAR_LINE_TYPE_SINGLE;
					nextBar.openingBarLine.voltaCount = 0;
					
					nextBar.openingBarLine.annotation = nil;
					[nextBar.openingBarLine removeAllRehearsalMarks];
					
					[nextBarLayer.openingBarLine updateFromModelObject];
					[nextBarLayer updateFromModelObject];
					
					barLayer.closingBarLine.isEditable = NO;
					nextBarLayer.openingBarLine.isEditable = NO;
					
					[nextBarLayer setNeedsUpdateLayout];
					
				} else {
					if ([bar.chords count]) {
						[bar.chords removeAllObjects];
						[barLayer updateFromModelObject];
						
					}
					BarLayer* nextBarLayer =
						(BarLayer*) barLayer.closingBarLine.nextEditableElement.designatedSuperlayer;
					
					if (nextBarLayer && nextBarLayer -> isLocked) {
						TimeSignature* currentTimeSignature = [self currentTimeSignature];
						Bar* nextBar = nextBarLayer.modelObject;
						nextBarLayer -> isLocked = NO;
						
						if (currentTimeSignature) {
							[nextBar adaptForTimeSignature: currentTimeSignature];
							[nextBarLayer updateFromModelObject];
							
						}
						
					}
				
				}
				[sheetLayer linkAllElements];
				
			} else if (!barMarkKey && openingBarLineLayer.barMark) {
				TimeSignature* currentTimeSignature = [self currentTimeSignature];
				if (currentTimeSignature) {
					[bar adaptForTimeSignature: currentTimeSignature];
					
					barLayer -> isLocked = NO;
					[barLayer updateFromModelObject];
					
					NSUInteger barLayerIndex = [sheetLayer -> bars indexOfObject: barLayer];
					
					if (barLayerIndex != NSNotFound &&
						barLayerIndex + 1 < [sheetLayer -> bars count]) {
						BarLayer* nextBarLayer = [sheetLayer -> bars objectAtIndex: barLayerIndex + 1];
						if (!nextBarLayer.openingBarLine.barMark) {
							Bar* nextBar = nextBarLayer.modelObject;
							[nextBar adaptForTimeSignature: currentTimeSignature];
							
							nextBarLayer -> isLocked = NO;
							[nextBarLayer updateFromModelObject];
							
							[nextBarLayer setNeedsUpdateLayout];
							
							nextBarLayer.openingBarLine.isEditable = YES;
							
						}
						
					}
					barLayer.closingBarLine.isEditable = YES;
					
					[sheetLayer linkAllElements];
					
				}
				
			}
			
		}
		[currentLayer updateFromModelObject];
		[barLayer setNeedsUpdateLayout];
				
	} else {
		if ([currentLayer isKindOfClass: [TextLayer class]]) {
			EditableTextLayer* currentTextLayer = (EditableTextLayer*) currentLayer;
			
			Sheet* sheet = (Sheet*) sheetLayer.modelObject;
			
			if ([currentTextLayer.label isEqualToString: @"Song Title"]) {
				if (![inputField.text isEqualToString: sheet.title]) {
					sheet.title = inputField.text;
					didChangeTitle = YES;
					
				}
				
			} else if ([currentTextLayer.label isEqualToString: @"Artist"]) {
				sheet.artist = inputField.text;
				
			} else if ([currentTextLayer.label isEqualToString: @"Editor"]) {
				sheet.copyright = inputField.text;
				
			}
			
		}
		
		[currentLayer updateFromModelObject];
		
	}
	[sheetLayer updateLayout];
	
	CGRect layerBounds = currentLayer.concatenatedBounds;
	renderQueueCenter = CGPointMake (
		layerBounds.origin.x + layerBounds.size.width / 2,
		layerBounds.origin.y + layerBounds.size.height / 2
		
	);
	
	if (didChangeTitle)
		[editingDelegate didChangeSheetTitle];
	if (didChangeTitle || didChangeArtist)
		[sheetLayer.title updateLayout];
	
}

- (void) commitTextEdit {
	editingLayer.hidden = NO;
	TextLayer* textLayer = (TextLayer*) editingLayer;
	textLayer.hidden = NO;
	
	NSString* contentText = [inputField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (isEditingAnnotation || [contentText length]) {
		[textLayer.modelObject setText: contentText];
		[self commitChangeToCurrentElement];
		
	}
	
}

- (BarLayer*) barLayerOfElement: (ScalableLayer*) element {
	while (element && ![element isKindOfClass: [BarLayer class]])
		element = element -> designatedSuperlayer;
	
	return (BarLayer*) element;
	
}

- (BarLayer*) currentEditingBarLayer {
	return [self barLayerOfElement: editingLayer];
	
}

- (void) insertBarAtCurrentPosition {
	BarLayer* currentBarLayer;
	
	if ([editingLayer isKindOfClass: [ClosingBarLineLayer class]]) {
		currentBarLayer = [self barLayerOfElement: editingLayer.nextEditableElement];
		if (!currentBarLayer) {
			[self goForward];
			return;
			
		}
		
	} else {
		currentBarLayer = [self currentEditingBarLayer];
		
	}
	
	if (currentBarLayer != nil) {
		Sheet* sheet = sheetLayer.modelObject;
		Bar* bar = currentBarLayer.modelObject;
		NSArray* bars = sheet.bars;
		NSUInteger position = [bars indexOfObject: bar];
		
		Bar* newBar = [self newBarUsingCurrentTimeSignature];
		[sheetLayer insertBar: newBar atPosition: (int) position];
		[newBar release];
		
		[self setEditingLayer: ((BarLayer*) [sheetLayer -> bars objectAtIndex: position]).openingBarLine];
		
	}
	
}

- (void) removeBarAtCurrentPosition {
	BarLayer* currentBarLayer = [self currentEditingBarLayer];
	if (currentBarLayer != nil) {
		
		Sheet* sheet = sheetLayer.modelObject;
		NSArray* bars = sheet.bars;
		
		if ([bars count] > 1) {
			unsigned long position = [bars indexOfObject: currentBarLayer.modelObject];
			
			[sheetLayer removeBarAtPosition: (int) position];
			
			[self setEditingLayer: ((BarLayer*) [sheetLayer -> bars objectAtIndex: MIN ([bars count] - 1, position)]).openingBarLine];
			
		}
		
	}
	
}

- (BOOL) didChange {
	return didChange;
	
}

- (void) setDidChange: (BOOL) _didChange {
	didChange = _didChange;
	
}

- (void) checkIfTimeSignatureChanged {
	if ([editingLayer isKindOfClass: [TimeSignatureLayer class]]) {
		
		TimeSignature* timeSignature = (TimeSignature*) editingLayer.modelObject;
		
		if (timeSignatureBeforeEditing.numerator ==
			timeSignature.numerator)
			return;
		
		
		NSArray* bars = sheetLayer -> bars;
		int cursor = 0;
		
		do {
			BarLayer* barLayer = [bars objectAtIndex: cursor];
			if (barLayer.timeSignatureLayer == editingLayer)
				break;
			
			cursor++;
			
		} while (cursor < [bars count]);
		
		while (cursor < [bars count]) {
			BarLayer* barLayer = [bars objectAtIndex: cursor];
			
			if (barLayer.timeSignatureLayer &&
				barLayer.timeSignatureLayer != editingLayer)
				break;
			
			if (!barLayer -> isLocked) { 
				Bar* bar = (Bar*) barLayer.modelObject;
				[bar adaptForTimeSignature: timeSignature];
				[barLayer updateFromModelObject];
				
			}
			cursor++;
			
		};
		
		[sheetLayer linkAllElements];
		[sheetLayer updateLayout];
		
		[timeSignatureBeforeEditing release];
		timeSignatureBeforeEditing = nil;
		
	}
	
}

- (void) goForward {
	[self checkIfTimeSignatureChanged];
	
	ScalableLayer* lastLayer = editingIterator.currentLayer;
	
	if (isEditingAnnotation) {
		editingIterator.currentLayer =
			layerBeforeEnteringAnnotationEditingMode;
		
	} else {
		if (!editingIterator.currentLayer) {
			editingIterator.currentLayer = [self defaultFirstLayer];
			
		} else {
			(void) [editingIterator nextLayer];
			
		}
		
	}
	
	if (!editingIterator.currentLayer) {
		editingIterator.currentLayer = lastLayer;
		
		Bar* bar = [self newBarUsingCurrentTimeSignature];
		[sheetLayer appendBar: bar];
		[bar release];
		
		editingIterator.currentLayer =
			((BarLayer*) [sheetLayer -> bars lastObject]).openingBarLine;
		
	}
	
	[self setEditingLayer: editingIterator.currentLayer andCollapse: NO];
	
}

- (void) goBack {
	[self checkIfTimeSignatureChanged];
	
	if (isEditingAnnotation) {
		editingIterator.currentLayer =
			layerBeforeEnteringAnnotationEditingMode;
		
	} else
		(void) [editingIterator previousLayer];
	
	[self setEditingLayer: editingIterator.currentLayer andCollapse: NO];
	
}

- (Bar*) newBar {
	Bar* bar = [[Bar alloc] init];
	OpeningBarLine* openingBarLine = [[OpeningBarLine alloc] init];
	bar.openingBarLine = openingBarLine;
	[openingBarLine release];
	
	return bar;
	
}

- (Bar*) newBarUsingCurrentTimeSignature {
	Bar* bar = [self newBar];
	
	TimeSignature* currentTimeSignature = [self currentTimeSignature];
	if (currentTimeSignature)
		[bar adaptForTimeSignature: currentTimeSignature];
	
	return bar;
	
}

- (TimeSignature*) currentTimeSignatureFromLayer: (ScalableLayer*) location {
	
	if (!location)
		location = [self defaultFirstLayer];
	
	TimeSignature* currentTimeSignature = nil;
	LayerIterator* cursor = [LayerIterator new];
	cursor.currentLayer = location;
	
	if (!cursor.currentLayer) {
		NSArray* bars = sheetLayer -> bars;
		cursor.currentLayer = ((BarLayer*) [bars lastObject]).openingBarLine;
		
		if (!cursor.currentLayer.previousEditableElement)
			cursor.currentLayer = ((BarLayer*) [bars objectAtIndex: [bars count] - 2]).openingBarLine;
		
	}
	
	ScalableLayer* cursorLayer;
	while ((cursorLayer = [cursor previousLayer])) {
		if ([cursorLayer isKindOfClass: [TimeSignatureLayer class]]) {
			currentTimeSignature = cursorLayer.modelObject;
			break;
			
		}
		
	}
	[cursor release];
	
	return currentTimeSignature;
	
}

- (TimeSignature*) currentTimeSignature {
	return [self currentTimeSignatureFromLayer: editingIterator.currentLayer];
	
}

- (void) toggleCurrentTimeSignature: (BOOL) jumpBackIfSet {
	OpeningBarLineLayer* openingBarLineLayer;
	
	if ([editingLayer isKindOfClass: [OpeningBarLineLayer class]]) {
		openingBarLineLayer = (OpeningBarLineLayer*) editingLayer;
		
	} else  if ([editingLayer isKindOfClass: [TimeSignatureLayer class]]) {
		openingBarLineLayer = ((BarLayer*) editingLayer -> designatedSuperlayer).openingBarLine;
		
	} else {
        openingBarLineLayer = nil;
        
    }
	
	if (openingBarLineLayer == nil)
		return;
	
	
	OpeningBarLine* openingBarLine = openingBarLineLayer.modelObject;
	TimeSignature* timeSignature = openingBarLine.timeSignature;
	
	if (timeSignature && jumpBackIfSet) {
		[self goBack];
		return;
		
	}
	
	BarLayer* currentBarLayer = (BarLayer*) openingBarLineLayer -> designatedSuperlayer;
	BarLayer* previousBarLayer = nil;
	
	if (currentBarLayer == [sheetLayer -> bars objectAtIndex: 0]) {
		[self goBack];
		return;
		
	}
	
	BOOL didCreateTimeSignature = NO;
	
	if (timeSignature) {
		previousBarLayer =
			(BarLayer*) openingBarLineLayer.previousEditableElement.previousEditableElement -> designatedSuperlayer;
		
		openingBarLine.timeSignature = nil;
		timeSignature = [self currentTimeSignatureFromLayer: previousBarLayer.openingBarLine];
		
		NSArray* bars = sheetLayer -> bars;
		int cursor = 0;
		
		do {
			BarLayer* barLayer = [bars objectAtIndex: cursor];
			if (barLayer == currentBarLayer)
				break;
			
			cursor++;
			
		} while (cursor < [bars count]);
		
		do {
			BarLayer* barLayer = [bars objectAtIndex: cursor];
			
			if (((OpeningBarLine*) barLayer.openingBarLine.modelObject).timeSignature)
				break;
			
			if (!barLayer -> isLocked) { 
				Bar* bar = (Bar*) barLayer.modelObject;
				[bar adaptForTimeSignature: timeSignature];
				[barLayer updateFromModelObject];
				
			}
			cursor++;
			
		} while (cursor < [bars count]);
		
		[sheetLayer linkAllElements];
		[sheetLayer updateLayout];
		
	} else {
		previousBarLayer =
			(BarLayer*) openingBarLineLayer.previousEditableElement -> designatedSuperlayer;
		
		timeSignature = self.currentTimeSignature;
		openingBarLine.timeSignature = [[timeSignature copy] autorelease];
		
		didCreateTimeSignature = YES;
		
	}
	
	[openingBarLineLayer updateFromModelObject];
	[currentBarLayer updateFromModelObject];
	
	previousBarLayer.closingBarLine.barLineSymbol.hidden = NO;
	previousBarLayer.closingBarLine.barLineSymbol.opacity = 1.f;
	
	[sheetLayer linkAllElements];
	[sheetLayer updateLayout];
	
	if (didCreateTimeSignature)
		[self goBack];
	
}

- (void) enterAnnotationEditingMode {
	layerBeforeEnteringAnnotationEditingMode = editingIterator.currentLayer;
	
	BarLayer* barLayer = (BarLayer*) editingLayer.superlayer;
	AnnotationLayer* annotation = barLayer.annotation;
	
	Bar* bar = barLayer.modelObject;
	if (bar.openingBarLine.annotation) {
		[self setEditingLayer: annotation andCollapse: NO];
		
	} else {
		if (!bar.openingBarLine)
			bar.openingBarLine = [[[OpeningBarLine alloc] init] autorelease];
		
		bar.openingBarLine.annotation = @"New Annotation";
		[barLayer updateFromModelObject];
		[barLayer updateLayout];
		[sheetLayer updateLayout];
		
		annotation = barLayer.annotation;
		// NSLog (@"creating annotation %@", annotation);
		
		[self setEditingLayer: annotation andCollapse: NO];
		
	}
	
}

- (void) highlightCurrentLayerOverCursor: (ScalableLayer*) currentLayer {
	currentLayerOverCursor = currentLayer;
	
	if (self.isPlayingBack) {
		if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE])
			[currentLayer setColorScheme: SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE];
		else
			[currentLayer setColorScheme: SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE];
		
		[currentLayer setIsEmbossed: YES];
		
	} else {
		[currentLayer setColorScheme: colorScheme];
		
		[currentLayer setIsEmbossed: NO];
		
	}
	[sheetLayer updateRenderQueueState: NO];
	
}

- (void) unhighlightCurrentLayerOverCursor {
	if (currentLayerOverCursor != nil) {
		[currentLayerOverCursor setColorScheme: colorScheme];
		[currentLayerOverCursor setIsEmbossed: NO];
		currentLayerOverCursor = nil;
		
		[sheetLayer updateRenderQueueState: NO];
		
	}
	
}

- (void) placeCursorOver: (ScalableLayer*) currentLayer {
	[self unhighlightCurrentLayerOverCursor];
	
	CGRect bounds;
	
	 if (self.isPlayingBack) {
		bounds = [currentLayer concatenatedBoundsForPlayback];
		
		if ([currentLayer isKindOfClass: [ChordLayer class]]) {
			ChordLayer* currentChordLayer = (ChordLayer*) currentLayer;
			
			bounds.origin.x -= 0;
			bounds.size.width =
				currentChordLayer.shadowLayer.scaledPosition.x; // - 1 / scale;
			
		}
		
		ScalableLayer* leftLayer = currentLayer.previousEditableElement;
		if (leftLayer) {
			if ([leftLayer isKindOfClass: [ChordLayer class]]) {
				ChordLayer* leftChordLayer = (ChordLayer*) leftLayer;
				CGRect leftBounds = [leftChordLayer concatenatedBoundsForPlayback];
				
				double leftSeparatorPosition =
					leftBounds.origin.x +
					leftChordLayer.shadowLayer.scaledPosition.x;
				
				double leftSeparatorDelta = leftSeparatorPosition - bounds.origin.x;
				
				bounds.origin.x += leftSeparatorDelta;
				bounds.size.width -= leftSeparatorDelta;
				
			}
			
		}
		
		bounds.origin.y += 1;
		bounds.size.height -= 1;
		
	} else {
		bounds = [currentLayer concatenatedBoundsForEditor];
		
	}
	
	CursorLayer* cursor =  sheetLayer.cursor;
	
	if ([currentLayer isKindOfClass: [EditableTextLayer class]])
		bounds.size.width -= 2;
	
	[cursor snapToRect: bounds];
	
	[self highlightCurrentLayerOverCursor: currentLayer];
	
}

- (void) adjustCursorPosition {
	if (!editingLayer)
		return;
	
	[self placeCursorOver: editingLayer];
	
	if (!didEdit)
		[CATransaction setDisableActions: NO];
	
}

- (void) leaveAnnotationEditingMode {
	BarLayer* barLayer =
		(BarLayer*) layerBeforeEnteringAnnotationEditingMode.superlayer;
	
	if (!barLayer)
		barLayer = (BarLayer*) editingLayer -> designatedSuperlayer;
	
	Bar* bar = barLayer.modelObject;
	NSString* contentText = [inputField.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (![contentText length]) {
		bar.openingBarLine.annotation = nil;
		[barLayer updateFromModelObject];
		
		[sheetLayer markDirtyLayoutOfAllBars];
		[sheetLayer updateLayout];
		
	} else {
		bar.openingBarLine.annotation = contentText;
		
	}
	
	isEditingAnnotation = NO;
	
}

- (BOOL) isFirstElement: (id) element {
	if (!element)
		return YES;
	
	if ([element isKindOfClass: [TextModel class]]) {
		return [((TextModel*) element) isFirstElement];
		
	}
	return NO;
	
}

- (BOOL) isOnFirstBar {
	return editingLayer != nil &&
		editingLayer -> designatedSuperlayer == [self.sheetLayer -> bars objectAtIndex: 0];
	
}

- (KeySignature*) firstKeySignature {
	Sheet* sheet = self.sheetLayer.modelObject;
	NSArray* bars = sheet.bars;
	for (Bar* bar in bars) {
		OpeningBarLine* openingBarLine = bar.openingBarLine;
		if (openingBarLine) {
			KeySignature* keySignature = openingBarLine.keySignature;
			if (keySignature)
				return keySignature;
			
		}
		
	}
	return nil;
	
}

- (void) transposeFromBeginningUsingOriginalKeySignature: (KeySignature*) originalKeySignature targetKeySignature: (KeySignature*) targetKeySignature {
	
	LayerIterator* iterator = [[LayerIterator alloc] init];
	iterator.currentLayer = [self defaultFirstLayer];
	
	[self transposeWithIterator: iterator
		fromKeySignature: originalKeySignature
		toKeySignature: targetKeySignature
		transposeToEnd: YES];
	
	[iterator release];

	Sheet* sheet = self.sheetLayer.modelObject;
	NSArray* bars = sheet.bars;
	for (Bar* bar in bars) {
		OpeningBarLine* openingBarLine = bar.openingBarLine;
		if (openingBarLine) {
			openingBarLine.keySignature = targetKeySignature;
			break;
			
		}
		
	}
	
}

- (BOOL) keySignatureDoesChangeAfterCurrentPosition {
	BOOL didFindKeySignatureChange = NO;
	LayerIterator* signatureIterator = [editingIterator copy];
	
	ScalableLayer* currentLayer;
    
	while ((currentLayer = [signatureIterator nextLayer])) {
		if ([currentLayer isKindOfClass: [KeySignatureLayer class]]) {
			didFindKeySignatureChange = YES;
			break;
		}
	}
    
    [signatureIterator release];
	return didFindKeySignatureChange;
	
}

- (void) transposeFromCurrentPositionUsing: (KeySignature*) targetKeySignature originalKeySignature: (KeySignature*) originalKeySignature transposeToEnd: (BOOL) transposeToEnd {
	
	[self transposeWithIterator: editingIterator
		fromKeySignature: originalKeySignature
		toKeySignature: targetKeySignature
		transposeToEnd: transposeToEnd];
	
}

- (void) transposeWithIterator: (LayerIterator*) iterator fromKeySignature: (KeySignature*) originalKeySignature toKeySignature: (KeySignature*) targetKeySignature transposeToEnd: (BOOL) transposeToEnd {
	
	int keyValue = originalKeySignature.key.intValue;
	int targetKeyValue = targetKeySignature.key.intValue;
	
	int delta = targetKeyValue - keyValue;
	
	LayerIterator* transposeIterator = [iterator copy];
	
	int transposeCount = 1;
	ScalableLayer* currentLayer = transposeIterator.currentLayer;
	do {
		if ([currentLayer isKindOfClass: [KeySignatureLayer class]]) {
			if (transposeToEnd || transposeCount--) {
				KeySignature* currentKeySignature = currentLayer.modelObject;
				currentKeySignature.key.intValue =
					currentKeySignature.key.intValue + delta;
				
				[currentLayer updateFromModelObject];
				
			} else {
				break;
				
			}
			
		} else if ([currentLayer isKindOfClass: [ChordLayer class]]) {
			Chord* currentChord = currentLayer.modelObject;
			
			Key* currentKey = currentChord.key;
			currentKey.intValue = currentKey.intValue + delta;
			currentKey.stringValue = [currentKey stringValueForKeySignature: targetKeySignature];
			
			Key* currentBassKey = currentChord.bassKey;
			currentBassKey.intValue = currentBassKey.intValue + delta;
			currentBassKey.stringValue = [currentBassKey stringValueForKeySignature: targetKeySignature];
			
			[currentLayer updateFromModelObject];
			
		} else if ([currentLayer isKindOfClass: [ClosingBarLineLayer class]]) {
			BarLayer* barLayer = (BarLayer*) currentLayer.superlayer;
			[barLayer setNeedsUpdateLayout];
			
		}
		
	} while ((currentLayer = [transposeIterator nextLayer]));
	
	[sheetLayer updateLayout];
	[transposeIterator release];
	
}

- (void) changeKeyFromBeginningUsingOriginalKeySignature: (KeySignature*) originalKeySignature targetKeySignature: (KeySignature*) targetKeySignature {
	LayerIterator* iterator = [[LayerIterator alloc] init];
	iterator.currentLayer = [self defaultFirstLayer];
	
	[self changeKeyWithIterator: iterator
		fromKeySignature: originalKeySignature
		toKeySignature: targetKeySignature
		changeKeyToEnd: YES];
	
	[iterator release];
	
	Sheet* sheet = self.sheetLayer.modelObject;
	NSArray* bars = sheet.bars;
	for (Bar* bar in bars) {
		OpeningBarLine* openingBarLine = bar.openingBarLine;
		if (openingBarLine) {
			openingBarLine.keySignature = targetKeySignature;
			break;
			
		}
		
	}
	
}

- (void) changeKeyWithIterator: (LayerIterator*) iterator fromKeySignature: (KeySignature*) originalKeySignature toKeySignature: (KeySignature*) targetKeySignature changeKeyToEnd: (BOOL) changeKeyToEnd {
	
	int keyValue = originalKeySignature.key.intValue;
	int targetKeyValue = targetKeySignature.key.intValue;
	
	int delta = targetKeyValue - keyValue;
	
	LayerIterator* transposeIterator = [iterator copy];
	
	int transposeCount = 1;
	ScalableLayer* currentLayer = transposeIterator.currentLayer;
	do {
		if ([currentLayer isKindOfClass: [KeySignatureLayer class]]) {
			if (changeKeyToEnd || transposeCount--) {
				KeySignature* currentKeySignature = currentLayer.modelObject;
				currentKeySignature.key.intValue =
					currentKeySignature.key.intValue + delta;
				
				[currentLayer updateFromModelObject];
				
			} else {
				break;
				
			}
			
		} else if ([currentLayer isKindOfClass: [ClosingBarLineLayer class]]) {
			BarLayer* barLayer = (BarLayer*) currentLayer.superlayer;
			[barLayer setNeedsUpdateLayout];
			
		}
		
	} while ((currentLayer = [transposeIterator nextLayer]));
	
	[sheetLayer updateLayout];
	[transposeIterator release];
	
}

@end


@implementation SheetView (AudioPlayback)


- (void) playChord: (Chord*) chord {
	[chordPlayer playChord: chord];
	
}

- (void) scheduleProcessChordAfterDelay: (double) delay {
	[lastScheduledPlaybackDate release];
	lastScheduledPlaybackDate = [[NSDate alloc] init];
	
	[playbackTimer release];
	
	playbackTimer = [[NSTimer
		scheduledTimerWithTimeInterval: delay
		target: self
		selector: @selector (processPlayback)
		userInfo: nil
		repeats: NO] retain];
	
	// NSLog (@"---- scheduled playback %@ ----", playbackTimer);
	
}

- (void) processPlayback {
	// NSLog (@"-- process playback --");
	
	if ([playbackSequence hasNextStep]) {
		PlaybackSequenceStep* step = [playbackSequence nextStep];
		
		// NSLog(@"step %@", step);
		//NSLog(@"sequence count %i", [playbackSequence -> sequence count]);
		
		BarLayer* currentBarLayer =
			[sheetLayer -> bars objectAtIndex: step -> barIndex];
		ScalableLayer* currentLayer;
		
		if (step -> chordIndex >= 0)
			currentLayer = [currentBarLayer.chords objectAtIndex: step -> chordIndex];
		else
			currentLayer = currentBarLayer.openingBarLine;
		
		
		[self setUpZoom: currentLayer];
		
		[self presentCursor: YES];
		[self placeCursorOver: currentLayer];
		
		[self playChord: step -> chord];
		
		[self scheduleProcessChordAfterDelay: step -> duration / self.tempo * 60];
		
	} else {
		[self stopPlayback];
		
	}
	
}

- (void) startPlaybackFromCurrentElement {
	// NSLog (@"-- start playback --");
	
	if (DRAW_AS_BANNER_WHEN_PLAYING_BACK) {
		sheetLayer -> layoutMode = SHEET_LAYOUT_MODE_BANNER;
		[sheetLayer updateLayout];
		
	}
	
	Sheet* sheet = self.sheetLayer.modelObject;
	
	if (playbackSequence)
		[playbackSequence release];
	playbackSequence = [[PlaybackSequence alloc] init];
	[playbackSequence buildFromSheet: sheet];
	
	BOOL canPlayEditingLayer = editingLayer != nil;
	
	if (canPlayEditingLayer)
		[playbackSequence advanceToChord: editingLayer.modelObject];
	
	if (playbackTimer)
		[playbackTimer invalidate];
	
	if (canPlayEditingLayer) {
		[self scheduleProcessChordAfterDelay: .0f];
		// [self processPlayback];
		
	} else {
		[self scheduleProcessChordAfterDelay: .5f];
		ScalableLayer* firstLayer =
			(OpeningBarLineLayer*) [[sheetLayer -> bars objectAtIndex: 0] openingBarLine];
		[self setUpZoom: firstLayer];
		
	}
	
	if (editingDelegate)
		[editingDelegate beginPlayback];
	
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	
	sheetScrollView.panGestureRecognizer.enabled = NO;
	sheetScrollView.pinchGestureRecognizer.enabled = NO;
	sheetScrollView.scrollsToTop = NO;
	
}

- (BOOL) isPlayingBack {
	return playbackTimer != nil;
	
}

- (void) pausedPlaybackSoundMixer: (id) sender {
	[self stopPlayback];
	
}

- (void) stopPlaybackAndCenterContent: (BOOL) doCenterContent {
	if (!editingDelegate)
		return;
	
	// NSLog (@"-- stop playback --");
	
	if (DRAW_AS_BANNER_WHEN_PLAYING_BACK) {
		sheetLayer -> layoutMode = SHEET_LAYOUT_MODE_SHEET;
		[sheetLayer updateLayout];
		
	}
	
	if (doCenterContent)
		[sheetLayer.sheetScrollView centerContentAnimated: YES];
	
	[playbackTimer invalidate];
	[playbackTimer release];
	playbackTimer = nil;
	
	[lastScheduledPlaybackDate release];
	lastScheduledPlaybackDate = nil;
	
	if (!self.isEditing)
		[self presentCursor: NO];
	
	if (editingDelegate)
		[editingDelegate endPlayback];
	
	SheetScrollView* sheetScrollView = self.sheetLayer.sheetScrollView;
	
	[sheetScrollView enableGestureRecognizers: YES];
	sheetScrollView.panGestureRecognizer.enabled = YES;
	sheetScrollView.pinchGestureRecognizer.enabled = YES;
	sheetScrollView.scrollsToTop = YES;
	
}

- (void) stopPlayback {
	[self stopPlaybackAndCenterContent: YES];
	
}


- (float) tempo {
	return ((Sheet*) sheetLayer.modelObject).tempo;
	
}

- (void) setTempo: (float) tempo {
	float lastTempo = self.tempo;
	((Sheet*) sheetLayer.modelObject).tempo = tempo;
	
	if (lastScheduledPlaybackDate) { // should really use host time instead
		NSDate* lastProcessDate = [NSDate
			dateWithTimeInterval: 1 / lastTempo sinceDate: lastScheduledPlaybackDate];
		NSDate* processDate = [NSDate
			dateWithTimeInterval: 1 / tempo sinceDate: lastScheduledPlaybackDate];
		
		double delta = [processDate timeIntervalSinceDate: lastProcessDate];
		
		if (delta <= 0)
			[self processPlayback];
		else
			[self scheduleProcessChordAfterDelay: delta];
		
	}
	
}

@end
