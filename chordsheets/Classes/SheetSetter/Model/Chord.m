//
//  Chord.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Chord.h"

NSString* CHORD_QUALITY_MAJOR = @"major";
NSString* CHORD_QUALITY_MINOR = @"minor";
NSString* CHORD_QUALITY_DIMINISHED = @"diminished";
NSString* CHORD_QUALITY_AUGMENTED = @"augmented";

NSString* CHORD_OPTION_VALUE_2 = @"2";
NSString* CHORD_OPTION_VALUE_4 = @"4";
NSString* CHORD_OPTION_VALUE_FLAT_5 = @"b5";
NSString* CHORD_OPTION_VALUE_5 = @"5";
NSString* CHORD_OPTION_VALUE_SHARP_5 = @"#5";
NSString* CHORD_OPTION_VALUE_6 = @"6";
NSString* CHORD_OPTION_VALUE_7 = @"7";
NSString* CHORD_OPTION_VALUE_MAJOR_7 = @"maj7";
NSString* CHORD_OPTION_VALUE_FLAT_9 = @"b9";
NSString* CHORD_OPTION_VALUE_9 = @"9";
NSString* CHORD_OPTION_VALUE_SHARP_9 = @"#9";
NSString* CHORD_OPTION_VALUE_11 = @"11";
NSString* CHORD_OPTION_VALUE_SHARP_11 = @"#11";
NSString* CHORD_OPTION_VALUE_FLAT_13 = @"b13";
NSString* CHORD_OPTION_VALUE_13 = @"13";

NSString* CHORD_OPTION_VALUE_HALF_DIMINISHED = @"ø";
NSString* CHORD_OPTION_VALUE_SUSPENDED = @"sus";

@interface Chord (Private)

- (NSString*) parseKeyName;
- (NSString*) parseChordQuality;

@end

@implementation Chord

// class initalization

static NSDictionary* chordQualitySymbolTable;
static NSDictionary* inverseChordQualitySymbolTable;

static NSDictionary* keyScaleTable;

static NSArray* chordOptionTable;

static NSDictionary* chordQualityDisplaySymbolTable;
static NSDictionary* chordOptionsDisplaySymbolTable;

static NSSet* chordOptionsToExcludeFromDisplayString;


