//
//  KeySignature.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "Key.h"


@interface KeySignature : NSObject <NSCoding, NSCopying> {
	
	@protected
	
	Key* key;
	BOOL isMinor;
	
	BOOL useFlatKeyTable;
	
}

- (id) initWithKey: (Key*) key isMinor: (BOOL) isMinor;

@property (nonatomic, readwrite, retain) Key* key;
@property (nonatomic, readwrite) BOOL isMinor;

- (NSString*) stringValue;
- (void) setStringValue: (NSString*) stringValue;

- (NSString*) displayStringValue;

- (NSString*) toXMLString;

- (NSString*) stringValueOfKey: (Key*) key;

@end