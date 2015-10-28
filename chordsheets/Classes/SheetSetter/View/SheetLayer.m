//
//  SheetLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Sheet.h"
#import "Bar.h"
#import "Chord.h"

#import "SheetLayer.h"

#import "SheetScrollView.h"
#import "BarLayer.h"
#import "ClosingBarLineLayer.h"
#import "ChordLayer.h"

#import "TextLayer.h"
#import "BoundedBitmapLayer.h"

#import "TileRenderJob.h"


#define MAX_BARS_PER_ROW 4


#define MARGIN_TOP 10
#define MARGIN_RIGHT 10
#define MARGIN_BOTTOM 14
#define MARGIN_LEFT 15


NSString* SHEET_LAYOUT_MODE_SHEET = @"sheet";
NSString* SHEET_LAYOUT_MODE_BANNER = @"banner";


@interface BarRowDescription : NSObject {
	
	@public
	
	BOOL containsKeyOrTimeSignature;
	
	int numBars;
	BarLayer** barLayers;
	float fullWidth;
	float* barWidths;
	float fullSpacing;
	float* barSpacings;
	
}

@end

@implementation BarRowDescription

- (id) initWithCapacity: (unsigned int) capacity {
	if (self = [super init]) {
		barLayers = malloc (sizeof (BarLayer*) * capacity);
		memset (barLayers, 0, sizeof (BarLayer*) * capacity);
		
		barWidths = malloc (sizeof (float) * capacity);
		memset (barWidths, 0, sizeof (float) * capacity);
		
		barSpacings = malloc (sizeof (float) * capacity);
		memset (barSpacings, 0, sizeof (float) * capacity);
		
	}
	return self;
	
}

- (void) dealloc {
	free (barLayers);
	free (barWidths);
	free (barSpacings);
	
	[super dealloc];
	
}

@end


@interface SheetLayer (Private)

- (void) linkAllElements;

@end


@implementation SheetLayer

- (id) init {
	
	if ((self = [super init])) {
		self.anchorPoint = CGPointMake (0, 0);
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.opaque = YES;
		
		
		barRowContainer = [[CALayer layer] retain];
		barRowContainer.name = @"barRowContainer";
		barRowContainer.anchorPoint = CGPointMake (0, 0);
		barRowContainer.opaque = YES;
		
		cursorContainer = [CALayer layer];
		cursorContainer.name = @"cursorContainer";
		[self addSublayer: cursorContainer];
		
		cursorLayer = [CursorLayer layer];
		cursorLayer.name = @"cursorLayer";
		cursorLayer.hidden = YES;
		[cursorContainer addSublayer: cursorLayer];
		[scalableSublayers addObject: cursorLayer];
		cursorLayer -> persistentParent = cursorContainer;
		
		bars = [[NSMutableArray alloc] init];
		barRows = [[NSMutableArray alloc] init];
		
		sheetProperties = [[NSMutableDictionary alloc] init];
		
		title = [[TitleLayer layer] retain];
		title.scaledPosition = CGPointMake (MARGIN_LEFT, MARGIN_TOP);
		[self addSublayer: title];
		
		copyright = [[CopyrightLayer layer] retain];
		copyright -> editorYPadding = 3;
		copyright.label = @"Editor";
		
		copyright.fontName = @"Helvetica";
		copyright.fontSize = 10;
		copyright -> lockFontColor = YES;
		
		copyright.isEditable = YES;
		[self addSublayer: copyright];
		
		shadowLayer = [[CALayer layer] retain];
		shadowLayer.name = @"shadowLayer";
		[shadowLayer retain];
		
		CALayer* backingLayer = shadowLayer;
		backingLayer.opacity = .85f;
		
		UIImage* shadowImage;
		
#define CREATE_SHADOW(instance, fileName) \
		instance = [CALayer layer]; \
		instance.anchorPoint = CGPointMake (0, 0); \
		shadowImage = [UIImage imageNamed: fileName]; \
		instance.contents = (id) shadowImage.CGImage; \
		instance.bounds = \
			CGRectMake (0, 0, shadowImage.size.width, shadowImage.size.height); \
		[backingLayer addSublayer: instance];
		
		CREATE_SHADOW(shadowTL, @"Shadow_TL.png");
		CREATE_SHADOW(shadowT, @"Shadow_T.png");
		CREATE_SHADOW(shadowTR, @"Shadow_TR.png");
		CREATE_SHADOW(shadowL, @"Shadow_L.png");
		CREATE_SHADOW(shadowR, @"Shadow_R.png");
		CREATE_SHADOW(shadowBL, @"Shadow_BL.png");
		CREATE_SHADOW(shadowB, @"Shadow_B.png");
		CREATE_SHADOW(shadowBR, @"Shadow_BR.png");
		
		staticLayer = [[CALayer alloc] init];
		staticLayer.actions = [ScalableLayer layoutActions];
		staticLayer.anchorPoint = CGPointMake (0, 0);
		
		layoutMode = SHEET_LAYOUT_MODE_SHEET;
		isFirstLayout = YES;
		
	}
	return self;
	
}

extern BOOL isDragging, isZooming, isAnimating;