+ (void) initialize {
	if (!chordQualitySymbolTable) {
		chordQualitySymbolTable = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"", CHORD_QUALITY_MAJOR,
			@"m", CHORD_QUALITY_MINOR,
			@"o", CHORD_QUALITY_DIMINISHED,
			@"+", CHORD_QUALITY_AUGMENTED,
			nil];
		
		inverseChordQualitySymbolTable = [[NSDictionary alloc] initWithObjectsAndKeys:
			CHORD_QUALITY_MAJOR, @"",
			CHORD_QUALITY_MINOR, @"-",
			CHORD_QUALITY_MINOR, @"m",
			CHORD_QUALITY_DIMINISHED, @"o",
			CHORD_QUALITY_DIMINISHED, @"°",
			CHORD_QUALITY_AUGMENTED, @"+",
			
			nil];
		
		keyScaleTable = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"WWHWWWH", CHORD_QUALITY_MAJOR,
			@"WHWWWHW", CHORD_QUALITY_MINOR,
			@"WHWHWHWH", CHORD_QUALITY_DIMINISHED,
			@"WWWWWW", CHORD_QUALITY_AUGMENTED,
			
			@"WWHWWHW", @"domiantSeventh",
			@"WWWHWWH", @"lydian",
			@"HWWHWWW", @"halfDiminished",
			@"WHWHWWW", @"halfDiminishedAlternate",
			@"WWWHWHW", @"lydianDominant",
			@"HWHWHWHW", @"dominantSeventhDiminished",
			@"HWHWWWW", @"diminishedWholeTone",
			@"WWWWHWH", @"lydianAugmented",
			@"WHWWWWH", @"melodicMinor",
			@"WHWWH3H", @"harmonicMinor",
			@"W3WWHW", @"suspendedFourth",
			@"3WHH3W", @"bluesScale",
			
			nil];
		
		chordOptionTable = [[NSArray alloc] initWithObjects:
			CHORD_OPTION_VALUE_2,
			CHORD_OPTION_VALUE_4,
			CHORD_OPTION_VALUE_FLAT_5,
			CHORD_OPTION_VALUE_5,
			CHORD_OPTION_VALUE_SHARP_5,
			
			CHORD_OPTION_VALUE_7,
			CHORD_OPTION_VALUE_MAJOR_7,
			
			CHORD_OPTION_VALUE_6,
			CHORD_OPTION_VALUE_FLAT_9,
			CHORD_OPTION_VALUE_9,
			CHORD_OPTION_VALUE_SHARP_9,
			CHORD_OPTION_VALUE_11,
			CHORD_OPTION_VALUE_SHARP_11,
			CHORD_OPTION_VALUE_FLAT_13,
			CHORD_OPTION_VALUE_13,
			
			CHORD_OPTION_VALUE_HALF_DIMINISHED,
			CHORD_OPTION_VALUE_SUSPENDED,
			
			nil
			
		];
		
		chordOptionsDisplaySymbolTable = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"n", CHORD_OPTION_VALUE_MAJOR_7,
			@"ø", CHORD_OPTION_VALUE_HALF_DIMINISHED,
			@"s", CHORD_OPTION_VALUE_SUSPENDED,
			nil];

		chordQualityDisplaySymbolTable = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"", CHORD_QUALITY_MAJOR,
			@"m", CHORD_QUALITY_MINOR,
			@"o", CHORD_QUALITY_DIMINISHED,
			@"+", CHORD_QUALITY_AUGMENTED,
			nil];
		
		chordOptionsToExcludeFromDisplayString = [[NSSet setWithObjects:
			CHORD_OPTION_VALUE_6,
			CHORD_OPTION_VALUE_7,
			
			nil
			
		] retain];
		
	}
	
}

+ (NSDictionary*) chordQualitySymbolTable {
	return chordQualitySymbolTable;
	
}

// construction

- (id) init {
	if ((self = [super init])) {
		self.chordQuality = nil;
		chordOptions = [[NSMutableSet alloc] init];
		
	}
	return self;
	
}

- (id) initWithCoder: (NSCoder*) coder {
	if ((self = [super init])) {
		key = [[coder decodeObjectForKey: @"key"] retain];
		chordQuality = [[coder decodeObjectForKey: @"chordQuality"] retain];
		bassKey = [[coder decodeObjectForKey: @"bassKey"] retain];
		chordOptions = [[coder decodeObjectForKey: @"chordOptions"] retain];
		
	}
	return self;
	
}
 
- (id) copyWithZone: (NSZone*) zone {
	Chord* instance = [[[self class] allocWithZone: zone] init];
	
    Key *keyCopy = [self.key copyWithZone:zone];
	instance.key = keyCopy;
    [keyCopy release];
    
    for (id option in [self chordOptions]) {
        [instance setChordOption:[NSString stringWithString:(NSString *)option]];
    }
    
    NSString *chordQualityCopy = [self.chordQuality copyWithZone:zone];
	instance.chordQuality = chordQualityCopy;
    [chordQualityCopy release];
    
    Key *bassKeyCopy = [self.bassKey copyWithZone:zone];
	instance.bassKey = bassKeyCopy;
    [bassKeyCopy release];
	
	return instance;
	
}

// properties

- (Key*) key {
	return key;
	
}

- (void) setKey: (Key*) _key {
	if (key == _key)
		return;
	
	[key release];
	key = [_key retain];
	
	if (!key) {
		[self setChordQuality: nil];
		[self removeAllChordOptions];
		[self setBassKey: nil];
		
	}
	
}

- (NSString*) chordQuality {
	return chordQuality;
	
}

