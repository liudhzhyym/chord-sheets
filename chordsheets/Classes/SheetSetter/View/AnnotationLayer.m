//
//  AnnotationLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "AnnotationLayer.h"
#import "BoundedBitmapLayer.h"

#import "BarLayer.h"


@implementation AnnotationLayer

- (id) init {
	if ((self = [super init])) {
		self.drawsBorder = YES;
		
		self.fontName = @"Helvetica"; // -Bold";
		self.fontSize = 10;
		
		self.label = @"Annotation";
		
		self.isEditable = YES;
		
		// self.opaque = YES; // causes artifacts on ios 7
		
		shadowLayer = [BoundedBitmapLayer layer];
		shadowLayer.scaledPosition = CGPointMake (0, 12 + 1);
		[self addSublayer: shadowLayer];
		
		editorYPadding = 0;
		
	}
	return self;
	
}

extern NSString *SHEET_COLOR_SCHEME_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_NEGATIVE;
extern NSString *SHEET_COLOR_SCHEME_PRINT;

- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[super setColorScheme: _colorScheme];
	
	BOOL isPositive = [colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE];
	BOOL isPrint = [colorScheme isEqualToString: SHEET_COLOR_SCHEME_PRINT];
	
	float fontShade = isPrint ? 0. : isPositive ? .3f : 0;
	
	fontColor [0] = fontShade;
	fontColor [1] = fontShade;
	fontColor [2] = fontShade;
	
	float backgroundShade = isPrint ? 1. : isPositive ? 1. : .4f;
	
	backgroundColor [0] = backgroundShade;
	backgroundColor [1] = backgroundShade;
	backgroundColor [2] = backgroundShade;
	backgroundColor [3] = 1.f;
	
	[shadowLayer loadBundleImage: isPrint ?
		@"AnnotationShadow_print.png" : isPositive ?
		@"AnnotationShadow.png" : @"AnnotationShadow_negative.png"];
	
	[self setNeedsRendering: YES];
	[self setNeedsUpdateRenderQueueState];
	
	[self updateLayout];
	
}

- (void) updateLayout {
	shadowLayer.scaledSize = CGSizeMake (
		textSize.width,
		shadowLayer.scaledSize.height
		
	);
	
	
}

- (CGRect) localBoundsForEditor {
	
	BarLayer* pertainingBar = (BarLayer*) self -> designatedSuperlayer;
	
	return CGRectMake (
		0, -editorYPadding,
		pertainingBar.closingBarLine.scaledPosition.x - originalPosition.x - 24 - 2,
		textSize.height + editorYPadding
		
	);
	
}


@end
