//
//  SheetLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "ParserContext.h"

#import "ScalableLayer.h"

#import "TextLayer.h"
#import "TitleLayer.h"
#import "CopyrightLayer.h"

#import "CursorLayer.h"


#define DRAW_AS_BANNER_WHEN_PLAYING_BACK NO


extern NSString* SHEET_LAYOUT_MODE_SHEET;
extern NSString* SHEET_LAYOUT_MODE_BANNER;


@class SheetScrollView;
@class Bar;

@interface SheetLayer : ScalableLayer {
	
	@public
	
	NSMutableArray* bars;
	NSMutableArray* barRows;
	
	CGSize contentSize;
	
	CALayer* cursorContainer;
	CALayer* barRowContainer;
	CALayer* shadowLayer;
	
	NSString* layoutMode;
	
	float printingLayoutWidth;
	
	@protected
	
	SheetScrollView* sheetScrollView;
	
	NSMutableDictionary* sheetProperties;
	
	TitleLayer* title;
	EditableTextLayer* copyright;
	
	CGSize lastContentSize;
	
	CursorLayer* cursorLayer;
	
	BOOL isFirstLayout;
	
	@private	
	
	CALayer *shadowTL, *shadowT, *shadowTR,
		*shadowL, *shadowR,
		*shadowBL, *shadowB, *shadowBR;
	
	CALayer* staticLayer;
	
}

@property (readonly) CALayer* staticLayer;

@property (readonly) TitleLayer* title;

@property (readwrite, assign) SheetScrollView* sheetScrollView;

@property (readonly) CGSize contentSize;

- (void) appendBar: (Bar*) bar;

- (void) insertBar: (Bar*) bar atPosition: (int) position;
- (void) removeBarAtPosition: (int) position;
- (void) clearBarAtPosition: (int) position;


- (void) markDirtyLayoutOfAllBars;
- (void) updateLayout;

@property (readonly) CursorLayer* cursor;

- (void) linkAllElements;

- (void) cleanUpEmptyBars;

- (void) onQueueRendered: (RenderQueue*) renderQueue;

- (void) renderStaticInBackground: (BOOL) background;

void linkElements (ScalableLayer* element, ScalableLayer* nextElement);

@end