- (void) setChordQuality: (NSString*) _chordQuality {
	if (!_chordQuality)
		_chordQuality = CHORD_QUALITY_MAJOR;
	
	if (chordQuality == _chordQuality)
		return;
	
	[chordQuality release];
	chordQuality = [_chordQuality retain];
	
}

- (Key*) bassKey {
	return bassKey;
	
}

- (void) setBassKey: (Key*) _bassKey {
	if (bassKey == _bassKey)
		return;
	
	[bassKey release];
	bassKey = [_bassKey retain];
	
}

- (void) setChordOption: (NSString*) chordOption {
	
	// special options
	
	if ([chordOption isEqualToString: CHORD_OPTION_VALUE_HALF_DIMINISHED]) {
		[self setChordQuality: CHORD_QUALITY_MINOR];
		[self setChordOption: CHORD_OPTION_VALUE_7];
		[self setChordOption: CHORD_OPTION_VALUE_FLAT_5];
		
		return;
		
	}
	
	if ([chordOption isEqualToString: CHORD_OPTION_VALUE_SUSPENDED]) {
		[self setChordQuality: CHORD_QUALITY_MAJOR];
		[self setChordOption: CHORD_OPTION_VALUE_7];
		[self setChordOption: CHORD_OPTION_VALUE_9];
		[self setChordOption: CHORD_OPTION_VALUE_11];
		
		return;
		
	}
	
	// standard options
	
	if ([chordOption isEqualToString: CHORD_OPTION_VALUE_7]) {
		[chordOptions removeObject: CHORD_OPTION_VALUE_MAJOR_7];
		
	} else if ([chordOption isEqualToString: CHORD_OPTION_VALUE_MAJOR_7]) {
		[chordOptions removeObject: CHORD_OPTION_VALUE_7];
		
	} else if ([chordOption isEqualToString: CHORD_OPTION_VALUE_2] ||
		[chordOption isEqualToString: CHORD_OPTION_VALUE_6]) {
		[chordOptions removeObject: CHORD_OPTION_VALUE_7];
		[chordOptions removeObject: CHORD_OPTION_VALUE_MAJOR_7];
		
	} else if ([chordOption isEqualToString: CHORD_OPTION_VALUE_FLAT_9] ||
		[chordOption isEqualToString: CHORD_OPTION_VALUE_9] ||
		[chordOption isEqualToString: CHORD_OPTION_VALUE_SHARP_9] ||
		[chordOption isEqualToString: CHORD_OPTION_VALUE_11] ||
		[chordOption isEqualToString: CHORD_OPTION_VALUE_SHARP_11] ||
		[chordOption isEqualToString: CHORD_OPTION_VALUE_FLAT_13] ||
		[chordOption isEqualToString: CHORD_OPTION_VALUE_13]) {
		if (!([chordOptions containsObject: CHORD_OPTION_VALUE_7] ||
			[chordOptions containsObject: CHORD_OPTION_VALUE_MAJOR_7])) {
			[chordOptions addObject: CHORD_OPTION_VALUE_7];
			
		}
		
	}
	[chordOptions addObject: chordOption];
	
}

- (void) removeChordOption: (NSString*) chordOption {
	
	// special options

	if ([chordOption isEqualToString: CHORD_OPTION_VALUE_HALF_DIMINISHED]) {
		[self setChordQuality: nil];
		[self removeChordOption: CHORD_OPTION_VALUE_7];
		[self removeChordOption: CHORD_OPTION_VALUE_FLAT_5];
		
		return;
		
	}
	
	if ([chordOption isEqualToString: CHORD_OPTION_VALUE_SUSPENDED]) {
		[self removeChordOption: CHORD_OPTION_VALUE_7];
		[self removeChordOption: CHORD_OPTION_VALUE_9];
		[self removeChordOption: CHORD_OPTION_VALUE_11];
		
		return;
		
	}
	
	// standard options
	
	[chordOptions removeObject: chordOption];
	
}

- (void) removeAllChordOptions {
	[chordOptions removeAllObjects];
	
}

