//
//  OpeningBarLineLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 08.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "OpeningBarLineLayer.h"

#import "OpeningBarLine.h"

#import "BarLayer.h"


@implementation OpeningBarLineLayer


- (id) init {
	if ((self = [super init])) {
		barLineSymbol.scaledPosition = CGPointMake (-12 + 7, -10);
//		barLineSymbol.scaledPosition = CGPointMake (-12 + 7 + 2, -10 + 10);
				
	}
	return self;
	
}

@synthesize rehearsalMark;
@synthesize voltaMark;
@synthesize barMark;

- (void) updateFromModelObject {
	OpeningBarLine* openingbarLine = modelObject;
	
	NSString* symbol = nil;
	if (openingbarLine) {
		if (!openingbarLine.type || [openingbarLine.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
			if (openingbarLine.repeatCount)
				symbol = @"P";
			else
				symbol = @"I";
			
		} else {
			if (openingbarLine.repeatCount)
				symbol = @"R";		
			else
				symbol = @"Q";
			
		}
		
	} else {
		symbol = @"I";
		
	}
	barLineSymbol.text = symbol;
	
	NSString* rehearsalMarkSymbol = nil;
	NSString* voltaMarkSymbol = nil;
	
	// NSLog (@"volta count %i", openingbarLine.voltaCount);
	
	if (openingbarLine.voltaCount) {
		unichar voltaMarkCharacter = 'S';
		voltaMarkCharacter += openingbarLine.voltaCount - 1;
		
		voltaMarkSymbol = [NSString stringWithCharacters: &voltaMarkCharacter length: 1];
		
	}
	
	float voltaInset = voltaMarkSymbol ? 1 : 0;
	
	CGPoint rehearsalMarkPosition;
	if ([openingbarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_CODA]) {
		rehearsalMarkSymbol = @"z";
		rehearsalMarkPosition = CGPointMake (
			self.insetOfNarrowBar + voltaInset * 24, -10
			
		);
		
	} else if ([openingbarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_SEGNO]) {
		rehearsalMarkSymbol = @"w";		
		rehearsalMarkPosition = CGPointMake (
			self.insetOfNarrowBar + 2 + voltaInset * 25, -10
			
		);
		
	}
	
	if (rehearsalMarkSymbol) {
		if (!rehearsalMark) {
			rehearsalMark = [TextLayer layer];
			rehearsalMark.fontName = @"iDBsheet-Regular";
			rehearsalMark.fontSize = LABEL_BASE_SIZE * 3;
			
		}
		[self presentSublayer: rehearsalMark visible: YES];
		rehearsalMark.scaledPosition = rehearsalMarkPosition;
		rehearsalMark.text = rehearsalMarkSymbol;
		
	} else {
		if (rehearsalMark) {
			[rehearsalMark removeFromSuperlayer];
			[scalableSublayers removeObject: rehearsalMark];
			rehearsalMark = nil;
			
		}
		
	}
	
	if (voltaMarkSymbol) {
		if (!voltaMark) {
			voltaMark = [TextLayer layer];
			voltaMark.fontName = @"iDBsheet-Regular";
			voltaMark.fontSize = LABEL_BASE_SIZE * 3;
			[self addSublayer: voltaMark];		
		
		}
		voltaMark.text = voltaMarkSymbol;
		voltaMark.scaledPosition = CGPointMake (
			self.insetOfNarrowBar - 6, -10 + 1// 12
			
		);
		[self presentSublayer: voltaMark visible: YES];
		
	} else {
		if (voltaMark) {
			[voltaMark removeFromSuperlayer];
			[scalableSublayers removeObject: voltaMark];
			voltaMark = nil;
			
		}
		
	}
	
	NSString* barMarkSymbol = nil;
	NSString* barMarkKey = openingbarLine.barMark;
	if (barMarkKey) {
		if ([barMarkKey isEqualToString: BAR_LINE_BAR_MARK_SIMILE]) {
			barMarkSymbol = @"t";
			
		} else if ([barMarkKey isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE]) {
			barMarkSymbol = @"u";
			
		} else if ([barMarkKey isEqualToString: BAR_LINE_BAR_MARK_WHOLE_REST]) {
			barMarkSymbol = @"v";
			
		}
		
	}
	if (barMarkSymbol) {
		if (!barMark) {
			barMark = [TextLayer layer];
			barMark -> cropY = .3f;
			barMark.scaledPosition = CGPointMake (
				10, -10
				
			);
			barMark.fontName = @"iDBsheet-Regular";
			barMark.fontSize = LABEL_BASE_SIZE * 3;
			
		}
		barMark.text = barMarkSymbol;
		[self presentSublayer: barMark visible: YES];
		
	} else {
		if (barMark) {
			[barMark removeFromSuperlayer];
			[scalableSublayers removeObject: barMark];
			barMark = nil;
			
		}
		
	}
	[self setNeedsRecalcConcatenatedBounds: YES];
	
}

- (void) updateLayout {
	
	// NSLog(@"upda lay");
	
}

- (id) modelObject {
	if (!modelObject)
		modelObject = [[OpeningBarLine alloc] init];
	
	return modelObject;
	
}

- (CGRect) localBounds {
	
	OpeningBarLine* openingbarLine = modelObject;
	
	double boundsWidth = 5;
	
	NSString* barMarkKey = openingbarLine.barMark;
	if (barMarkKey) {
		BarLayer* pertainingBar = (BarLayer*) designatedSuperlayer;
		
		if ([barMarkKey isEqualToString: BAR_LINE_BAR_MARK_SIMILE] ||
			[barMarkKey isEqualToString: BAR_LINE_BAR_MARK_WHOLE_REST] ||
			pertainingBar -> isLastInLine) {
			boundsWidth = pertainingBar.closingBarLine.scaledPosition.x -
				originalPosition.x - 20;
			
		} else if ([barMarkKey isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE]) {
			
			BarLayer* nextBar =
				(BarLayer*) pertainingBar.openingBarLine.nextEditableElement.designatedSuperlayer;
			if (nextBar && !pertainingBar -> isLastInLine) {
				boundsWidth = nextBar.scaledPosition.x - pertainingBar.scaledPosition.x + nextBar.closingBarLine.scaledPosition.x - 12 - 10;
				
			} else {
				boundsWidth = pertainingBar.closingBarLine.scaledPosition.x -
					originalPosition.x - 20;
				
			}
			
		}
		
	}
	return self -> localBounds = CGRectMake (
		5 - 3, 0, (CGFloat) boundsWidth, 32 + 2
		
	);
	
}

/*
- (CGRect) localBoundsForEditor {
	
	return CGRectMake (
		5 - 3, 0, 5, 32 + 2
		
	);
	
}
*/

- (float) width {
	float width = 0;
	
	OpeningBarLine* barLine = modelObject;
	if (!barLine.type || [barLine.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
		if (barLine.repeatCount)
			width = 3; // |:
		else
			width = 1; // |
		
	} else {
		if (barLine.repeatCount)
			width = 11.25; // ||:
		else
			width = 6; // ||
		
	}
	return width;
	
}

- (float) insetOfNarrowBar {
	float width = 0;
	
	OpeningBarLine* barLine = modelObject;
	if (!barLine.type || [barLine.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
		width = 1; // |
		
	} else {
		width = 5.8f; // ||
		
	}
	return width;
	
}

- (void) dealloc {
    [super dealloc];
	
}

//

extern NSString *SHEET_COLOR_SCHEME_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_NEGATIVE;
extern NSString *SHEET_COLOR_SCHEME_PRINT;

extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE;


- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[colorScheme release];
	colorScheme = [_colorScheme retain];

	for (ScalableLayer* sublayer in scalableSublayers) {
		if (sublayer == barLineSymbol) {
			if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE]) {
				sublayer.colorScheme = SHEET_COLOR_SCHEME_POSITIVE;
				
			} else if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE]) {
				sublayer.colorScheme = SHEET_COLOR_SCHEME_NEGATIVE;
				
			} else {
				sublayer.colorScheme = _colorScheme;
				
			}
			
		} else {
			sublayer.colorScheme = _colorScheme;
			
		}
		
	}
	
}


@end
