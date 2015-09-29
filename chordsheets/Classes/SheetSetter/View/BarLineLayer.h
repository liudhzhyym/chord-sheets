//
//  BarLine.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "ScalableLayer.h"

#import "BoundedBitmapLayer.h"
#import "TextLayer.h"



#define LABEL_BASE_SIZE 16
#define BASELINE_HEIGHT .54f

#define REPEAT_COUNT_LABEL_SIZE_FACTOR 1.6
#define REHEARSAL_MARK_LABEL_SIZE_FACTOR 3
#define CODA_MARK_LABEL_SIZE_FACTOR 3


@interface BarLineLayer : ScalableLayer {
	
	TextLayer* barLineSymbol;
	
}

@property (readonly) TextLayer* barLineSymbol;
@property (readonly) float width;

+ (float) offsetForBetweenLeft: (BarLineLayer*) leftBar right: (BarLineLayer*) rightBar;


@end
