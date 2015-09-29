//
//  TileRenderJob.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 09.03.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import "TileRenderJob.h"


@interface TileRenderJob (Private)

@end


@implementation TileRenderJob

CGColorRef placeholderColour = nil;

- initWithSourceLayer: (ScalableLayer*) _sourceLayer bounds: (CGRect) _sourceBounds
	targetLayer: (CALayer*) _targetLayer {
	
	if ((self = [super init])) {
		sourceLayer = [_sourceLayer retain];
		sourceBounds = _sourceBounds;
		sourceScale = sourceLayer.scale;
		localSourceBounds = CGRectMake (
			sourceBounds.origin.x / sourceScale,
			sourceBounds.origin.y / sourceScale,
			sourceBounds.size.width / sourceScale,
			sourceBounds.size.height / sourceScale
			
		);
		targetLayer = _targetLayer;
		
		placeholderLayer = [CALayer layer];
		placeholderLayer.backgroundColor = placeholderColour ?
			placeholderColour : [UIColor colorWithRed:0 green:1 blue:0 alpha:1].CGColor;
		placeholderLayer.anchorPoint = CGPointMake (0, 0);
		placeholderLayer.bounds = _sourceBounds;
		placeholderLayer.position = _sourceBounds.origin;
		placeholderLayer.opaque = YES;
		
		[targetLayer addSublayer: placeholderLayer];
		
		stateLock = [[NSRecursiveLock alloc] init];
		
	}
	return self;
	
}


extern CGRect currentViewRect;

- (float) priority {
	
	CGRect bounds = sourceBounds;
	CGPoint center = CGPointMake (
		(bounds.origin.x + bounds.size.width / 2) / sourceScale,
		(bounds.origin.y + bounds.size.height / 2) / sourceScale
		
	);
	
	center.x -= renderQueueCenter.x;
	center.y -= renderQueueCenter.y;
	
	float priority = (float) -sqrt (
		center.x * center.x +
		center.y * center.y
		
	);
	
	return priority + (CGRectIntersectsRect (localSourceBounds, currentViewRect) ? 8192 : 0);
	
}

@synthesize state;

- (void) startProcess {
	
	state = STATE_BUSY;
	
	[CATransaction lock];
	
	if (!doNotUpdateLayerVisibility) {
		[CATransaction setDisableActions: YES];
		
		[sourceLayer updateLayerVisibilityInRect: CGRectMake (
			sourceBounds.origin.x / sourceScale,
			sourceBounds.origin.y / sourceScale,
			sourceBounds.size.width / sourceScale,
			sourceBounds.size.height / sourceScale
			
		)];
		[sourceLayer renderImmediately];
		
		[CATransaction setDisableActions: NO];
		
	}
	
	CALayer* staticTile = [sourceLayer staticTileInBounds: sourceBounds];
	[targetLayer addSublayer: staticTile];
	
	[placeholderLayer removeFromSuperlayer];
	
	[CATransaction unlock];
	
	state = STATE_IDLE;
	
}

- (void) dealloc {
	
	[sourceLayer release];
	[stateLock release];
	
	[super dealloc];
	
}

@end
