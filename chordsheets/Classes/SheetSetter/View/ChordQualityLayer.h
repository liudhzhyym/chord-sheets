//
//  ChordQualityLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "TextLayer.h"


@interface ChordQualityLayer : TextLayer {
	NSString* serial;
	
}

@property (readonly) float width;

@property (readwrite, retain) NSString* serial;

- (void) parseSerial: (NSString*) serial;

@end
