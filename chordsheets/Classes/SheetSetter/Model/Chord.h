//
//  Chord.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "Key.h"


extern NSString *CHORD_QUALITY_MAJOR;
extern NSString *CHORD_QUALITY_MINOR;
extern NSString *CHORD_QUALITY_DIMINISHED;
extern NSString *CHORD_QUALITY_AUGMENTED;

extern NSString *CHORD_OPTION_VALUE_2;
extern NSString *CHORD_OPTION_VALUE_4;
extern NSString *CHORD_OPTION_VALUE_FLAT_5;
extern NSString *CHORD_OPTION_VALUE_5;
extern NSString *CHORD_OPTION_VALUE_SHARP_5;
extern NSString *CHORD_OPTION_VALUE_6;
extern NSString *CHORD_OPTION_VALUE_7;
extern NSString *CHORD_OPTION_VALUE_MAJOR_7;
extern NSString *CHORD_OPTION_VALUE_FLAT_9;
extern NSString *CHORD_OPTION_VALUE_9;
extern NSString *CHORD_OPTION_VALUE_SHARP_9;
extern NSString *CHORD_OPTION_VALUE_11;
extern NSString *CHORD_OPTION_VALUE_SHARP_11;
extern NSString *CHORD_OPTION_VALUE_13;
extern NSString *CHORD_OPTION_VALUE_FLAT_13;

extern NSString* CHORD_OPTION_VALUE_HALF_DIMINISHED;
extern NSString* CHORD_OPTION_VALUE_SUSPENDED;


@interface Chord : NSObject <NSCoding, NSCopying> {
	
	@public
	
	NSMutableArray* excludedOptionsFromDisplayString;
	
	@protected
	
	Key* key;
	NSString* chordQuality;
	Key* bassKey;
	
	NSMutableSet* chordOptions;
	
	@private
	
	NSMutableString* parsingBuffer;
	
}

@property (nonatomic, readwrite, retain) Key* key;
@property (nonatomic, readwrite, retain) NSString* chordQuality;
@property (nonatomic, readwrite, retain) Key* bassKey;

- (void) setChordOption: (NSString*) chordOption;
- (void) removeChordOption: (NSString*) chordOption;
- (void) removeAllChordOptions;

@property (nonatomic, readonly) NSSet* chordOptions;

@property (nonatomic, readonly) NSSet* keys;

- (BOOL) isEmpty;

- (NSString*) keyDisplayStringExtension;

- (NSString*) chordOptionsSerialString;
- (NSString*) chordQualityDisplayString;

- (void) parseStringValue: (NSString*) serial;
- (NSString*) stringValueForKeySignature: (KeySignature*) keySignature;

+ (NSDictionary*) chordQualitySymbolTable;

@end