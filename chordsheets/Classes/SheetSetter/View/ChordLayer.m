//
//  ChordLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Chord.h"
#import "AttributedChord.h"

#import "ChordLayer.h"

#import "BoundedBitmapLayer.h"


#define ENABLE_SHADOW NO
#define ENABLE_SEPARATOR YES


#define SHADOW_Y_OFF 28
#define SEPARATOR_Y_OFF 28



@implementation ChordLayer


const float yOff = -18.f - 2;

- (id) init {
	if ((self = [super init])) {
		
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.anchorPoint = CGPointMake (0, 0);
		
		self.isEditable = YES;
		
		if (ENABLE_SHADOW || ENABLE_SEPARATOR)
			shadowLayer = [BoundedBitmapLayer layer];
		
		// self.shouldRasterize = YES;
		
	}
	return self;
	
}

extern NSString *SHEET_COLOR_SCHEME_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_NEGATIVE;
extern NSString *SHEET_COLOR_SCHEME_PRINT;

extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE;


- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[super setColorScheme: _colorScheme];
	
	if (ENABLE_SHADOW) {
		if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE] ||
			[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE] ||
			[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE])
			[shadowLayer loadBundleImage: @"ChordShadow.png"];
		else
			[shadowLayer loadBundleImage: @"ChordShadow_negative.png"];
		
		shadowLayer.scaledSize = CGSizeMake (
			shadowLayer.scaledSize.width, 56 - 4 + 1 - SHADOW_Y_OFF
			
		);
		[self addSublayer: shadowLayer];
		
	} else if (ENABLE_SEPARATOR) {
		shadowLayer -> lockTextureScale = YES;
		
		if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE] ||
			[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE] ||
			[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PRINT])
			[shadowLayer loadBundleImage: @"ChordSeparator_positive.png"];
		else
			[shadowLayer loadBundleImage: @"ChordSeparator_negative.png"];
		
		shadowLayer.scaledSize = CGSizeMake (
			8.f, 72 - 4 + 1 - SHADOW_Y_OFF
			
		);
		[self addSublayer: shadowLayer];
		
	}
	
}

- (void) setScale: (float) _scale {
	// self.shouldRasterize = _scale < 1;
	[super setScale: _scale];
	
}

@synthesize chordName;
@synthesize chordQuality;
@synthesize slash;
@synthesize bassKey;
@synthesize syncopation;

@synthesize shadowLayer;

//

- (void) updateFromModelObject {
	AttributedChord* chord = modelObject;
	NSString* chordQualityText = [chord chordQualityDisplayString];
	
	if (chord.key && [chord.key.stringValue length]) {
		if (!chordName) {
			chordName = [ExtendedKeyLayer layer];
			chordName.fontSize = 16 * 3;
			chordName.scaledPosition = CGPointMake (0, -3 + yOff);
			[self presentSublayer: chordName visible: YES];
			
		}
		chordName.keyExtension = [chord keyDisplayStringExtension];
		chordName.modelObject = chord.key;
		
	} else {
		if (chordName) {
			[chordName removeFromSuperlayer];
			[scalableSublayers removeObject: chordName];
			chordName = nil;
			
		}
		chord.bassKey = nil;
		chord.isSyncopic = false;
		chord.chordQuality = nil;
		[chord removeAllChordOptions];
		
	}
	
	int chordQualityTextLength = (int) [chordQualityText length];
	
	if (chord.key && [chord.key.stringValue length] && chordQualityTextLength > 0) {
		if (!chordQuality) {
			chordQuality = [ChordQualityLayer layer];
			chordQuality.fontSize = 16 * 2;
			chordQuality.fontName = @"iDBsheet-Regular";
			chordQuality.scaledPosition = CGPointMake (0, (CGFloat) (-3 + 5 + yOff + 7.35 + .15f));
			
		}
		[chordQuality setText: chordQualityText];
		[self presentSublayer: chordQuality visible: YES];
		
	} else {
		if (chordQuality) {
			[chordQuality removeFromSuperlayer];
			[scalableSublayers removeObject: chordQuality];
			chordQuality = nil;
			
		}
		
	}
	
	if (chord.bassKey) {
		if (!bassKey) {
			bassKey = [KeyLayer layer];
			bassKey.fontSize = 14 * 3;
			bassKey.scaledPosition = CGPointMake (0 - 30 + 14 + 0, 14 + 1 + yOff + 4);
			
			slash = [TextLayer layer];
			slash -> cropY = .35f;
			slash.fontName = @"iDBsheet-Regular";
			slash.fontSize = 16 * 3;
			slash.text = @"/";
			slash.scaledPosition = CGPointMake (0.f - 1.f -31 - 14, 7.f - 7 + yOff + 4 + 1);
			
		}
		bassKey.modelObject = chord.bassKey;
		[self presentSublayer: bassKey visible: !!chord.bassKey];
		[self presentSublayer: slash visible: !!chord.bassKey];
		
	} else {
		if (bassKey) {
			[bassKey removeFromSuperlayer];
			[scalableSublayers removeObject: bassKey];
			//[bassKey release];
			bassKey = nil;
			
			[slash removeFromSuperlayer];
			[scalableSublayers removeObject: slash];
			//[slash release];
			slash = nil;
			
		}
		
	}
	
	if (chord.isSyncopic) {
		if (!syncopation) {
			syncopation = [TextLayer layer];
			syncopation.fontName = @"iDBsheet-Regular";
			syncopation.fontSize = 16 * 3;
			syncopation.text = @"Y";
			syncopation.scaledPosition = CGPointMake (0.f - 10.f + 1 + .25, 7.f - 7 + yOff);
			
		}
		[self presentSublayer: syncopation visible: YES];
		
	} else {
		if (syncopation) {
			[syncopation removeFromSuperlayer];
			[scalableSublayers removeObject: syncopation];
			[syncopation release];
			syncopation = nil;
			
		}
		
	}
	
	[self updateLayout];
	
}

