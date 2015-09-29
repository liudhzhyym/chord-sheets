//
//  ScalableLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 03.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "ScalableLayer.h"


@implementation ScalableLayer


NSDictionary* layoutActions;
NSDictionary* editingActions;

CGFloat screenScale;

+ (void) initialize {
	if (!layoutActions) {
		layoutActions =
			[[NSDictionary alloc] initWithObjectsAndKeys:
				[NSNull null], @"onOrderIn",
				[NSNull null], @"onOrderOut",
				[NSNull null], @"sublayers",
//				[NSNull null], @"contents",
				[NSNull null], @"bounds",
				[NSNull null], @"position",
			nil];
		
		editingActions =
			[[NSDictionary alloc] initWithObjectsAndKeys:
				[NSNull null], @"onOrderIn",
				[NSNull null], @"onOrderOut",
				[NSNull null], @"sublayers",
//				[NSNull null], @"contents",
				[NSNull null], @"bounds",
			nil];
		
		screenScale = [UIScreen mainScreen].nativeScale;
		
	}
	
}

+ (NSDictionary*) layoutActions {
	return layoutActions;
	
}

+ (NSDictionary*) editingActions {
	return editingActions;	
	
}

- (id) init {
	
	if ((self = [super init])) {
		
		scalableSublayers = [[NSMutableSet alloc] init];
		
		scale = 1.f;
		self.contentsScale = screenScale;
		self.rasterizationScale = screenScale;
		
		[self setUpAnimationActions: editingActions];
		
		// self.masksToBounds = YES;
		
	}
	return self;
	
}

- (void) setUpAnimationActions: (NSDictionary*) actions {
	
	if (self.actions == actions)
		return;
	
	if (self.actions == layoutActions)
		return;
	
	self.actions = actions;
	for (ScalableLayer* sublayer in scalableSublayers)
		[sublayer setUpAnimationActions: actions];
	
}

- (float) scale {
	return self -> scale;
	
}

- (void) setScale: (float) _scale {
	// NSLog (@"set scale %f: %@", _scale, self);
	self -> scale = _scale;
	// [self setScaledPosition: self.scaledPosition];
	
	for (ScalableLayer* sublayer in scalableSublayers)
		sublayer.scale = _scale;
	
}

- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[colorScheme release];
	colorScheme = [_colorScheme retain];
	
	for (ScalableLayer* sublayer in scalableSublayers)
		sublayer.colorScheme = _colorScheme;
	
}

- (NSString*) colorScheme {
	return colorScheme;
	
}

@synthesize designatedSuperlayer;

- (void) addSublayer: (CALayer*) sublayer {
	
	if ([sublayer isKindOfClass: [ScalableLayer class]]) {
		ScalableLayer* layer = (ScalableLayer*) sublayer;
		
		if (layer -> designatedSuperlayer == self) {
			[super addSublayer: layer];
			if (!layer.hidden) {
				[layer setNeedsUpdateRenderQueueState];
				[layer recursiveSetNeedsUpdateRenderQueueState: layer.hidden];
				
			} else
				; // NSLog (@"-- optimized.");
			
			return;
			
		}
		
		layer -> designatedSuperlayer = self;
		[scalableSublayers addObject: layer];
		
		[super addSublayer: sublayer];
		
		layer.colorScheme = colorScheme;
		layer.scale = scale;
		// [layer setUpAnimationActions: self.actions];
		
		if (!layer.hidden) {
			[layer setNeedsUpdateRenderQueueState];
			[layer recursiveSetNeedsUpdateRenderQueueState: NO];
			
		} else
			; // NSLog (@"optimized.");
		
	} else {
		// NSLog (@"wrong class %@ cannot propagagte specific props", [sublayer class]);
		
		[super addSublayer: sublayer];
		
	}
	
}

- (void) removeFromSuperlayer {
	if (!self.hidden) {
		[self setNeedsUpdateRenderQueueState];
		[self recursiveSetNeedsUpdateRenderQueueState: YES];
		
	} else {
		// NSLog (@"optimized.");
		
	}
	[super removeFromSuperlayer];
	
}

