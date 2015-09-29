//
//  ChordLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "ParserContext.h"

#import "ScalableLayer.h"

#import "KeyLayer.h"
#import "ExtendedKeyLayer.h"
#import "ChordQualityLayer.h"


@class BoundedBitmapLayer;


@interface ChordLayer : ScalableLayer {
	
	@public
	
	BoundedBitmapLayer* shadowLayer;
	
	ExtendedKeyLayer* chordName;
	ChordQualityLayer* chordQuality;
	
	KeyLayer* bassKey;
	TextLayer* slash;
	
	TextLayer* syncopation;
	
	NSMutableString* buffer;
	
	float barOffset;
	
}

@property (readonly) KeyLayer* chordName;
@property (readonly) ChordQualityLayer* chordQuality;
@property (readonly) TextLayer* slash;
@property (readonly) KeyLayer* bassKey;

@property (readonly) TextLayer* syncopation;

@property (readonly) BoundedBitmapLayer* shadowLayer;

@property (readonly) float width;
@property (readonly) float height;

@property (readonly) float fullWidth;


@end
