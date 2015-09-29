//
//  KeySignatureLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "KeySignatureLayer.h"

#import "KeySignature.h"

#import "TextLayer.h"


@implementation KeySignatureLayer

static NSArray* majorAccidentalDefinitions;
static NSArray* minorAccidentalDefinitions;

#define MAX_NUM_ACCIDENTALS 6

+ (void) initialize {
	if (!majorAccidentalDefinitions) {
		majorAccidentalDefinitions = [[NSArray arrayWithObjects:
			@"Cb:5:#",
			@"C:1:x",
			@"C#:5:b",
			@"Db:5:b",
			@"D:2:#",
			@"D#:3:b",
			@"Eb:3:b",
			@"E:4:#",
			@"E#:1:b",
			@"Fb:4:#",
			@"F:1:b",
			@"F#:6:#",
			@"Gb:6:b",
			@"G:1:#",
			@"G#:4:b",
			@"Ab:4:b",
			@"A:3:#",
			@"A#:2:b",
			@"Bb:2:b",
			@"B:5:#",
			@"B#:0:x",
			nil
			
		] retain];
		minorAccidentalDefinitions = [[NSArray arrayWithObjects:
			@"Cb:2:#",
			@"C:3:b",
			@"C#:4:#",
			@"Db:4:#",
			@"D:1:b",
			@"D#:6:#",
			@"Eb:6:b",
			@"E:1:#",
			@"E#:4:b",
			@"Fb:1:#",
			@"F:4:b",
			@"F#:3:#",
			@"Gb:3:#",
			@"G:2:b",
			@"G#:5:#",
			@"Ab:5:#",
			@"A:1:x",
			@"A#:5:b",
			@"Bb:5:b",
			@"B:2:#",
			@"B#:3:b",
			nil
			
		] retain];
		
	}
	
}

- (id) init {
	if ((self = [super init])) {
		accidentials = [[NSMutableArray alloc] init];
		
		for (int i = MAX_NUM_ACCIDENTALS; i--;) {
			TextLayer* accidential = [TextLayer layer];
			accidential -> cropY = .3f;
			accidential.fontSize = 16 * 2.5;
			accidential.fontName = @"iDBsheet-Regular";
			
			[accidentials addObject: accidential];
			[self addSublayer: accidential];
			
		}
		
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.anchorPoint = CGPointMake (0, 0);
		
		self.isEditable = YES;
		
	}
	return self;
	
}

//

static int xOffsetTableSharp [] =
	{0, 1, 1, 2, 3, 3};

- (void) updateFromModelObject {
	KeySignature* keySignature = modelObject;
	
	NSString* keyString = [keySignature.key stringValue];
	
	NSArray* definitions = keySignature.isMinor ?
		minorAccidentalDefinitions : majorAccidentalDefinitions;
	
	NSArray* definition = nil;
	for (NSString* serial in definitions) {
		definition = [serial componentsSeparatedByString: @":"]; 
		if ([[definition objectAtIndex: 0] isEqualToString: keyString]) {
			// NSLog (@"found definition for key %@", keyString);
			break;
			
		}
		
	}
	accidentalCount = [[definition objectAtIndex: 1] intValue];
	
	static int yOffsetTableFlat [] =
		{4, 7, 3, 6, 2, 5};
	static int yOffsetTableSharp [] =
		{8, 5, 9, 6, 3, 7};
	
	accidentalChar = [[definition objectAtIndex: 2] characterAtIndex: 0];
	NSString* accidentalSymbol =
		accidentalChar == 'b' ? @"q" :
		accidentalChar == '#' ? @"#" :
		@"Z";
	
	int* yOffsetTable =
		accidentalChar == 'b' ? yOffsetTableFlat :
		accidentalChar == '#' ? yOffsetTableSharp :
		nil;
	
	float spacing = accidentalChar == 'b' ? 4.75 : 4.5;
	for (int i = 0; i < accidentalCount; i++) {
		TextLayer* accidential = [accidentials objectAtIndex: i];
		float extraSpace = accidentalChar == 'b' ?
			(i / 2) * 1.5f : xOffsetTableSharp [i] * 1.5f;
		
		if (yOffsetTable) {
			accidential.scaledPosition = CGPointMake
				(i * spacing + extraSpace, (3 - yOffsetTable [i]) * (CGFloat) 3.5);
			
		} else {
			accidential.scaledPosition = CGPointMake
				(0, -6);
		
		}
		accidential.text = accidentalSymbol;
		accidential.hidden = NO;
		
	}
	for (int i = accidentalCount; i < MAX_NUM_ACCIDENTALS; i++) {
		TextLayer* accidential = [accidentials objectAtIndex: i];
		accidential.hidden = YES;
		
	}
	
	self -> localBounds = CGRectMake (
		-1, 0, self.width + 1, 32 + 2
		
	);
	
}

//

- (float) width {
	TextLayer* lastAccidental = [accidentials objectAtIndex: accidentalCount - 1];
	return (float) lastAccidental.scaledPosition.x + (float) lastAccidental.width + (accidentalChar == 'x' ? .5f : -.5f);
	
}

//

- (void) dealloc {
	[accidentials release];
	[super dealloc];
	
}

@end
