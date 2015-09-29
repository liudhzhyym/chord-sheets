//
//  TileRenderJob.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 09.03.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "ScalableLayer.h"


typedef enum {
	
	STATE_IDLE = 0,
	STATE_BUSY

} State;


extern CGPoint renderQueueCenter;


@interface TileRenderJob : NSObject {
	
	@protected
	
	ScalableLayer* sourceLayer;
	CGRect sourceBounds;
	CGRect localSourceBounds;
	float sourceScale;
	CALayer* targetLayer;
	
	CALayer* placeholderLayer;
	
	State state;
	NSRecursiveLock* stateLock;
	
	@public
	
	BOOL doNotUpdateLayerVisibility;
	
}

- (id) initWithSourceLayer: (ScalableLayer*) sourceLayer bounds: (CGRect) bounds
	targetLayer: (CALayer*) targetLayer;

@property (readwrite) State state;
@property (readonly) float priority;

- (void) startProcess;


@end
