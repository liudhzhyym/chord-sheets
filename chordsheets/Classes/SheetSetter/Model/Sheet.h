//
//  Sheet.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "ParserContext.h"


@class Bar;

@class TimeSignature;
@class KeySignature;


@interface Sheet : NSObject <NSCoding, NSCopying> {
	
	@protected
	
	NSString* title;
	NSString* artist;
	NSString* composer;
	
	NSString* copyright;
	
	float tempo;
	
	@public
	
	NSMutableArray* bars;
	
	BOOL didChange;
	
	@private
	
	TimeSignature* currentTimeSignature;
	Bar* currentProcessingBar;
	
}

@property (nonatomic, readwrite, retain) NSString* title;
@property (nonatomic, readwrite, retain) NSString* artist;
@property (nonatomic, readwrite, retain) NSString* composer;
@property (nonatomic, readwrite, retain) NSString* copyright;

@property (nonatomic, readwrite) float tempo;

@property (nonatomic, readwrite, retain) NSArray* bars;


- (void) registerWithParserContext: (ParserContext*) parserContext;

- (NSString*) toXMLString;


@end


@interface Sheet (Editing)

/*
@property (readonly) id currentElement;

- (void) commitChangeToCurrentElement;
@property (readonly) BOOL didChange;

- (void) goForward;
- (void) goBack;

- (BOOL) isFirstElement: (id) element;

- (BOOL) keySignatureDoesChangeAfterCurrentPosition;
- (void) transposeFromCurrentPositionUsing: (KeySignature*) targetKeySignature transposeToEnd: (BOOL) transposeToEnd;
*/

@end