- (NSSet*) chordOptions {
	return chordOptions;
	
}

- (NSSet*) keys {
	if (!key)
		return [NSSet set];
	
	NSMutableArray* keys = [NSMutableArray array];
	
	// find quality
	
	int keyValue = key.intValue;
	
	NSString* quality = chordQuality;
	if (!quality || ![quality length])
		quality = CHORD_QUALITY_MAJOR;
	
	// find scale
	
	NSString* keyScaleKey = nil;
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_7]) {
		
		if ([quality isEqualToString: CHORD_QUALITY_MAJOR]) {
			keyScaleKey = @"domiantSeventh";
			
		}
		
	} else if ([chordOptions containsObject: CHORD_OPTION_VALUE_MAJOR_7]) {
		if ([quality isEqualToString: CHORD_QUALITY_MINOR]) {
			keyScaleKey = @"melodicMinor";
			
		} else if ([quality isEqualToString: CHORD_QUALITY_AUGMENTED]) {
			keyScaleKey = @"lydianAugmented";
			
		}
		
	}
	
	if (!keyScaleKey) {
		keyScaleKey = quality;
		
	}
	
	// NSLog (@"%@ using key scale %@", self, keyScaleKey);
	
	NSString* keyScale = [keyScaleTable objectForKey: keyScaleKey];
	
	// build scale (2 octaves)
	
	int scaleCursor = 0;
	NSMutableArray* scaleValues = [NSMutableArray arrayWithObject:
		[NSNumber numberWithInt: scaleCursor]];

	for (int j = 2; j--;) 	
		for (int i = 0; i < [keyScale length]; i++) {
			unichar scaleWidthSymbol = [keyScale characterAtIndex: i];
			scaleCursor += scaleWidthSymbol == '3' ?
				3 : scaleWidthSymbol == 'W' ? 2 : 1;
			
			[scaleValues addObject: [NSNumber numberWithInt: scaleCursor]];
			
		}
	
	// NSLog (@"scale values: %@", scaleValues);

	// build triad
	
	int currentNote;
	int chordCursor = 0;
	for (int i = 0; i < 3; i++) {
		currentNote = [[scaleValues objectAtIndex: chordCursor] intValue] + keyValue;
		if (i == 2 && [chordOptions containsObject: CHORD_OPTION_VALUE_5])
			continue;
		
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		chordCursor = chordCursor + 2;
		
	}
	
	// fix triad
	
	if (![chordOptions containsObject: CHORD_OPTION_VALUE_5]) {
		if ([chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_5]) {
			currentNote = [[keys objectAtIndex: 2] intValue];
			[keys replaceObjectAtIndex: 2 withObject: [NSNumber numberWithInt: currentNote - 1]];
			
		}
		if ([chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_5]) {
			currentNote = [[keys objectAtIndex: 2] intValue];
			[keys replaceObjectAtIndex: 2 withObject: [NSNumber numberWithInt: currentNote + 1]];
			
		}
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_4]) {
		currentNote = keyValue + 5;
		[keys replaceObjectAtIndex: 1 withObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	// options
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_7] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_MAJOR_7]) {
		currentNote = [[scaleValues objectAtIndex: 6] intValue] + keyValue;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_2]) {
		currentNote = keyValue + 2;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_6]) {
		currentNote = keyValue + 9;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}

	// inversion
	
	BOOL needsInvert = NO;
	int bassKeyValue = bassKey.intValue;
	for (int i = (int) [keys count]; i--;) {
		int currentKeyValue = [[keys objectAtIndex: i] intValue];
		if (needsInvert)
			[keys replaceObjectAtIndex: i withObject: [NSNumber numberWithInt: currentKeyValue + 12]];
			// [keys replaceObjectAtIndex: i withObject: [Key keyWithInt: currentKeyValue + 12]];

		// NSLog (@"current key value %i bass key value %i", currentKeyValue, bassKeyValue);
		
		if (bassKey && i && !needsInvert) {
			if (keyValue > bassKeyValue) {
				if (currentKeyValue <= bassKeyValue + 12) {
					// NSLog (@"inv %i", i);
					needsInvert = YES;
					
				}
				
			} else {
				if (currentKeyValue <= bassKeyValue) {
					// NSLog (@"inv %i", i);
					needsInvert = YES;
					
				}
				
			}
			
		}
		
	}
	
	// more options…
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_9]) {
		currentNote = keyValue + 13;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_9]) {
		currentNote = keyValue + 14;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_9]) {
		currentNote = keyValue + 15;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_11]) {
		currentNote = keyValue + 17;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_11]) {
		currentNote = keyValue + 18;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_13]) {
		currentNote = keyValue + 20;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_13]) {
		currentNote = keyValue + 21;
		[keys addObject: [NSNumber numberWithInt: currentNote]];
		
	}
	
	// NSLog (@"keys %@", keys);
	
	return [NSSet setWithArray: keys];
	
}

