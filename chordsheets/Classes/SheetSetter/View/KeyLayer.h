//
//  KeyLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "TextLayer.h"


@interface KeyLayer : TextLayer {
	
	TextLayer* accidental;
	TextLayer* extension;
	
}

@property (readonly) TextLayer* accidental;
@property (readonly) TextLayer* extension;

@property (readonly) float width;
@property (readonly) float fullWidth;

@end