- (void) drawShadowAroundRect: (CGRect) rect {
	
	BOOL disableActions = [CATransaction disableActions];
	
	if (false && isAnimating) {
		if (disableActions)
			[CATransaction setDisableActions: NO];
		
	} else {
		if (!disableActions)
			[CATransaction setDisableActions: YES];
		
	}
	CGSize shadowSize;
	shadowSize = shadowTL.bounds.size;
	shadowTL.frame = CGRectMake (
		-shadowSize.width, -shadowSize.height,
		shadowSize.width, shadowSize.height
		
	);
	shadowSize = shadowT.bounds.size;
	shadowT.frame = CGRectMake (
		0, -shadowSize.height,
		rect.size.width, shadowSize.height
		
	);
	shadowSize = shadowTR.bounds.size;
	shadowTR.frame = CGRectMake (
		rect.size.width, -shadowSize.height,
		shadowSize.width, shadowSize.height
		
	);

	shadowSize = shadowL.bounds.size;
	shadowL.frame = CGRectMake (
		-shadowSize.width, 0,
		shadowSize.width, rect.size.height
		
	);
	shadowSize = shadowR.bounds.size;
	shadowR.frame = CGRectMake (
		rect.size.width, 0,
		shadowSize.width, rect.size.height
		
	);

	shadowSize = shadowBL.bounds.size;
	shadowBL.frame = CGRectMake (
		-shadowSize.width, rect.size.height,
		shadowSize.width, shadowSize.height
		
	);
	shadowSize = shadowB.bounds.size;
	shadowB.frame = CGRectMake (
		0, rect.size.height,
		rect.size.width, shadowSize.height
		
	);
	shadowSize = shadowBR.bounds.size;
	shadowBR.frame = CGRectMake (
		rect.size.width, rect.size.height,
		shadowSize.width, shadowSize.height
		
	);
	
	if (false && isAnimating) {
		if (disableActions)
			[CATransaction setDisableActions: YES];
		
	} else {
		if (!disableActions)
			[CATransaction setDisableActions: NO];
	
	}
	
}

- (CursorLayer*) cursor {
	return cursorLayer;
	
}

extern NSString* SHEET_COLOR_SCHEME_PRINT;

extern CGColorRef placeholderColour;

- (void) setColorScheme: (NSString*) _colorScheme {
	[super setColorScheme: _colorScheme];
	
	[barRowContainer setBackgroundColor: [SheetView backgroundColorForScheme: _colorScheme].CGColor];
	
	BOOL isPositive = [colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE];
	BOOL isPrint = [colorScheme isEqualToString: SHEET_COLOR_SCHEME_PRINT];
	
	float copyrightShade = isPrint ? 0 : isPositive ? .4f : .55f;
	copyright -> fontColor [0] = copyrightShade;
	copyright -> fontColor [1] = copyrightShade;
	copyright -> fontColor [2] = copyrightShade;
	
	float titleShade = isPrint || isPositive ? 0. : .7f;
	
	title.title -> fontColor [0] = titleShade;
	title.title -> fontColor [1] = titleShade;
	title.title -> fontColor [2] = titleShade;
	
	title.artist -> fontColor [0] = titleShade;
	title.artist -> fontColor [1] = titleShade;
	title.artist -> fontColor [2] = titleShade;	
	
	
	if (placeholderColour)
		CGColorRelease (placeholderColour);
	
	if (isPositive)
		placeholderColour =
			[UIColor colorWithRed: .8f green: .8f blue: .8f alpha: 1.f].CGColor;	
	else
		placeholderColour =
			[UIColor colorWithRed: .3f green: .3f blue: .3f alpha: 1.f].CGColor;
	
	CGColorRetain (placeholderColour);
	
}

- (void) drawInContext: (CGContextRef) context {
	
}

@synthesize sheetScrollView;

@synthesize title;

- (RenderQueue*) renderQueue {
	if (!renderQueue) {
		renderQueue = [[RenderQueue alloc] init];
		
		// [renderQueue addListener: self selector: @selector (onQueueRendered:) forEvent: @"queueRendered"];
		
	}
	return renderQueue;
	
}

- (void) onQueueRendered: (RenderQueue*) renderQueue {
	// NSLog (@"--- rendered");
	
	// [self renderStaticInBackground: YES];
	
}

- (TileRenderQueue*) tileRenderQueue {
	if (RENDER_IN_BACKGROUND_THREAD) {
		if (!tileRenderQueue)
			tileRenderQueue = [[TileRenderQueue alloc] init];
		
		return tileRenderQueue;
		
	} else {
		return nil;
		
	}
	
}

- (void) setScale: (float) _scale {
	[[self renderQueue] flushQueue];
	[[self tileRenderQueue] flushQueue];
	
/*	
	if (self.shouldRasterize) {
		if (scale >= 1)
			self.shouldRasterize = NO;
		
	} else {
		if (scale < 1)
			self.shouldRasterize = YES;
		
	}
*/	
	
	[super setScale: _scale];
	
	[CATransaction setDisableActions: YES];
	
}

//