- (void) presentSublayer: (ScalableLayer*) sublayer visible: (BOOL) visibility {
	if (visibility) {
		if (sublayer -> persistentParent) {
			if (sublayer.superlayer != sublayer -> persistentParent)
				[sublayer -> persistentParent addSublayer: sublayer];
			
		} else {
			if (sublayer.superlayer != self)
				[self addSublayer: sublayer];
			
		}
		
	} else {
		if (sublayer.superlayer)
			[sublayer removeFromSuperlayer];
		
	}
	
/*	
	if (!sublayer)
		NSLog (@"no sublayer");
		
	if (!visibility != sublayer.hidden) {
		NSLog (@"sublayer %@ should be hidden %i is hidden %i",
			sublayer, !visibility, sublayer.hidden);
		NSLog (@"superlayer is %@", sublayer.superlayer);
		
	}
*/

}

- (BOOL) isHidden {
	return super.hidden || !self.superlayer;
	
}

- (void) setHidden: (BOOL) state {
	if (state == super.hidden)
		return;
	
	super.hidden = state;
	[self setNeedsUpdateRenderQueueState];
	[self recursiveSetNeedsUpdateRenderQueueState: state];
	
}

@synthesize needsRendering;
@synthesize isInRenderQueue;

- (BOOL) needsUpdateRenderQueueState {
	return needsUpdateRenderQueueState;
	
}

/*
- (BOOL) fullyHidden {
	BOOL hidden = NO;
	ScalableLayer* layer = self;
	do {
		hidden = layer.hidden;
		layer = layer -> designatedSuperlayer;
		
	} while (!hidden && layer);
	
	return hidden;
	
}
*/

- (void) recursiveSetNeedsUpdateRenderQueueState: (BOOL) parentHidden {
	
	needsUpdateRenderQueueState = YES;
	for (ScalableLayer* sublayer in scalableSublayers) {
		if (parentHidden == sublayer.hidden) {
			childrenNeedUpdateRenderQueueState = YES;
			[sublayer recursiveSetNeedsUpdateRenderQueueState: parentHidden];
			
		} else
			; // NSLog (@"optvvimized..");
		
	}
	
}

- (void) setNeedsUpdateRenderQueueState {
	
	//
		
		needsUpdateRenderQueueState = YES;
		
	//
	
	ScalableLayer* parent = designatedSuperlayer;
	while (parent && !parent -> childrenNeedUpdateRenderQueueState) {
		parent -> childrenNeedUpdateRenderQueueState = YES;
		parent = parent -> designatedSuperlayer;
		
	}
	
}

- (BOOL) childrenNeedUpdateRenderQueueState {
	return childrenNeedUpdateRenderQueueState;
	
}

- (void) setChildrenNeedUpdateRenderQueueState: (BOOL) state {
	childrenNeedUpdateRenderQueueState = state;
	
}

- (void) updateRenderQueueState: (BOOL) parentHidden {
	BOOL hidden = parentHidden || self.hidden;
	
	if (needsUpdateRenderQueueState) {
		needsUpdateRenderQueueState = NO;
		
// NSLog (@"%@ needs update render queue state/need rendering %i/is in queue %i", self, needsRendering, isInRenderQueue);
		
		if (hidden) {
			if (isInRenderQueue)
				[self.renderQueue removeFromQueue: self];
			
		} else {
			if (needsRendering && !isInRenderQueue)
				[self.renderQueue addToQueue: self];
			
		}
		
	}
	if (childrenNeedUpdateRenderQueueState) {
		childrenNeedUpdateRenderQueueState = NO;

// NSLog (@"  %@ children need update render queue state", self);
		
		for (ScalableLayer* sublayer in scalableSublayers)
			[sublayer updateRenderQueueState: hidden];
		
	}
	
}

- (void) renderImmediately {
	if (isInRenderQueue)
		[self.renderQueue removeFromQueue: self];
	
	needsRendering = NO;
	
	if (!self.hidden) {
		[self setNeedsDisplay];
	
		for (ScalableLayer* sublayer in scalableSublayers)
			[sublayer renderImmediately];
		
	}
	
}

