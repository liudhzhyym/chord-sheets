//
//  TimeSignatureLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "ScalableLayer.h"

#import "TextLayer.h"


@interface TimeSignatureLayer : ScalableLayer {
	
	TextLayer* numeratorLayer;
	TextLayer* denominatorLayer;
	
}

@property (readonly) float width;

@end