- (void) setModelObject: (Sheet*) sheet {
	[super setModelObject: sheet];
	
	[title setTitleText: sheet.title];
	[title setArtistText: sheet.artist];
	
	copyright.text = [NSString
		stringWithFormat: @"edited by %@", sheet.copyright];
	
	TimeSignature* currentTimesignature = nil;
	
	int skipCount = 0;
	Bar* lastBar = [sheet.bars lastObject];
	for (Bar* bar in sheet.bars) {
		
		TimeSignature* timeSignature = bar.openingBarLine.timeSignature;
		if (timeSignature)
			currentTimesignature = timeSignature;
		
		NSString* barMark = bar.openingBarLine.barMark;
		if (barMark) {
			if ([barMark isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE])
				skipCount = 2;
			else
				skipCount = 1;
			
		}
		
		BarLayer* barLayer = [BarLayer layer];
		
		if (skipCount) {
			barLayer -> isLocked = YES;
			skipCount--;
			
		} else {
			if (currentTimesignature)
				[bar adaptForTimeSignature: currentTimesignature];
			
		}
		
		[bars addObject: barLayer];
		[self addSublayer: barLayer];
		
		if (bar == lastBar)
			barLayer -> isLastInSheet = YES;
		barLayer.modelObject = bar;
		
	}
	
	[self linkAllElements];
	[self updateLayout];
	// [self renderImmediately];
	
	SheetScrollView* scrollView = self.sheetScrollView;
	[scrollView flashScrollIndicators];
	
}

void linkElements (ScalableLayer* element, ScalableLayer* nextElement) {
	element.nextEditableElement = nextElement;
	nextElement.previousEditableElement = element;
	
}

- (void) linkAllElements {
	NSMutableArray* elements = [NSMutableArray arrayWithObjects:
		title.title,
		title.artist,
		// copyright,
		nil
		
	];
	
	BarLayer* barLayer = nil;
	int skipCount = 0;
	for (barLayer in bars) {
		Bar* bar = nil;
		
		bar = barLayer.modelObject;
		if (DISPLAYS_KEY_SIGNATURES && bar.openingBarLine.keySignature)
			[elements addObject: barLayer.keySignatureLayer];
		if (bar.openingBarLine.timeSignature)
			[elements addObject: barLayer.timeSignatureLayer];
		
		if (!skipCount)
			[elements addObject: barLayer.openingBarLine];
		
		OpeningBarLine* openingBarLine = bar.openingBarLine;
		NSString* barMarkKey = openingBarLine.barMark;
		if (barMarkKey) {
			if ([barMarkKey isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE])
				skipCount = 2;
			else
				skipCount = 1;
			
		}
		if (skipCount) {
			skipCount--;
			
		} else {
			NSArray* chords = barLayer.chords;
			for (ChordLayer* chordLayer in chords)
				[elements addObject: chordLayer];
			
		}
		
		if (!skipCount)
			[elements addObject: barLayer.closingBarLine];
		
		barLayer -> isLastInSheet = NO;
		
	}
	barLayer = [bars lastObject];
	if (barLayer)
		barLayer -> isLastInSheet = YES;
	
	
	ScalableLayer* lastLayer = nil;
	for (ScalableLayer* layer in elements) {
		if (lastLayer)
			linkElements (lastLayer, layer);
		
		lastLayer = layer;
		
	}
	
}

- (void) appendBar: (Bar*) bar {
	BarLayer* lastBarLayer = [bars lastObject];
	lastBarLayer -> isLastInSheet = NO;
	[lastBarLayer.closingBarLine updateFromModelObject];
	
	BarLayer* barLayer = [BarLayer layer];
	barLayer -> isLastInSheet = YES;	
	[bars addObject: barLayer];
	[self addSublayer: barLayer];
	
	barLayer.modelObject = bar;
	
	Sheet* sheet = modelObject;
	[sheet -> bars addObject: bar];
	
	[self linkAllElements];
	[self updateLayout];
	[self updateLayerVisibilityInRect: [sheetScrollView currentViewRect]];
	
}

- (void) insertBar: (Bar*) bar atPosition: (int) position {
	BarLayer* barLayer = [BarLayer layer];
	[bars insertObject: barLayer atIndex: position];
	[self addSublayer: barLayer];
	
	barLayer.modelObject = bar;
	
	Sheet* sheet = modelObject;
	[sheet -> bars insertObject: bar atIndex: position];
	
	[self linkAllElements];
	[self updateLayout];
	[self updateLayerVisibilityInRect: [sheetScrollView currentViewRect]];
	
}