- (void) renderImmediatelyInContext: (CGContextRef) context {
	if (isInRenderQueue)
		[self.renderQueue removeFromQueue: self];
	
	needsRendering = NO;
	
	if (!self.hidden) {
		// [self updateScaledPosition];
		
		CGContextSaveGState (context);
		
		CGContextTranslateCTM (context, self.scaledPosition.x, self.scaledPosition.y);
		
		[self drawImmediatelyInContext: context];
		
		for (CALayer* sublayer in self.sublayers) {
			if ([sublayer isKindOfClass: [ScalableLayer class]]) {
				ScalableLayer* scalableSublayer = (ScalableLayer*) sublayer;
				[scalableSublayer renderImmediatelyInContext: context];
				
			}
			
		}
		
		CGContextRestoreGState (context);
		
	}
	
}

- (void) drawImmediatelyInContext: (CGContextRef) context {
	[self drawInContext: context];
	
}

- (void) renderChildren: (NSArray*) sublayers immediatelyInContext: (CGContextRef) context {
	
}

- (RenderQueue*) renderQueue {
	if (renderQueue)
		return renderQueue;
	else
		return designatedSuperlayer.renderQueue;
	
}

- (TileRenderQueue*) tileRenderQueue {
	if (tileRenderQueue)
		return tileRenderQueue;
	else
		return (tileRenderQueue = designatedSuperlayer.tileRenderQueue);
	
}

- (void) setPriority: (float) _priority {
	priority = _priority;
	
}

- (float) priority {
	CGRect bounds = self.concatenatedBounds;
	CGPoint center = CGPointMake (
		bounds.origin.x + bounds.size.width / 2,
		bounds.origin.y + bounds.size.height / 2
		
	);
	center.x -= renderQueueCenter.x;
	center.y -= renderQueueCenter.y;
	
	priority = (float) -sqrt (
		center.x * center.x +
		center.y * center.y
		
	);
	
	return priority + (self.hidden ? -8152 : 0);
	
}

- (void) setScaledPosition: (CGPoint) _position {
	if (!CGPointEqualToPoint (originalPosition, _position)) {
		originalPosition = _position;
		
		if (!needsRecalcConcatenatedBounds) {
			needsRecalcConcatenatedBounds = YES;
			for (ScalableLayer* sublayer in scalableSublayers)
				sublayer.needsRecalcConcatenatedBounds = YES;
			
		}
		
	}
	
}

- (CGPoint) scaledPosition {
	return originalPosition;
	
}

- (void) updateScaledPosition {
	CGPoint parentError = designatedSuperlayer == nil ?
		CGPointZero :
		designatedSuperlayer -> localRoundingError;
	
	CGPoint localPosition = CGPointMake (
		originalPosition.x * scale - parentError.x,
		originalPosition.y * scale - parentError.y
		
	);
	
	CGPoint targetPosition = CGPointMake (
		(CGFloat) round (localPosition.x * screenScale) / screenScale,
		(CGFloat) round (localPosition.y * screenScale) / screenScale
		
	);
	
	localRoundingError = CGPointMake (
		targetPosition.x - localPosition.x,
		targetPosition.y - localPosition.y
		
	);
	
	if (!CGPointEqualToPoint (self.position, targetPosition))
		[self setPosition: targetPosition];
	
	for (ScalableLayer* sublayer in scalableSublayers)
		// if (!sublayer.hidden)
			[sublayer updateScaledPosition];
	
}

- (CGRect) localBounds {
	return localBounds;
	
}

- (CGRect) localBoundsForEditor {
	return localBounds;
	
}

@synthesize needsRecalcConcatenatedBounds;

- (CGRect) concatenatedBounds {
	if (needsRecalcConcatenatedBounds) {
		concatenatedBounds = self.localBounds;
		
		if (designatedSuperlayer) {
			CGRect parentBounds = [designatedSuperlayer concatenatedBounds];
			concatenatedBounds.origin.x += parentBounds.origin.x + originalPosition.x,
			concatenatedBounds.origin.y += parentBounds.origin.y + originalPosition.y;
			
		} else {
			concatenatedBounds.origin.x += originalPosition.x,
			concatenatedBounds.origin.y += originalPosition.y;
			
		}
		
		needsRecalcConcatenatedBounds = NO;
		
	}
	return concatenatedBounds;
	
}

