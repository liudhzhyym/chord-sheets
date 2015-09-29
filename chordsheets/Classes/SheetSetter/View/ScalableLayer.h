//
//  SheetLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "RenderQueue.h"
#import "TileRenderQueue.h"


#define RENDER_IN_BACKGROUND_THREAD NO


extern CGPoint renderQueueCenter;


@class SheetScrollView;


@interface ScalableLayer : CALayer {
	
	@protected
	
	NSMutableSet* scalableSublayers;
	
	CGPoint originalPosition;
	float scale;
	
	NSString* colorScheme;
	
	CGPoint localRoundingError;
	
	CGRect localBounds;
	CGRect concatenatedBounds;
	
	BOOL needsRendering;
	BOOL needsUpdateRenderQueueState;
	BOOL childrenNeedUpdateRenderQueueState;
	
	float priority;
	BOOL isInRenderQueue;
	
	id modelObject;
	BOOL isEditable;
	
	ScalableLayer* nextEditableElement;
	ScalableLayer* previousEditableElement;
	
	BOOL needsRecalcConcatenatedBounds;
	
	BOOL didSetUpEditMode;
	

	NSMutableArray* staticTiles;
	
	CGImageRef texture;
	
	
	@public
	
	ScalableLayer* designatedSuperlayer;
	CALayer* persistentParent;
	
	BOOL forceUpdateVisibility;
	
	RenderQueue* renderQueue;
	TileRenderQueue* tileRenderQueue;
	
	BOOL didRenderStatic;
	BOOL didPreRenderStatic;
	
}

- (void) setUpAnimationActions: (NSDictionary*) actions;
+ (NSDictionary*) layoutActions;
+ (NSDictionary*) editingActions;

@property (readwrite) float scale;
@property (readwrite) CGPoint scaledPosition;
- (void) updateScaledPosition;

@property (readonly) ScalableLayer* designatedSuperlayer;
- (void) presentSublayer: (ScalableLayer*) sublayer visible: (BOOL) visibility;

@property (readwrite, retain) NSString* colorScheme;

- (void) setIsEmbossed: (BOOL) doSet;

@property (readonly) CGRect localBounds;
@property (readwrite) BOOL needsRecalcConcatenatedBounds;
@property (readonly) CGRect concatenatedBounds;
@property (readonly) CGRect localBoundsForEditor;
@property (readonly) CGRect concatenatedBoundsForEditor;
@property (readonly) CGRect localBoundsForPlayback;
@property (readonly) CGRect concatenatedBoundsForPlayback;

- (void) updateLayerVisibilityInRect: (CGRect) viewRect;


- (void) renderStatic;
- (CALayer*) staticTileInBounds: (CGRect) rect;
- (void) unrenderStatic;


@property (readwrite) BOOL isEditable;

@property (nonatomic, readwrite, retain) id modelObject;
@property (readonly) id annotationModelObject;

- (void) updateFromModelObject;
- (void) updateLayout;

@property (readwrite, assign) ScalableLayer* nextEditableElement;
@property (readwrite, assign) ScalableLayer* previousEditableElement;

@property (readwrite) BOOL needsRendering;
- (void) setNeedsUpdateRenderQueueState;
@property (readwrite) BOOL childrenNeedUpdateRenderQueueState;
- (void) recursiveSetNeedsUpdateRenderQueueState: (BOOL) parentHidden;
- (void) renderImmediately;
- (void) renderImmediatelyInContext: (CGContextRef) context;
- (void) drawImmediatelyInContext: (CGContextRef) context;

- (RenderQueue*) renderQueue;
@property (readwrite) BOOL isInRenderQueue;
@property (readwrite) float priority;
- (void) updateRenderQueueState: (BOOL) parentHidden;

- (ScalableLayer*) editableLayerUnderPoint: (CGPoint) location;

- (void) enterEditMode;
- (void) leaveEditMode;


@end
