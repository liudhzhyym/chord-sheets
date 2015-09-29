//
//  BarLine.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "BarLineLayer.h"

#import "BarLayer.h"
#import "OpeningBarLine.h"
#import "ClosingBarLine.h"


@implementation BarLineLayer

- (id) init {
	if ((self = [super init])) {
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.anchorPoint = CGPointMake (0, 0);
//		[self setNeedsDisplay];
		
		barLineSymbol = [TextLayer layer];
		barLineSymbol -> cropY = .25;
		barLineSymbol.fontName = @"iDBsheet-Regular";
		barLineSymbol.fontSize = 16 * 3;
		[self addSublayer: barLineSymbol];
		
		self.isEditable = YES;
		
	}
	return self;
	
}

- (CGRect) localBoundsForEditor {
	return self.localBounds;
	
}


- (CGRect) localBoundsForPlayback {
	CGRect bounds = self.localBoundsForEditor;
	
	bounds.origin.x += 1;
	bounds.origin.y = -7;
	
	bounds.size.width += 8 - 2;
	bounds.size.height = 54;
	
	return bounds;
	
}

- (float) width {
	return 0;
	
}

@synthesize barLineSymbol;

//

- (void) dealloc {
	[super dealloc];

}

//

+ (float) offsetForBetweenLeft: (BarLineLayer*) _leftBar right: (BarLineLayer*) _rightBar {
	
	float constOffset = 0;
	
	float offset; // = -1 + constOffset;
	ClosingBarLine* left = _leftBar.modelObject;
	OpeningBarLine* right = _rightBar.modelObject;
	
	if ((DISPLAYS_KEY_SIGNATURES && right.keySignature) || right.timeSignature) {
		if (!left.type || [left.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
			offset = -5.75f + constOffset;
			
		} else {
			if (left.repeatCount > 1)
				offset = -1.5f + constOffset;
			else
				offset = -3.5f + constOffset;
			
		}
		return offset;
		
	}
	if (!left.type || [left.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
		if ([right.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
			offset = -11 + constOffset;
			
		} else {
			offset = -11 + constOffset;
			
		}
		
	} else {
		if (!right.type || [right.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
			if (left.type && [left.type isEqualToString: BAR_LINE_TYPE_DOUBLE] && !left.repeatCount) {
				offset = -8.6f + constOffset;
				
			} else {
				offset = -6.25f + constOffset;
				
			}
			
		} else {
			offset = -8.6f + constOffset;
			
		}
		
	}
	return offset;

}


@end
