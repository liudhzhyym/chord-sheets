//
//  KeySignatureLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "ScalableLayer.h"


@interface KeySignatureLayer : ScalableLayer {
	
	NSMutableArray* accidentials;
	
	int accidentalCount;
	unichar accidentalChar;
	
}

@property (readonly) float width;

@end