- (CGRect) concatenatedBoundsForEditor {
	
	CGRect bounds = self.localBoundsForEditor;
	
	ScalableLayer* visitor = self;
	do {
		CGPoint position = visitor.scaledPosition;
		bounds.origin.x += position.x,
		bounds.origin.y += position.y;
		
		// NSLog (@"adding %@: %f; %f", visitor, position.x, position.y);
		
		visitor = visitor -> designatedSuperlayer;
		
	} while (visitor && [visitor isKindOfClass: [ScalableLayer class]]);
	
	return bounds;
	
}

- (CGRect) localBoundsForPlayback {
	return localBounds;
	
}

- (CGRect) concatenatedBoundsForPlayback {
	
	CGRect bounds = self.localBoundsForPlayback;
	
	ScalableLayer* visitor = self;
	do {
		CGPoint position = visitor.scaledPosition;
		bounds.origin.x += position.x,
		bounds.origin.y += position.y;
		
		// NSLog (@"adding %@: %f; %f", visitor, position.x, position.y);
		
		visitor = visitor -> designatedSuperlayer;
		
	} while (visitor && [visitor isKindOfClass: [ScalableLayer class]]);
	
	return bounds;
	
}

- (void) updateLayerVisibilityInRect: (CGRect) viewRect { // root layer only
//	if (didRenderStatic)
//		return;
	
/*	NSLog (@"update layer visibility in rect %f, %f, %f, %f",
		viewRect.origin.x, viewRect.origin.y, viewRect.size.width, viewRect.size.height);
*/	
	
/*
	viewRect.size.width /= 2;
	viewRect.size.height /= 2;
*/
	
	//BOOL selfHidden = self.hidden;
	NSArray* _scalableSublayers = [scalableSublayers copy];
	for (ScalableLayer* sublayer in _scalableSublayers) {
		if (sublayer -> persistentParent && !sublayer -> forceUpdateVisibility)
			continue;
		
		CGRect bounds = [sublayer concatenatedBounds];
		
		BOOL isVisible =
			CGRectGetMinX (viewRect) < CGRectGetMaxX (bounds) &&
			CGRectGetMaxX (viewRect) > CGRectGetMinX (bounds) &&
			CGRectGetMinY (viewRect) < CGRectGetMaxY (bounds) &&
			CGRectGetMaxY (viewRect) > CGRectGetMinY (bounds);
		
		// sublayer.hidden = !isVisible;
		
		if (sublayer.hidden == isVisible)
			[self presentSublayer: sublayer visible: isVisible];
		
	}
	[_scalableSublayers release];
	
}

- (void) drawInContext: (CGContextRef) context {
	
}

- (void) layoutSublayers {

}

/*
*/

@synthesize isEditable;

- (ScalableLayer*) editableLayerUnderPoint: (CGPoint) location {
	
	location.x -= self.scaledPosition.x;
	location.y -= self.scaledPosition.y;
	
	// NSLog (@"propageted location %f; %f", location.x, location.y);
	
	if (self.isEditable) {
		CGRect bounds = self.localBounds;
		
		// NSLog (@"hit testing %@ in rect %f; %f; %f; %f",
		//	self, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
		
		if (CGRectContainsPoint (bounds, location))
			return self;
		
	} else {
		NSArray* layers = self.sublayers;
		
		for (int i = (int) [layers count]; i--;) {
			CALayer* layer = [layers objectAtIndex: i];
			if (![layer isKindOfClass: [ScalableLayer class]])
				continue;
			
			ScalableLayer* sublayer = (ScalableLayer*) layer; 
			ScalableLayer* subHitLayer = [sublayer editableLayerUnderPoint: location];
			if (subHitLayer)
				return subHitLayer;
			
		}
		
	}
	return nil;
	
}

// editing

- (id) modelObject {
	return modelObject;
	
}

- (void) setModelObject: (id) _modelObject {
	if (modelObject != _modelObject) {
		[modelObject release];
		modelObject = [_modelObject retain];
		
		[self updateFromModelObject];
		
	}
	
}

- (void) updateFromModelObject {
	
}

- (void) updateLayout {

}

