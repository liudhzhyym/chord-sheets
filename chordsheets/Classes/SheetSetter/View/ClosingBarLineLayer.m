//
//  ClosingBarLineLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 08.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "ClosingBarLineLayer.h"

#import "ClosingBarLine.h"
#import "BarLayer.h"


@implementation ClosingBarLineLayer


- (id) init {
	if ((self = [super init])) {
		barLineSymbol.scaledPosition = CGPointMake (-16, -10);
		
	}
	return self;
	
}

#define BOTTOM_MARK_Y_OFFSET 15.5f

// properties

@synthesize repeatCountLabel;

- (void) updateFromModelObject {
	ClosingBarLine* closingBarLine = modelObject;
	
	BOOL isLastInSheet = ((BarLayer*) designatedSuperlayer) -> isLastInSheet;
	
	// NSLog (@"is last in sheet %i", isLastInSheet);
	
	NSString* symbol = nil;
	if (closingBarLine) {
		if (closingBarLine.repeatCount) {
			symbol = @"K";
			
		} else if (!closingBarLine.type || [closingBarLine.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
			if (isLastInSheet)
				symbol = @"L";
			else
				symbol = @"I";
			
		} else {
			if (isLastInSheet)
				symbol = @"L";
			else
				symbol = @"J";
			
		}
		
	} else {
		if (isLastInSheet)
			symbol = @"L";
		else
			symbol = @"I";
		
	}
	
	if ([symbol isEqualToString: @"L"]) {
		barLineSymbol -> cropX = .25;
		barLineSymbol.scaledPosition = CGPointMake (-16 - 0, -10);
		
	} else {
		barLineSymbol -> cropX = 0;
		barLineSymbol.scaledPosition = CGPointMake (-16, -10);
		
	}
	
	
	barLineSymbol.text = symbol;
	
	float cursor = -10;
	
	if (closingBarLine.repeatCount > 1) {
		if (!repeatCountLabel) {
			repeatCountLabel = [TextLayer layer];
			repeatCountLabel -> cropY = .3f;
			repeatCountLabel.fontSize = (float) (LABEL_BASE_SIZE * REPEAT_COUNT_LABEL_SIZE_FACTOR);
			repeatCountLabel.fontName = @"iDBsheet-Regular";
			repeatCountLabel.scaledPosition = CGPointMake (0, BASELINE_HEIGHT * (1 - repeatCountLabel.fontSize) + 36.f + .75f);
			repeatCountLabel.hidden = YES;
			[self addSublayer: repeatCountLabel];
			
		}
		repeatCountLabel.text =
			[NSString stringWithFormat: @"%iX", closingBarLine.repeatCount];
		cursor += 6; // 8;
		cursor -= repeatCountLabel.width;
		repeatCountLabel.scaledPosition = CGPointMake (cursor, repeatCountLabel.scaledPosition.y);
		repeatCountLabel.hidden = NO;
		cursor -= 1;
		
	} else {
		if (repeatCountLabel) {
			[repeatCountLabel removeFromSuperlayer];
			[scalableSublayers removeObject: repeatCountLabel];
			repeatCountLabel = nil;
			
		}
		
	}
	if ([closingBarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_FINE]) {
		if (!fineMark) {
			fineMark = [TextLayer layer];
			fineMark.fontSize = LABEL_BASE_SIZE * REHEARSAL_MARK_LABEL_SIZE_FACTOR;
			fineMark.fontName = @"iDBsheet-Regular";
			fineMark.scaledPosition = CGPointMake (-10, BASELINE_HEIGHT * (1 - fineMark.fontSize) + BOTTOM_MARK_Y_OFFSET / 1);// -11.3);
			fineMark.text = @"p";
			[self addSublayer: fineMark];
			
		}
		if (!(closingBarLine.repeatCount > 1))
			cursor += 2;
		cursor -= fineMark.width;
		fineMark.scaledPosition = CGPointMake (cursor, fineMark.scaledPosition.y);
		cursor -= 1;

	} else {
		if (fineMark) {
			[fineMark removeFromSuperlayer];
			[scalableSublayers removeObject: fineMark];
			fineMark = nil;
			
		}
		if (closingBarLine.repeatCount > 1)
			cursor -= 1;
		else
			cursor += 1;
		
	}
	
	if ([closingBarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_CODA]) {
		if (!codaMark) {
			codaMark = [TextLayer layer];
			codaMark.scaledPosition = CGPointMake (-19, 26 / 1);
			codaMark.fontSize = LABEL_BASE_SIZE * CODA_MARK_LABEL_SIZE_FACTOR;
			codaMark.fontName = @"iDBsheet-Regular";
			codaMark.text = @"z";
			[self addSublayer: codaMark];
			
		}
		cursor -= codaMark.width;
		codaMark.scaledPosition = CGPointMake (cursor, codaMark.scaledPosition.y);
		cursor -= 1;
		
	} else {
		if (codaMark) {
			[codaMark removeFromSuperlayer];
			[scalableSublayers removeObject: codaMark];
			codaMark = nil;
			
		}
		
	}
	
	NSString* dcSymbol = nil;
	if ([closingBarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_DA_CAPO])
		dcSymbol = @"x";
	else if ([closingBarLine.rehearsalMarks containsObject: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO])
		dcSymbol = @"y";
	
	if (dcSymbol) {
		if (!dcMark) {
			dcMark = [TextLayer layer];
			dcMark.fontSize = LABEL_BASE_SIZE * REHEARSAL_MARK_LABEL_SIZE_FACTOR;
			dcMark.fontName = @"iDBsheet-Regular";
			dcMark.scaledPosition = CGPointMake (-10, BASELINE_HEIGHT * (1 - dcMark.fontSize) + BOTTOM_MARK_Y_OFFSET / 1);// -11.3);
			[self addSublayer: dcMark];
			
		}
		dcMark.text = dcSymbol;
		cursor -= dcMark.width;
		dcMark.scaledPosition = CGPointMake	(
			cursor, dcMark.scaledPosition.y
			
		);
		cursor -= 1;
		
	} else {
		if (dcMark) {
			[dcMark removeFromSuperlayer];
			[scalableSublayers removeObject: dcMark];
			dcMark = nil;
			
		}
		
	}
	(void) cursor;
	
}


- (id) modelObject {
	if (!modelObject)
		modelObject = [[ClosingBarLine alloc] init];
	
	return modelObject;
	
}

- (CGRect) localBounds {
	return self -> localBounds = CGRectMake (
		-15, 0, 5, 32 + 2
		
	);
	
}

- (float) rehearsalMarksCombinedWidth {
	
	double width = 0;
	if (dcMark && !dcMark.hidden)
		width = dcMark.scaledPosition.x;
	else if (codaMark && !codaMark.hidden)
		width = codaMark.scaledPosition.x;
	else if (fineMark && !fineMark.hidden)
		width = fineMark.scaledPosition.x;
	
	return width ? (float) -width - 10 : 0;
	
}

- (float) width {
	float width = 0;
	ClosingBarLine* barLine = modelObject;

	if (barLine.repeatCount) {
		width = 11.25; // ||:
		
	} else if (!barLine.type || [barLine.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
		width = 6; // |
		
	} else {
		width = 6; // ||
		
	}
	return width;
	
}

- (float) overlappingRight {
	float width = 0;
	ClosingBarLine* barLine = modelObject;

	if (barLine.repeatCount) {
		width = 4.9f; // ||:
		
	} else if (!barLine.type || [barLine.type isEqualToString: BAR_LINE_TYPE_SINGLE]) {
		width = 0; // |
		
	} else {
		width = 2.5; // ||
		
	}
	return width;
	
}

- (void) updateLayout {
	repeatCountLabel.scaledPosition = CGPointMake (0, 40);
	
}

- (void) dealloc {
    [super dealloc];
	
}


@end
