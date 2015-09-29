//
//  CopyrightLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 08.03.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import "CopyrightLayer.h"


@implementation CopyrightLayer

- (void) setNeedsRendering: (BOOL) _needsRendering {
	[super setNeedsRendering: _needsRendering];
	
}

- (void) renderImmediately {
	if (isInRenderQueue)
		[self.renderQueue removeFromQueue: self];
	
	if (needsRendering) {
		needsRendering = NO;
		[self setNeedsDisplay];
		
	}
	
	for (ScalableLayer* sublayer in scalableSublayers)
		[sublayer renderImmediately];
	
}

- (void) drawInContext: (CGContextRef) context {
	[super drawInContext: context];
	
}

@end