- (id) annotationModelObject {
	return nil;
	
}


@synthesize nextEditableElement;
@synthesize previousEditableElement;

extern NSString *SHEET_COLOR_SCHEME_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_NEGATIVE;
extern NSString *SHEET_COLOR_SCHEME_PRINT;

extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE;


- (void) enterEditMode {
	
	if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE]) {
		self.shadowOpacity = 0;
		
	} else {
		self.shadowOpacity = .33f;
		
		if (!didSetUpEditMode) {
			didSetUpEditMode = YES;
			self.shadowRadius = 2;
			self.shadowOffset = CGSizeMake (0, 4);
			
		}
		
	}
	
}

- (void) leaveEditMode {
	self.shadowOpacity = 0;
	
}

- (void) setIsEmbossed: (BOOL) doSet {
	if (doSet) {
		BOOL drawsPositive =
			[colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE] ||
			[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE];
		
		self.shadowColor = drawsPositive ?
			[UIColor blackColor].CGColor :
			[UIColor whiteColor].CGColor;
		
		self.shadowOpacity = 1.;
		self.shadowRadius = 0.;
		
		self.shadowOffset = CGSizeMake (0, drawsPositive ? -1 : 1);
		
	} else {
		self.shadowOpacity = 0.;
		
	}
	
}

//

- (void) renderStatic {
	
}

- (CALayer*) staticTileInBounds: (CGRect) bounds {
	
	CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB ();
	
	CGContextRef context = CGBitmapContextCreate (
		NULL,
		(size_t) bounds.size.width, (size_t) bounds.size.height,
		8, 0,
		colourSpace,
		kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host
//		kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Host
		
	);
	
	CGContextSaveGState (context);

/*
	CGContextSetFillColorWithColor (context, [UIColor colorWithRed: 0. green: 1. blue: 0. alpha :.0].CGColor);
	CGContextFillRect(context, CGRectMake(0, 0, bounds.size.width, bounds.size.height));
*/
	
	CGContextTranslateCTM (context,
		-bounds.origin.x, bounds.origin.y + bounds.size.height);
	CGContextScaleCTM (context, 1, -1);
	
	[self renderInContext: context];
	
	CGContextRestoreGState (context);
	
	
	
/*	
	CGContextSetStrokeColorWithColor (context, [UIColor colorWithRed: 0. green: 1. blue: 0. alpha :1.].CGColor);
	CGContextStrokeRect (context, CGRectMake (0, 0, bounds.size.width, bounds.size.height));
	
*/
	
	
	CGImageRef image = CGBitmapContextCreateImage (context);
	CGContextRelease (context);
	
	CGColorSpaceRelease (colourSpace);
	
	CALayer* layer = [CALayer layer];
	layer.anchorPoint = CGPointMake (0, 0);
	layer.bounds = CGRectMake (0, 0, bounds.size.width, bounds.size.height);
	layer.position = bounds.origin;
	layer.contents = (id) image;
	
	CGImageRelease (image);
	
	return layer;
	
}

- (void) unrenderStatic {
	
	if (staticTiles) {
		for (CALayer* staticLayer in staticTiles)
			if (staticLayer.superlayer == self)
				[staticLayer removeFromSuperlayer];
		
		[staticTiles removeAllObjects];
		
	} else
		staticTiles = [[NSMutableArray alloc] init];
	
	didRenderStatic = NO;
	
}

// deallocation

- (void) dealloc {
	
	// NSLog(@"deallocating %@", self);
	for (ScalableLayer* sublayer in scalableSublayers) {
		[sublayer removeFromSuperlayer];
		// NSLog(@"releasing instance %@ retain count %i", sublayer, [sublayer retainCount]);
		
	}
	[scalableSublayers release];
	
	NSArray* sublayers = [self.sublayers copy];
	for (CALayer* sublayer in sublayers) {
		[sublayer removeFromSuperlayer];
		// NSLog(@"releasing instance %@ %@ retain count %i (children %@)", sublayer, sublayer.name, [sublayer retainCount] - 1, [sublayer sublayers]);
		
	}
	[sublayers release];
	
	[modelObject release];
	
	[staticTiles release];
	
	[super dealloc];
	
}

@end