- (void) stripSlash {
	if ([parsingBuffer characterAtIndex: 0] == '/')
		[parsingBuffer deleteCharactersInRange: NSMakeRange (0, 1)];
	
}

- (void) parseStringValue: (NSString*) serial {
	[self removeAllChordOptions];
	
	serial = [serial stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]
		
	];
	if (![serial length])
		serial = @"/";
	
	parsingBuffer = [serial mutableCopy];
	
	if ([serial isEqualToString: @"/"]) {
		self.key = nil;
		self.chordQuality = nil;
		self.bassKey = nil;
		
	} else {
		NSString* chordNameSerial = [self parseKeyName];
		self.key = [Key keyWithString: chordNameSerial];
		
		NSString* q = [self parseChordQuality];
		//self.chordQuality = q;
		(void) q;
		
		if ([parsingBuffer length]) {
			self.bassKey = [Key keyWithString: [self parseKeyName]];
			
		} else {
			self.bassKey = nil;
			
		}
		
	}
	[parsingBuffer release];
	
}


- (NSString*) parseKeyName {
	[self stripSlash];
	if (![parsingBuffer length])
		return nil;
	
	uint cutIndex = 0;
	NSMutableString* serial = [[parsingBuffer substringToIndex: 1] mutableCopy];
	NSMutableString* secondChar =
		[parsingBuffer length] > 1 ?
			[[parsingBuffer substringWithRange: NSMakeRange (1, 1)] mutableCopy] :
			[@"" retain];
	
	CFStringUppercase ((CFMutableStringRef) serial, CFLocaleGetSystem ());
	CFStringLowercase ((CFMutableStringRef) secondChar, CFLocaleGetSystem ());
	
	if ([secondChar isEqualToString: @"#"] ||
		[secondChar isEqualToString: @"b"]) {
		[serial appendString: secondChar];
		cutIndex = 2;
		
	} else
		cutIndex = 1;
	
	[parsingBuffer deleteCharactersInRange: NSMakeRange (0, cutIndex)];
	
	[secondChar release];
	return [serial autorelease];
	
}

