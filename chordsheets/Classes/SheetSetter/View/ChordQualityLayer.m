//
//  ChordQualityLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 10.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "ChordQualityLayer.h"


@implementation ChordQualityLayer

- (id) init {
	if ((self = [super init])) {
		cropY = .275f;
		
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.anchorPoint = CGPointMake (0, 0);
		
		self.fontName = @"Helvetica";
		self.fontSize = 12;
		
	}
	return self;
	
}

@synthesize serial;

- (void) parseSerial: (NSString*) _serial {
	self.serial = _serial;
	self.text = [_serial stringByReplacingOccurrencesOfString: @"-" withString: @"m"
		options: 0 range: NSMakeRange (0, [_serial length])];
	
}

//

- (float) width {
	// NSLog (@"layouted width %f", layoutedWidth);	
	return fmaxf (0.f, (float) textSize.width);
	
}

//

- (void) dealloc {

	[super dealloc];

}

@end
