//
//  KeyLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Key.h"

#import "KeyLayer.h"


@implementation KeyLayer

- (id) init {
	if ((self = [super init])) {
		cropY = .325f;
		
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.anchorPoint = CGPointMake (0, 0);
		
		self.fontName = @"iDBsheet-Regular";
		
	}
	return self;
	
}

@synthesize accidental;
@synthesize extension;

//

- (void) setModelObject: (Key*) key {
	[super setModelObject: key];
	
	if ([self class] != [KeyLayer class])
		return;
	
	if (key)
		self.text = [key stringValue];
	else
		self.text = @"";
	
}

//

- (void) setAccidentalFontSize: (float) _fontSize {
	[accidental setFontSize: _fontSize * 3 / 4];
	
}

- (void) setFontSize: (float) _fontSize {
	[super setFontSize: _fontSize];
	if (accidental)
		[self setAccidentalFontSize: _fontSize];
	
}

- (void) setText: (NSString*) _text {
	
	int textLength = (int) [_text length];
	
	BOOL hasAccidental = textLength > 1;
	if (hasAccidental) {
		UniChar accidentalChar = [_text characterAtIndex: 1];
		hasAccidental =
			accidentalChar == 'b' ||
			accidentalChar == '#';
		
	}
	
	BOOL hasExtension =
		(hasAccidental && textLength > 2) ||
		(!hasAccidental && textLength > 1);
	
	
	float cursor = 0.f;
	
	
	NSString* noteText = textLength ? [_text substringToIndex: 1] : @"";
	[super setText: noteText];
	
	cursor = (float) textSize.width;
	
	
	
	if (hasAccidental) {
		if (!accidental) {
			accidental = [[TextLayer alloc] init];
			accidental -> cropY = .3f;
			accidental.scaledPosition = CGPointMake (10, 20); // 14 + 14);
			accidental.fontName = @"iDBsheet-Regular";
			[self setAccidentalFontSize: fontSize];
			
		}
		NSMutableString* accidentalText =
			[[_text substringWithRange: NSMakeRange (1, 1)] mutableCopy];
		[accidentalText replaceOccurrencesOfString: @"b" withString: @"q"
			options: NSLiteralSearch range: NSMakeRange (0, 1)]; // use table
		accidental.text = accidentalText;
		
		UniChar accidentalChar = [accidentalText length] ? [accidentalText characterAtIndex: 0] : 0;
		UniChar noteChar = [noteText length] ? [noteText characterAtIndex: 0] : 0;
		
		// float accidentalYOff = (accidentalChar == '#' ? -12 + .4 : -12) + 5.65 - 1 * 0 - 10;
		float accidentalXOff = .1f; // .05;
		
		if (noteChar == 'A') {
			if (accidentalChar == '#')
				accidentalXOff -= .7;
			else
				accidentalXOff -= .6;
			
		}
		
// NSLog(@"font size %f", accidental.fontSize);
		
		accidental.scaledPosition = CGPointMake (
			cursor + (-.75f + accidentalXOff) * self.fontSize / 16,
			1 * self.fontSize / 16 // (accidentalYOff + 14.) * accidental.fontSize / 38.4
			
		);
		
		[self presentSublayer: accidental visible: YES];
		// accidental.hidden = NO;
        [accidentalText release];
		
		
		cursor = (float) accidental.scaledPosition.x + (float) (accidental ->  textSize).width - 1.f;
		
		
	} else {
		if (accidental) {
			[self presentSublayer: accidental visible: NO];
			// accidental.hidden = YES;
			[accidental release];
			accidental = nil;
			
		}
		cursor -= 1.25f;
		
	}
	
	if (hasExtension) {
		if (!extension) {
			extension = [[TextLayer alloc] init];
			extension -> cropY = .3f;
			extension.scaledPosition = CGPointMake (10, 20); // 14 + 14);
			extension.fontName = @"iDBsheet-Regular";
			extension.fontSize = fontSize * 1; // / 1.2;
			
		}
		int extensionLength = hasAccidental ? 2 : 1;
		NSMutableString* extensionText =
			[[_text substringWithRange: NSMakeRange (extensionLength, textLength - extensionLength)] mutableCopy];
		extension.text = extensionText;
		
		extension.scaledPosition = CGPointMake (
			cursor, -.2f
			
		);
		
		[self presentSublayer: extension visible: YES];
		// accidental.hidden = NO;
        [extensionText release];
		
	} else {
		if (extension) {
			[self presentSublayer: extension visible: NO];
			// accidental.hidden = YES;
			[extension release];
			extension = nil;
			
		}
		
	}
	
}

//

- (float) width {
	// NSLog (@"serial %@ layouted width %f", serial, layoutedWidth);
	return fmaxf (1.f, (float) textSize.width);
	
}

- (float) fullWidth {
	// NSLog (@"serial %@ layouted width %f", modelObject, 0.f);
	return
		extension != nil ?
			(float) (extension.scaledPosition.x + extension -> textSize.width - 1.f) :
		accidental != nil ?
			(float) (accidental.scaledPosition.x + accidental -> textSize.width - 1.f) :
			self.width - 1;
	
}

//

- (void) dealloc {
	if (accidental)
		[accidental release];
	if (extension)
		[extension release];
	
	[super dealloc];
	
}

@end