- (NSString*) parseChordQuality {
	if (![parsingBuffer length])
		return nil;
	
	NSString* serial;
	
	NSRange slashIndex = [parsingBuffer rangeOfString: @"/"];
	
	if (slashIndex.location == NSNotFound) {
		serial = [[parsingBuffer copy] autorelease];
		[parsingBuffer setString: @""];
		
	} else {
		serial = [parsingBuffer substringToIndex: slashIndex.location];
		[parsingBuffer deleteCharactersInRange: NSMakeRange (0, slashIndex.location + 1)];
		
	}
	
	// find quality
	
	// NSLog (@"ChordQuality is %@.", serial);
	
	NSRange majorIndex = [serial rangeOfString: @"maj"];
	
	if (majorIndex.location == 0) {
		NSRange major7Index = [serial rangeOfString: @"maj7"];
		self.chordQuality = CHORD_QUALITY_MAJOR;
		
		if (major7Index.location == 0) {
			[self setChordOption: CHORD_OPTION_VALUE_MAJOR_7];
			serial = [serial substringFromIndex: 4];
			
		} else {
			serial = [serial substringFromIndex: 3];
			
		}
		
	} else {
		if ([serial length]) {
			unichar firstChar = [serial characterAtIndex: 0];
			BOOL foundSymbol = NO;
			for (NSString* qualitySymbol in [inverseChordQualitySymbolTable allKeys]) {
				NSString* qualityKey = [inverseChordQualitySymbolTable objectForKey: qualitySymbol];
				if ([qualitySymbol length] && firstChar == [qualitySymbol characterAtIndex: 0]) {
					self.chordQuality = qualityKey;
					// NSLog (@"found key %@", qualityKey);
					foundSymbol = YES;
					serial = [serial substringFromIndex: 1];
					break;
					
				}
				
			}
			if (!foundSymbol)
				self.chordQuality = CHORD_QUALITY_MAJOR;
			
		}
		
	}
	
	// options
	
	if ([serial length]) {
		// NSLog (@"remaining options %@", serial);
		
		NSMutableString* optionBuffer = [NSMutableString string];
		
		while ([serial length]) {
			[optionBuffer appendString: [serial substringWithRange: NSMakeRange (0, 1)]];
			serial = [serial substringFromIndex: 1];
			
			if ([optionBuffer length] == 1) {
				if ([optionBuffer characterAtIndex: 0] == ' ' ||
					[optionBuffer characterAtIndex: 0] == '|' ||
					[optionBuffer characterAtIndex: 0] == ',') {
					[optionBuffer setString: @""];
					continue;
					
				}
				
			}
			for (NSString* option in chordOptionTable) {
				if ([optionBuffer isEqualToString: option]) {
					[self setChordOption: option];
					[optionBuffer setString: @""];
					break;
					
				}
				
			}
			
		}
		
	}
	return serial;
	
}

- (NSString*) stringValueForKeySignature: (KeySignature*) keySignature {
	NSMutableString* buffer = [NSMutableString string];
	
	[buffer appendString: [key stringValueForKeySignature: keySignature]];
	if (chordQuality)
		[buffer appendString: chordQuality];
	
	if ([chordOptions count]) {
		for (NSString* optionKey in chordOptionTable) {
			if ([chordOptions containsObject: optionKey]) {
				if ([buffer length])
					[buffer appendString: @" "];
				[buffer appendString: optionKey];
				
			}
			
		}
		
	}
	
	if (bassKey) {
		[buffer appendString: @"/"];
		[buffer appendString: [bassKey stringValueForKeySignature: keySignature]];
		
	}
	return buffer;
	
}

- (BOOL) isEmpty {
	return !key;
	
}

- (NSString*) chordOptionsSerialString {
	NSMutableString* buffer = [NSMutableString string];
	
	if (chordQuality)
		[buffer appendString: [chordQualitySymbolTable objectForKey: chordQuality]];
	
	if ([chordOptions count]) {
		for (NSString* optionKey in chordOptionTable) {
			if ([chordOptions containsObject: optionKey]) {
				[buffer appendString: optionKey];
				
			}
			
		}
		
	}
	// NSLog (@"flushing buffer %@", buffer);
	
	return buffer;
	
}