- (void) removeBarAtPosition: (int) position {
	NSLog (@"remove bar at position %i", position);
	
	BarLayer* barLayer = [bars objectAtIndex: position];
	Bar* bar = barLayer.modelObject;
	
	TimeSignature* timeSignature = bar.openingBarLine.timeSignature;
	if (timeSignature != nil)
		[timeSignature retain];

	KeySignature* keySignature = bar.openingBarLine.keySignature;
	if (keySignature != nil)
		[keySignature retain];
	
	[bar clear];
	[barLayer updateFromModelObject];
	
	[barLayer removeFromSuperlayer];
	
	[scalableSublayers removeObject: barLayer];
	[bars removeObjectAtIndex: position];
	
	Sheet* sheet = modelObject;
	[sheet -> bars removeObjectAtIndex: position];
	
	if (timeSignature != nil || keySignature != nil) {
		barLayer = [bars objectAtIndex: position];
		bar = barLayer.modelObject;
		
		OpeningBarLine* openingBarLine = bar.openingBarLine;
		if (openingBarLine == nil) {
			openingBarLine = bar.openingBarLine =
				[[[OpeningBarLine alloc] init] autorelease];
			
		}
		if (timeSignature != nil) {
			if (openingBarLine.timeSignature == nil)
				openingBarLine.timeSignature = timeSignature;
			
			[timeSignature release];
			
		}
		
		if (keySignature != nil) {
			if (openingBarLine.keySignature == nil)
				openingBarLine.keySignature = keySignature;
			
			[keySignature release];
			
		}
		[barLayer updateFromModelObject];
		
	}
	
	[self linkAllElements];
	[self updateLayout];
	[self updateLayerVisibilityInRect: [sheetScrollView currentViewRect]];
	
}

- (void) clearBarAtPosition: (int) position {
	BarLayer* barLayer = [bars objectAtIndex: position];
	Bar* bar = barLayer.modelObject;
	
	[bar clear];
	[barLayer updateFromModelObject];
	
	[self updateLayout];
	[self updateLayerVisibilityInRect: [sheetScrollView currentViewRect]];
	
}


- (void) cleanUpEmptyBars {
	BOOL didCleanUp = NO;
	
	Sheet* sheet = modelObject;
	NSMutableArray* barModels = sheet -> bars;
	
	NSMutableArray* barLayers = self -> bars;
	
	BarLayer* lastBarLayer = nil;
	for (int i = (int) [barLayers count]; i--;) {
		if ([barLayers count] <= 4)
			break;
		
		BarLayer* barLayer = [barLayers objectAtIndex: i];
		Bar* barModel = barLayer.modelObject;
		if ((!barModel.openingBarLine || [barModel.openingBarLine isDefault]) &&
			(!barModel.closingBarLine || [barModel.closingBarLine isDefault])) {
			
			BOOL hasChords = NO;
			for (Chord* chord in barModel.chords) {
				if (chord.key) {
					hasChords = YES;
					break;
					
				}
				
			}
			
			if (!hasChords && !barLayer -> isLocked) {
				didCleanUp = YES;
				
				lastBarLayer = 
					(BarLayer*) barLayer.openingBarLine.previousEditableElement.designatedSuperlayer;
				lastBarLayer.closingBarLine.nextEditableElement = nil;
				
				if (barLayer.superlayer)
					[barLayer removeFromSuperlayer];
				
				[barModels removeObject: barModel];
				[barLayers removeObject: barLayer];
				[scalableSublayers removeObject: barLayer];
				
			} else {
				break;
				
			}
			
		} else {
			break;
			
		}
		
	}
	if (lastBarLayer) {
		lastBarLayer -> isLastInSheet = YES;
		[lastBarLayer.closingBarLine updateFromModelObject];
		lastBarLayer.closingBarLine.barLineSymbol.hidden = NO;
		
	}
	if (didCleanUp) {
		[self linkAllElements];
		[self updateLayout];
		[self updateLayerVisibilityInRect: [sheetScrollView currentViewRect]];
		
	}
	
}

//

- (void) markDirtyLayoutOfAllBars {
	for (BarLayer* bar in bars)
		bar -> needsUpdateLayout = YES;
	
}

