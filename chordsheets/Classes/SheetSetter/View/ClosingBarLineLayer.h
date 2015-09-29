//
//  ClosingBarLineLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 08.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>

#import "BarLineLayer.h"

@interface ClosingBarLineLayer : BarLineLayer {
	
	TextLayer* repeatCountLabel;
	
	TextLayer* codaMark;
	TextLayer* dcMark;
	TextLayer* fineMark;	
	
}

@property (readonly) TextLayer* repeatCountLabel;

- (float) rehearsalMarksCombinedWidth;

@property (readonly) float overlappingRight;

@end