- (NSString*) chordQualityDisplayString {
	NSMutableString* buffer = [NSMutableString string];
	
	NSString* localChordQuality = [chordQualityDisplaySymbolTable objectForKey: chordQuality];
	
	NSMutableSet* optionTable = nil;
	if ([chordOptions count]) {
		optionTable = [chordOptions mutableCopy];
		
		if ([optionTable containsObject: CHORD_OPTION_VALUE_7]) {
			if ([chordQuality isEqualToString: CHORD_QUALITY_MINOR] &&
				[chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_5]) {

				localChordQuality = @"ø";
				[optionTable removeObject: CHORD_OPTION_VALUE_7];
				[optionTable removeObject: CHORD_OPTION_VALUE_FLAT_5];
				
			} else if (
				[chordQuality isEqualToString: CHORD_QUALITY_MAJOR] &&
				[chordOptions containsObject: CHORD_OPTION_VALUE_9] &&
				[chordOptions containsObject: CHORD_OPTION_VALUE_11]) {
				
				localChordQuality = @"s";
				[optionTable removeObject: CHORD_OPTION_VALUE_7];
				[optionTable removeObject: CHORD_OPTION_VALUE_9];
				[optionTable removeObject: CHORD_OPTION_VALUE_11];
				
			} else if (
				[chordOptions containsObject: CHORD_OPTION_VALUE_9] &&
				[chordOptions containsObject: CHORD_OPTION_VALUE_13]) {
				
				[optionTable removeObject: CHORD_OPTION_VALUE_7];
				[optionTable removeObject: CHORD_OPTION_VALUE_9];
				
			}
			
		}
		
	}
	
	if (excludedOptionsFromDisplayString)
		[excludedOptionsFromDisplayString release];
	excludedOptionsFromDisplayString = [NSMutableArray new];
	
	
	if (localChordQuality != nil) {
		// [buffer appendString: localChordQuality];
		[excludedOptionsFromDisplayString addObject: localChordQuality];
		
	}
	
	if (optionTable && [optionTable count]) {
		
		NSArray* optionList = [[optionTable allObjects] sortedArrayUsingComparator: ^NSComparisonResult (NSString* a, NSString* b) {
			int indexA = (int) [chordOptionTable indexOfObject: a];
			int indexB = (int) [chordOptionTable indexOfObject: b];
			return indexA < indexB ? -1 : indexA == indexB ? 0 : 1;
			
		}];
		
		for (NSString* optionKey in optionList) {
			// NSLog(@"analyze %@", optionKey);
			if ([chordOptionsToExcludeFromDisplayString containsObject: optionKey]) {
				[excludedOptionsFromDisplayString addObject: optionKey];
				// NSLog(@"added %@", optionKey);
				continue;
				
			}
			
			if ([buffer length])
				[buffer appendString: @"l"];
			
			NSString* displaySymbol = [chordOptionsDisplaySymbolTable objectForKey: optionKey];
			[buffer appendString: displaySymbol ? displaySymbol : [optionKey stringByReplacingOccurrencesOfString: @"b" withString: @"q"]];
			
		}
		
	}
	[optionTable release];
	// NSLog (@"flushing buffer %@", buffer);
	// NSLog (@"exposing options: %@", excludedOptionsFromDisplayString);
	
	return buffer;
	
}

- (NSString*) keyDisplayStringExtension {
	NSMutableString* buffer = [NSMutableString new];
	
	for (NSString* optionKey in excludedOptionsFromDisplayString) {
		NSString* displaySymbol = [chordOptionsDisplaySymbolTable objectForKey: optionKey];
		[buffer appendString: displaySymbol ? displaySymbol : [optionKey stringByReplacingOccurrencesOfString: @"b" withString: @"q"]];
		
	}
	
	return [buffer autorelease];
	
}

- (NSString*) description {
	return [NSString stringWithFormat: @"<Chord %@%@ %@/%@>",
		self.key, self.chordQuality, self.chordOptions, self.bassKey];
	
}

// serialization

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeObject: key forKey: @"key"];
	[coder encodeObject: chordQuality forKey: @"chordQuality"];
	[coder encodeObject: bassKey forKey: @"bassKey"];
	[coder encodeObject: chordOptions forKey: @"chordOptions"];
	
}

// deallocation

- (void) dealloc {
	if (key)
		[key release];
	if (chordQuality)
		[chordQuality release];
	if (bassKey)
		[bassKey release];
	if (chordOptions)
		[chordOptions release];
	
	if (excludedOptionsFromDisplayString)
		[excludedOptionsFromDisplayString release];
	
	[super dealloc];
	
}



@end