- (void) updateLayout {
	if (sheetScrollView.zooming)
		return;

	
	didRenderStatic = NO;
	didPreRenderStatic = NO;
	
	staticLayer.sublayers = nil;
	
	const float LEFT_BAR_OFFSET = 0;
	const float TOP_BAR_OFFSET = 72 - 7;
	
	double maxLineWidth = 0.f;
	float maxLineHeight = 0.f;
	CGPoint cursor = CGPointMake (
		LEFT_BAR_OFFSET + MARGIN_LEFT,
		TOP_BAR_OFFSET + MARGIN_TOP
		
	);
	
#define BAR_SPACING 0
	
	int barsInLine = 0;
	BarLayer* leftBar = nil;
	
	float annotationWidth = 0;
	
	BOOL isPrinting = [colorScheme isEqualToString: SHEET_COLOR_SCHEME_PRINT];
	BOOL drawPositive =
		[colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE] ||
		isPrinting;
	
	BOOL drawAsSheet = !DRAW_AS_BANNER_WHEN_PLAYING_BACK ||
		[layoutMode isEqualToString: SHEET_LAYOUT_MODE_SHEET];
	NSInteger numBarsInRow = drawAsSheet ? MAX_BARS_PER_ROW : [bars count];
	
	NSMutableArray* barRowDescriptions = [[NSMutableArray alloc] initWithCapacity: numBarsInRow];
	BarRowDescription* currentBarRowDescription = nil;
	
	int barRowIndex = 0;
	BoundedBitmapLayer* barRowBackground = nil;
	for (int i = 0; i < [bars count]; i++) {
		BarLayer* bar = [bars objectAtIndex: i];
		
		[bar updateLayout];
		bar.scaledPosition = CGPointMake (cursor.x, cursor.y);
		
		if (leftBar) {
			float barOffset = [BarLayer offsetForBetweenLeft: leftBar right: bar];
			cursor.x += barOffset;
			currentBarRowDescription -> fullSpacing -= barOffset;
			currentBarRowDescription -> barSpacings [barsInLine - 1] = -barOffset; // barOffset;
			
		}
		bar.scaledPosition = CGPointMake (cursor.x, cursor.y); // testY += 5);
		
		maxLineHeight = fmaxf (maxLineHeight, bar.height);
		
		if (!currentBarRowDescription) {
			currentBarRowDescription = [[BarRowDescription alloc] initWithCapacity: (int) numBarsInRow];
			
			[barRowDescriptions addObject: currentBarRowDescription];
			[currentBarRowDescription release];
			
		}
		
		Bar* barModel = (Bar*) bar.modelObject;
		
		BOOL barIsLastInLine;
		
		if (i == [bars count] - 1)
			barIsLastInLine = YES;
		else if (drawAsSheet &&
			(barsInLine == numBarsInRow - 1 ||
			((Bar*) bar.modelObject).closingBarLine.wrapsAfterBar))
			barIsLastInLine = YES;
		else
			barIsLastInLine = NO;
		
		bar -> isLastInLine = barIsLastInLine;
		if (barIsLastInLine) {
			bar.closingBarLine.barLineSymbol.opacity = 1;
			bar.closingBarLine.barLineSymbol.hidden = NO;
			
		}
		
		BOOL doHideOpeningBarLine = NO;
		BOOL doHideClosingBarLine = NO;
		
		BOOL containsKeyOrTimeSignature =
			barModel.openingBarLine.timeSignature || barModel.openingBarLine.keySignature;
		currentBarRowDescription -> containsKeyOrTimeSignature |= containsKeyOrTimeSignature;
		
		if (leftBar && !containsKeyOrTimeSignature) {
			ClosingBarLine* closingBarLineModel = ((Bar*) leftBar.modelObject).closingBarLine;
			OpeningBarLine* openingBarLineModel = barModel.openingBarLine;
			
			if (!leftBar -> isLastInLine && !leftBar -> isLastInSheet &&
				(!closingBarLineModel || !closingBarLineModel.type ||
				[closingBarLineModel.type isEqualToString: BAR_LINE_TYPE_SINGLE]))
				doHideClosingBarLine = YES;
			
			leftBar.closingBarLine.barLineSymbol.hidden = doHideClosingBarLine;
			
			if (!doHideClosingBarLine &&
				(!openingBarLineModel || !openingBarLineModel.type ||
				[openingBarLineModel.type isEqualToString: BAR_LINE_TYPE_SINGLE]) &&
				!openingBarLineModel.repeatCount)
				doHideOpeningBarLine = YES;
			
		}
		bar.openingBarLine.barLineSymbol.hidden = doHideOpeningBarLine;
		
		float barWidth = bar.widthIncludingAnnotation;
		
		currentBarRowDescription -> barLayers [barsInLine] = bar;
		currentBarRowDescription -> barWidths [barsInLine] = barWidth;
		currentBarRowDescription -> fullWidth += barWidth;
		currentBarRowDescription -> numBars++;
		
		barsInLine++;
		
		if (barIsLastInLine) {
			if (barRowIndex < [barRows count]) {
				barRowBackground = [barRows objectAtIndex: barRowIndex];
				
			} else {
				barRowBackground = [BoundedBitmapLayer layer];
				barRowBackground.opaque = YES;
				
				if (drawPositive)
					[barRowBackground loadBundleImage: @"BarRowBackground.png"];
				else
					[barRowBackground loadBundleImage: @"BarRowBackground_negative.png"];
				
				[barRowContainer addSublayer: barRowBackground];
				[scalableSublayers addObject: barRowBackground];
				barRowBackground -> persistentParent = barRowContainer;
				barRowBackground -> forceUpdateVisibility = NO;
				
				[barRows addObject: barRowBackground];
				
			}
			barRowIndex++;
			
			barRowBackground.scaledPosition = CGPointMake ((MARGIN_LEFT + LEFT_BAR_OFFSET) - 5, cursor.y - 6 + 1);
			barRowBackground.scale = self.scale;
			
			currentBarRowDescription -> barSpacings [barsInLine - 1] += 9;
			
			barsInLine = 0;
			
			bar -> isLastInLine = YES;
			
			cursor.x += barWidth;
			maxLineWidth = MAX (maxLineWidth,
				MAX (annotationWidth, cursor.x + bar.closingBarLine.width + 3.75f)
				
			);
			
			annotationWidth = 0;
			
			cursor.x = LEFT_BAR_OFFSET;
			cursor.y = cursor.y + maxLineHeight;
			maxLineHeight = 0;
			
			leftBar = nil;
			currentBarRowDescription = nil;
			
		} else {
			cursor.x += barWidth + BAR_SPACING;
			leftBar = bar;
			
			if (i == [bars count] - 1)
				cursor.y = cursor.y + maxLineHeight;
			
		}
		
	}
	
	if (isFirstLayout) {
		isFirstLayout = NO;
		[self linkAllElements];
		
	}
	
	if (isPrinting) {
		if (printingLayoutWidth > 0)
			maxLineWidth = printingLayoutWidth;
		
	}
	
	NSInteger barRowsToRemove = [barRows count] - barRowIndex;
	if (barRowsToRemove > 0) {
		for (NSInteger i = barRowsToRemove; i >= 0; i--) {
			barRowBackground = [barRows lastObject];
			[scalableSublayers removeObject: barRowBackground];
			[barRowBackground removeFromSuperlayer];
			[barRows removeLastObject];
			
		}
		
	}
	
	extern BOOL optimizeLayout;
	
	if (drawAsSheet) {
		// NSLog (@"------------ optimize %i", optimizeLayout);
		// NSLog (@"layout statistics");
		
		float maximumBarRowWidth = 0;
		float* maximumBarWidths = malloc (sizeof (float) * numBarsInRow);
		memset (maximumBarWidths, 0, sizeof (float) * numBarsInRow);
		
		#define OPTIMIZE_LAYOUT_IGNORE_SIGNATURES YES
		
		for (int i = 0; i < [barRowDescriptions count]; i++) {
			BarRowDescription* description = [barRowDescriptions objectAtIndex: i];

			maximumBarRowWidth = MAX (maximumBarRowWidth,
			description -> fullWidth - description -> fullSpacing);
			
			NSMutableString* buffer = [[NSMutableString alloc] init];
			for (int j = 0; j < description -> numBars; j++) {
				[buffer appendFormat: @"%i: %f; ", j, description -> barWidths [j]];
				if (OPTIMIZE_LAYOUT_IGNORE_SIGNATURES ||
					!(description -> containsKeyOrTimeSignature ||
					description -> numBars < -numBarsInRow)) // move out
					maximumBarWidths [j] = MAX (maximumBarWidths [j], description -> barWidths [j] - 1* description -> barSpacings [j]);

			}
			[buffer release];
			
		}
		
		float maxColumnWidth = 0;
		float sumMaxBarWidth = 0;
		for (int j = 0; j < numBarsInRow; j++) {
			float maximumBarWidth = maximumBarWidths [j];
			if (maximumBarWidth < 48 || isnan (maximumBarWidth))
				maximumBarWidth = maximumBarWidths [j] =
					maximumBarRowWidth / numBarsInRow;
			
			sumMaxBarWidth += maximumBarWidth;
			maxColumnWidth = MAX (maxColumnWidth, maximumBarWidth);
			
		}
		
		if (isPrinting || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			sumMaxBarWidth = 0;
			for (int j = 0; j < numBarsInRow; j++) {
				float maximumBarWidth = maximumBarWidths [j];
				maximumBarWidth = maximumBarWidths [j] =
					(maximumBarWidth + maxColumnWidth) / 2;
				sumMaxBarWidth += maximumBarWidth;
				
			}
			
		}
		
		if (isPrinting) {
			if (printingLayoutWidth > 0)
				maximumBarRowWidth = printingLayoutWidth;
			
		}
		
		float missingWidth = MAX (0, maximumBarRowWidth - sumMaxBarWidth);
				
		if (optimizeLayout) {
			maxLineWidth = 0;
			for (int i = 0; i < [barRowDescriptions count]; i++) {
				BarRowDescription* description = [barRowDescriptions objectAtIndex: i];
				
				float cursor = MARGIN_LEFT;
				BarLayer* bar = nil;
				
				if (!OPTIMIZE_LAYOUT_IGNORE_SIGNATURES && description -> containsKeyOrTimeSignature) {
					
					float missingWidth = maximumBarRowWidth - (description -> fullWidth - description -> fullSpacing);
					float missingWidthPerBar = missingWidth / description -> numBars;
					
					for (int j = 0; j < description -> numBars; j++) {
						bar = description -> barLayers [j];
						float barWidth = description -> barWidths [j] + missingWidthPerBar;
						
						CGPoint position = bar.scaledPosition;
						bar.scaledPosition = CGPointMake (cursor, position.y);
						[bar expandToWidth: barWidth spaceToDistribute: missingWidthPerBar];
						
						cursor += barWidth - description -> barSpacings [j];
						
					}
					
				} else {
					float missingWidthPerBar = /* description -> numBars < numBarsInRow ?
						0 : */ (missingWidth - 9) / numBarsInRow; // description -> numBars;
					
					for (int j = 0; j < description -> numBars; j++) {
						
						bar = description -> barLayers [j];
						float barWidth = maximumBarWidths [j] + missingWidthPerBar;
						
						CGPoint position = bar.scaledPosition;
						bar.scaledPosition = CGPointMake (cursor, position.y);
						
						[bar expandToWidth: barWidth + description -> barSpacings [j]
							spaceToDistribute: (barWidth + description -> barSpacings [j]) - description -> barWidths [j] + (bar.widthIncludingAnnotation - bar.width) - 0]; // bar.width];
						
						cursor += barWidth;
						
					}
					
				}
				if (bar)
					maxLineWidth = MAX (maxLineWidth, cursor + bar.closingBarLine.width + 2.75f);
				
			}
			
		}
		free (maximumBarWidths);
		
	}
	
	[barRowDescriptions release];
	
	// NSLog (@"max width %f", maximumBarRowWidth);
	
	cursor.y -= 1;
	copyright.scaledPosition = CGPointMake (MARGIN_LEFT, cursor.y + 3);
	
	contentSize = CGSizeMake (
		(CGFloat) ((MAX (
			MAX (copyright.localBounds.origin.x + copyright.localBounds.size.width,
				title.localBounds.origin.x + title.localBounds.size.width),
			(maxLineWidth - 18 + LEFT_BAR_OFFSET + 2 + 9)
			
		) + MARGIN_LEFT + MARGIN_RIGHT) * scale),
		(cursor.y + 4 + MARGIN_TOP + MARGIN_BOTTOM) * scale
		
	);
	
	if (contentSize.width != lastContentSize.width ||
		contentSize.height != lastContentSize.height) {
		
		lastContentSize = contentSize;
		[self.sheetScrollView updateContentSize];
		
		[self drawShadowAroundRect: CGRectMake (
			0, 0, contentSize.width, contentSize.height
			
		)];
		
	}
	
	CGSize rowSize = CGSizeMake ((CGFloat) maxLineWidth + 0, 56 - 4);
	for (BoundedBitmapLayer* barRowBackground in barRows)
		barRowBackground.scaledSize = rowSize;
	
	[self updateScaledPosition];
	[self updateLayerVisibilityInRect: [sheetScrollView currentViewRect]];
	
	[self updateRenderQueueState: self.hidden];
	
	for (BoundedBitmapLayer* barRowBackground in barRows)
		[barRowContainer insertSublayer: barRowBackground atIndex: 0];
	
	self.bounds = CGRectMake (
		0, 0, (CGFloat) ceil (contentSize.width), (CGFloat) ceil (contentSize.height)
		
	);
	barRowContainer.bounds = self.bounds;
	
	if ([CATransaction disableActions])
		[CATransaction setDisableActions: NO];
	
	[self.sheetScrollView.sheetView adjustCursorPosition];
	
}

