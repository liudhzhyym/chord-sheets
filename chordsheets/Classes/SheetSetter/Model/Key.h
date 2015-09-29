//
//  Key.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

@class KeySignature;

@interface Key : NSObject <NSCoding, NSCopying> {
	
	@protected
	
	int intValue;
	NSString* stringValue;
	
}

+ (id) keyWithInt: (int) value;
+ (id) keyWithString: (NSString*) value;

- (id) initWithInt: (int) value;
- (id) initWithString: (NSString*) value;

@property (readwrite) int intValue;

- (NSString*) stringValueForKeySignature: (KeySignature*) keySignature;

- (NSString*) stringValue;
- (void) setStringValue: (NSString*) value;

@end