//

- (void) updateLayout {
	
	NSString* chordNameText = ((Key*) chordName.modelObject).stringValue;
	
	BOOL chordNameHasAccidental = chordName.accidental != nil;
	BOOL chordNameHasExtension = chordName.keyExtension != nil;
	
	NSString* chordQualityText = chordQuality.text;
	UniChar chordQualityChar = [chordQualityText length] ? [chordQualityText characterAtIndex: 0] : 0x0;
	
	UniChar chordAccidental = [chordNameText length] > 1 ? [chordNameText characterAtIndex: 1] : 0x0;
	UniChar chordNote = !chordAccidental && [chordNameText length] ? [chordNameText characterAtIndex: 0] : 0x0;
	
	
	float qualityXOff = .5;
	if (chordNameHasAccidental) {
		
		if (chordAccidental == '#')
			qualityXOff -= .35 - .5;
		else
			qualityXOff -= 1. - .5;
		
		if (chordQualityChar == 'o' ||
			chordQualityChar == 248) // ø
			qualityXOff -= 2.5 - .5;
		
		if (chordQualityChar == 'm' ||
			chordQualityChar == 110) // maj7
			qualityXOff -= 2. - .5;

		if (chordQualityChar == '+')
			qualityXOff -= 3. - .5;
		
		if (chordQualityChar == '4') {
			if (chordAccidental == '#')
				qualityXOff -= 1.5;
			else
				qualityXOff -= 2;
			
		}
		
	} else if (chordNameHasExtension) {
		NSString* extensionText = chordName.keyExtension;
		UniChar extensionLastChar = [extensionText length] > 0 ?
			[extensionText characterAtIndex: [extensionText length] - 1] : 0x0;
		
		if (extensionLastChar == '7') {
			if (chordQualityChar == 'm')
				qualityXOff -= 1.25;
			if (chordQualityChar == '#')
				qualityXOff -= .4;
			else if (chordQualityChar == 'q')
				qualityXOff += .25;
			
		} else {
			qualityXOff += .25;
			
		}
		
	} else {
		if ([chordNameText isEqualToString: @"A"]) {
			if (chordQualityChar == 'o')
				qualityXOff -= 2.25 - 1.75;
			else if (chordQualityChar == '4')
				qualityXOff -= .5;
			else
				qualityXOff -= 1.75 - 1.75 + .5;
			
		}
		
	}
	chordQuality.scaledPosition = CGPointMake (chordName.fullWidth - .5f + qualityXOff, chordQuality.scaledPosition.y);
	
	float slashXOff =
		chordNote == 'A' ? -.5 :
		chordNote == 'F' ? -3 :
		chordNote == 'E' ? 0 : -2;
	
//NSLog(@"chordName.text %@", chordName.text);
//NSLog(@"SLASH X-OFF %f", slashXOff);
	
	slash.scaledPosition = CGPointMake (
		(CGFloat) (chordName.width - 5.f - 30 + 30 + slashXOff - 3 - 1.5),
		slash.scaledPosition.y
		
	);
	
	UniChar bassNote = [bassKey.text length] ? [bassKey.text characterAtIndex: 0] : 0x0;
	slashXOff +=
		bassNote == 'A' ? -1.75 :
		bassNote == 'C' || bassNote == 'G' ? 0 : 1.5;
	bassKey.scaledPosition = CGPointMake (chordName.width - 3 - 27 + 30 + slashXOff - 4 + 1, bassKey.scaledPosition.y);
	
	float selfWidth = self.width;
	
	if (ENABLE_SHADOW) {
		shadowLayer.scaledPosition = CGPointMake (
			selfWidth - 10 + 1, -18 + SHADOW_Y_OFF
			
		);
		
	} else if (ENABLE_SEPARATOR) {
		shadowLayer.scaledPosition = CGPointMake (
			selfWidth + 1, -24 -10 + SHADOW_Y_OFF
			
		);
		
	}
	
	self -> localBounds = CGRectMake (
		0, 0, selfWidth, 32
		
	);
	
}

- (float) fullWidth {
	return self.width;
	
}

- (CGRect) localBoundsForPlayback {
	CGRect bounds = self.localBoundsForEditor;
	
	bounds.origin.y = -19;
	
	bounds.size.width += 2;
	bounds.size.height = 54;
	
	return bounds;
	
}

//

#define MIN_WIDTH 8

- (float) width {
	float rightBound = chordName.fullWidth;
	
	if ([chordQuality.text length])
		rightBound = (float) chordQuality.scaledPosition.x + chordQuality.width;
	
	if (!slash.hidden)
		rightBound = fmaxf (rightBound,
			(float) bassKey.scaledPosition.x + bassKey.fullWidth);
	
	return fmaxf (MIN_WIDTH, rightBound + 1);
	
}

- (float) height {
	return 48.f;
	
}

//

- (void) dealloc {
	[super dealloc];
	
}

@end