- (CALayer*) staticLayer {
	return staticLayer;
	
}

- (void) renderStatic {
	[self renderStaticInBackground: NO];
	
}

- (void) renderStaticInBackground: (BOOL) background {
	if (!modelObject || didRenderStatic)
		return;
	
	TileRenderQueue* _tileRenderQueue = self.tileRenderQueue;
	[_tileRenderQueue flushQueue];
	
	CGRect currentViewRect = [sheetScrollView currentViewRect];
	
	CGSize tileSize = CGSizeMake (320 / 2, 320 / 2);
	
	CGRect absoluteBounds = CGRectMake (
		currentViewRect.origin.x * scale,
		currentViewRect.origin.y * scale,
		currentViewRect.size.width * scale,
		currentViewRect.size.height * scale
		
	);

	CGPoint absoluteOffset = CGPointMake (
		(CGFloat) fmod (tileSize.width - absoluteBounds.origin.x, tileSize.width),
		(CGFloat) fmod (tileSize.height - absoluteBounds.origin.y, tileSize.height)
		
	);
	if (absoluteOffset.x < 0)
		absoluteOffset.x += tileSize.width;
	if (absoluteOffset.y < 0)
		absoluteOffset.y += tileSize.height;
	
	CGRect selfBounds = self.bounds;
	CGRect fullBounds = CGRectMake (
		0, 0, selfBounds.size.width, selfBounds.size.height
		
	);
	
	[CATransaction setDisableActions: YES];
	
	/*
	if (!didRenderStatic && !didPreRenderStatic) {
		[self renderImmediately];
		
	}
	*/
	
	staticLayer.bounds = selfBounds;
	
	int tilesToLeft = (int) ceil (absoluteBounds.origin.x / tileSize.width);
	int tilesToRight = (int) ceil ((fullBounds.size.width - absoluteBounds.origin.x) / tileSize.width);
	int numTilesX = tilesToLeft + tilesToRight;
	
	int tilesToTop = (int) ceil (absoluteBounds.origin.y / tileSize.height);
	int tilesToBottom = (int) ceil ((fullBounds.size.height - absoluteBounds.origin.y) / tileSize.height);
	int numTilesY = tilesToTop + tilesToBottom;
	
	int numTiles = numTilesX * numTilesY;
	
	NSMutableArray* jobs = [[NSMutableArray alloc] initWithCapacity: numTiles];
	NSMutableArray* visibleStaticTiles = [[NSMutableArray alloc] initWithCapacity: numTiles];
	
	for (int y = 0; y < numTilesY; y++) {
		for (int x = 0; x < numTilesX; x++) {
			CGRect bounds = CGRectMake (
				x * tileSize.width - absoluteOffset.x,
				y * tileSize.height - absoluteOffset.y,
				tileSize.width, tileSize.height
				
			);
			
			if (bounds.origin.x < 0) {
				bounds.size.width += bounds.origin.x;
				bounds.origin.x = 0;
				
			}
			if (bounds.origin.x + bounds.size.width > fullBounds.size.width) {
				bounds.size.width = fullBounds.size.width - bounds.origin.x;
				
			}
			
			if (bounds.origin.y < 0) {
				bounds.size.height += bounds.origin.y;
				bounds.origin.y = 0;
				
			}
			if (bounds.origin.y + bounds.size.height > fullBounds.size.height) {
				bounds.size.height = fullBounds.size.height - bounds.origin.y;
				
			}
			
			if (bounds.size.width <= 0 || bounds.size.height <= 0) {
				NSLog (@"XXX error XXX");
				continue;
				
			}
			
			if (CGRectIntersectsRect (bounds, absoluteBounds)) {
				if (background) {
					TileRenderJob* job = [[TileRenderJob alloc]
						initWithSourceLayer: self bounds: bounds targetLayer: staticLayer];
					job -> doNotUpdateLayerVisibility = YES;
					[jobs addObject: job];
					[job release];
					
				}
				/*
				CALayer* staticTile = [self staticTileInBounds: bounds];
				[visibleStaticTiles addObject: staticTile];
				*/
				
			} else {
				if (!background) {
					TileRenderJob* job = [[TileRenderJob alloc]
						initWithSourceLayer: self bounds: bounds targetLayer: staticLayer];
					
					if (background)
						job -> doNotUpdateLayerVisibility = YES;
					
					[jobs addObject: job];
					[job release];
					
				}
				
			}
			
		}
		
	}
	
	if (background) {
		for (ScalableLayer* scalableLayer in scalableSublayers) {
			if (!scalableLayer -> persistentParent) {
				[self addSublayer: scalableLayer];
				
			}
			
		}
		// [self renderImmediately];
		
	} else if (!didPreRenderStatic) {
		CGRect extendedScreenBounds = CGRectMake (
			currentViewRect.origin.x * scale,
			currentViewRect.origin.y * scale,
			(CGFloat) MIN (fullBounds.size.width - currentViewRect.origin.x * scale,
				ceil (currentViewRect.size.width * scale / tileSize.width) * tileSize.width),
			(CGFloat) MIN (fullBounds.size.height - currentViewRect.origin.y * scale,
				ceil (currentViewRect.size.height * scale / tileSize.height) * tileSize.height)
			
		);
		if (extendedScreenBounds.origin.x < 0) {
			extendedScreenBounds.size.width += extendedScreenBounds.origin.x;
			extendedScreenBounds.origin.x = 0;
			
		}
		if (extendedScreenBounds.origin.y < 0) {
			extendedScreenBounds.size.height += extendedScreenBounds.origin.y;
			extendedScreenBounds.origin.y = 0;
			
		}
		
		CGRect extentedViewRect = CGRectMake(
			extendedScreenBounds.origin.x / scale,
			extendedScreenBounds.origin.y / scale,
			extendedScreenBounds.size.width / scale,
			extendedScreenBounds.size.height / scale
			
		);
		[self updateLayerVisibilityInRect: extentedViewRect];
		[self renderImmediately];
		
		CALayer* staticTile = [self staticTileInBounds: extendedScreenBounds];
		[visibleStaticTiles addObject: staticTile];
		
	}
	
	for (CALayer* staticTile in visibleStaticTiles)
		[staticLayer addSublayer: staticTile];
	
	[visibleStaticTiles release];
	
	[staticLayer addSublayer: shadowLayer];
	
	[CATransaction setDisableActions: NO];
	
	[tileRenderQueue addToQueue: jobs];
	[jobs release];
	
	if (background) {
		didPreRenderStatic = YES;
		
	} else {
		didRenderStatic = YES;
		
	}
	
	// NSLog (@"static layer sublayers %@", staticLayer.sublayers);
	
}

- (BOOL) isHidden {
	return NO;
	
}

@synthesize contentSize;

//

- (void) dealloc {
	/*
	if (renderQueue)
		[renderQueue removeListener: self selector: @selector (onQueueRendered:) forEvent: @"queueRendered"];
	
	*/
	
	for (CALayer* layer in barRows)
		[layer removeFromSuperlayer];
	for (CALayer* layer in bars)
		[layer removeFromSuperlayer];
	
	[bars release];
	[barRows release];
	
	barRowContainer.sublayers = nil;
	[barRowContainer removeFromSuperlayer];
	[barRowContainer release];
	
	shadowLayer.sublayers = nil;
	[shadowLayer removeFromSuperlayer];
	[shadowLayer release];
	
	cursorContainer.sublayers = nil;
	cursorLayer = nil;
	
	[sheetProperties release];
	
	if (renderQueue) {
		// [renderQueue flushQueue];
		[renderQueue release];
		
	}
	
	if (tileRenderQueue)
		[tileRenderQueue release];
	
	[title release];
	[copyright release];
	
	staticLayer.sublayers = nil;
	[staticLayer removeFromSuperlayer];
	[staticLayer release];
	
	[super dealloc];
	
}


@end
