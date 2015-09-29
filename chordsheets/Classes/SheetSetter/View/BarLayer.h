//
//  BarLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 08.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "ParserContext.h"

#import "ScalableLayer.h"
#import "OpeningBarLineLayer.h"
#import "ClosingBarLineLayer.h"

#import "KeySignatureLayer.h"
#import "TimeSignatureLayer.h"

#import "AnnotationLayer.h"


#define DISPLAYS_KEY_SIGNATURES NO


@interface BarLayer : ScalableLayer {
	
	KeySignatureLayer* keySignatureLayer;
	TimeSignatureLayer* timeSignatureLayer;
	
	OpeningBarLineLayer* openingBarLine;
	NSMutableArray* chords;
	ClosingBarLineLayer* closingBarLine;
	
	AnnotationLayer* annotation;
	
	NSString* currentBarLineContextName;
	NSMutableArray* currentBarLineContext;

	@protected
	
	@public
	
	BOOL isLastInLine;
	BOOL isLastInSheet;
	
	BOOL isLocked;
	
	BOOL needsUpdateLayout;
	
	float chordsOffset;
	
	
	@private
	
	float signaturesWidth;
	
	float chordsWidth;
	float chordsDescendantsWidth;
	
	float leftBound;
	
	BOOL needsExpandChords;
	
	// dimension cache
	
	float calculatedInnerWidth;
	BOOL needsRecalculateInnerWidth;
	
	float calculatedInnerWidthIncludingAnnotation;
	BOOL needsRecalculateInnerWidthIncludingAnnotation;
	
	float calculatedWidth;
	BOOL needsRecalculateWidth;
	
	float calculatedWidthIncludingAnnotation;
	BOOL needsRecalculateWidthIncludingAnnotation;
	
	float lastExpadedWidth;
	
}

@property (readonly) KeySignatureLayer* keySignatureLayer;
@property (readonly) TimeSignatureLayer* timeSignatureLayer;

@property (readonly) AnnotationLayer* annotation;

@property (readonly) OpeningBarLineLayer* openingBarLine;
@property (readonly) NSArray* chords;
@property (readonly) ClosingBarLineLayer* closingBarLine;

@property (readonly) float innerWidth;
@property (readonly) float innerWidthIncludingAnnotation;
@property (readonly) float width;
@property (readonly) float widthIncludingAnnotation;
@property (readonly) float height;


+ (float) offsetForBetweenLeft: (BarLayer*) leftBar right: (BarLayer*) rightBar;

- (void) setNeedsUpdateLayout;
- (void) expandToWidth: (float) width spaceToDistribute: (float) space;

@end
