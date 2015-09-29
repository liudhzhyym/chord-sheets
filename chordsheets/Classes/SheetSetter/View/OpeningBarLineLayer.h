//
//  OpeningBarLineLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 08.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>

#import "BarLineLayer.h"

@interface OpeningBarLineLayer : BarLineLayer {
	
	TextLayer* rehearsalMark;
	TextLayer* voltaMark;
	
	TextLayer* barMark;
	
}

@property (readonly) TextLayer* rehearsalMark;
@property (readonly) TextLayer* voltaMark;
@property (readonly) TextLayer* barMark;

- (float) insetOfNarrowBar;

@end
