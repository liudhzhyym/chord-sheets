//
//  OpeningBarLine.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "BarLine.h"

#import "KeySignature.h"
#import "TimeSignature.h"


extern NSString *BAR_LINE_BAR_MARK_WHOLE_REST;
extern NSString *BAR_LINE_BAR_MARK_SIMILE;
extern NSString *BAR_LINE_BAR_MARK_TWO_BAR_SIMILE;

@interface OpeningBarLine : BarLine {
	
	@protected

	KeySignature* keySignature;
	TimeSignature* timeSignature;
	
	NSString* annotation;
	int voltaCount;
	
	NSString* barMark;
	
}

@property (nonatomic, readwrite, retain) KeySignature* keySignature;
@property (nonatomic, readwrite, retain) TimeSignature* timeSignature;

@property (nonatomic, readwrite, retain) NSString* annotation;

@property (nonatomic, readwrite) int voltaCount;

@property (nonatomic, readwrite, retain) NSString* barMark;

@property (nonatomic, readonly) BOOL clearsBar;
@property (nonatomic, readonly) BOOL clearsNextBar;

@end
