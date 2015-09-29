//
//  TimeSignature.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>


@interface TimeSignature : NSObject <NSCoding, NSCopying> {
	@protected
	
	int numerator;
	int denominator;
	
}

@property (nonatomic, readwrite) int numerator;
@property (nonatomic, readwrite) int denominator;

- (int) chordCountForBar;

- (NSString*) stringValue;
- (void) setStringValue: (NSString*) stringValue;

- (NSString*) toXMLString;

@end