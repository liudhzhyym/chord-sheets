//
//  SheetScrollView.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>

#import "SheetView.h"
#import "SheetLayer.h"

#import "ParserContext.h"


#define MIN_SCALE .25f
// #define MIN_SCALE 1.f

#define MAX_SCALE 5.f


extern CGPoint renderQueueCenter;


extern NSString *SHEET_COLOR_SCHEME_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_NEGATIVE;

extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE;


extern CGRect currentViewRect;

@class Sheet;

@interface SheetScrollView : UIScrollView <UIScrollViewDelegate> {	
	
	@public
	
	CGSize originalContentSize;
	
	UIEdgeInsets currentInsets;
	
	BOOL needsCenteringOnLayout;
	
	BOOL canLeaveToLeft;
	BOOL canLeaveToRight;
	
	@protected
	
	SheetView* sheetView;
	Sheet* sheet;
	
	UITapGestureRecognizer* tapRecognizer;
	UITapGestureRecognizer* doubleTapRecognizer;
	
	float keyboardSpace;
	
	
	NSString* colorScheme;
	
	@private
	
	int leavingDirection;
	
	BOOL lockSwipeAfterEditing;
	int lockedSwipingDirection;
	
}

@property (readonly) SheetView* sheetView;
@property (readonly) SheetLayer* sheetLayer;
@property (nonatomic, readwrite, retain) Sheet* sheet;

@property (readwrite, retain) NSString* colorScheme;

@property (readwrite) float keyboardSpace;

- (void) reset;

- (void) updateContentSize;
- (CGRect) currentViewRect;

- (void) enableGestureRecognizers: (BOOL) doEnable;

- (void) expandInset;
- (void) centerContentAnimated: (BOOL) animated clampToZero: (BOOL) clamp;
- (void) centerContentAnimated: (BOOL) animated;

- (void) updateBackgroundForOrientation: (UIInterfaceOrientation) orientation;

@end
