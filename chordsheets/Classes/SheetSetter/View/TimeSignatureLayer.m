//
//  TimeSignatureLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "TimeSignatureLayer.h"

#import "TimeSignature.h"


@implementation TimeSignatureLayer

- (id) init {
	if ((self = [super init])) {
		numeratorLayer = [TextLayer layer];
		numeratorLayer -> cropY = .3f;
		numeratorLayer.scaledPosition = CGPointMake (0, -6);
		numeratorLayer.fontSize = 16 * 2;
		numeratorLayer.fontName = @"iDBsheet-Regular";
		
		[self addSublayer: numeratorLayer];
		
		denominatorLayer = [TextLayer layer];
		denominatorLayer -> cropY = .3f;
		denominatorLayer.scaledPosition = CGPointMake (0, 7);
		denominatorLayer.fontSize = 16 * 2;
		denominatorLayer.fontName = @"iDBsheet-Regular";
		[self addSublayer: denominatorLayer];
		
		self.isEditable = YES;
		
	}
	return self;
	
}

//

- (void) updateFromModelObject {
	TimeSignature* timeSignature = modelObject;
	
	numeratorLayer.text = [[NSNumber numberWithInt: timeSignature.numerator] stringValue];
	denominatorLayer.text = [[NSNumber numberWithInt: timeSignature.denominator] stringValue];
	
	[self updateLayout];
	
}

//

- (void) updateLayout {
	float maxWidth = self.width;
	numeratorLayer.scaledPosition = CGPointMake (
		(maxWidth - numeratorLayer.width) / 2,
		numeratorLayer.scaledPosition.y
		
	);
	denominatorLayer.scaledPosition = CGPointMake (
		(maxWidth - denominatorLayer.width) / 2,
		denominatorLayer.scaledPosition.y
		
	);
	
	self -> localBounds = CGRectMake (
		-1, 0, self.width + 1, 32 + 2
		
	);
	
}

//

- (float) width {
	return MAX (numeratorLayer.width, numeratorLayer.width);
	
}

//

- (void) dealloc {
	[super dealloc];
	
}

@end
