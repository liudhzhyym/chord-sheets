//
//  AttributedKey.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "Chord.h"


@interface AttributedChord : Chord {
	
	@protected
	
	NSString* annotation;
	BOOL isSyncopic;
	
}

@property (nonatomic, readwrite, retain) NSString* annotation;
@property (nonatomic, readwrite) BOOL isSyncopic;

- (NSString*) toXMLString;

@end