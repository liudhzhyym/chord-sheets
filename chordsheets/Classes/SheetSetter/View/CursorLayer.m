//
//  Cursor.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 28.01.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import "CursorLayer.h"


@implementation CursorLayer


- (id) init {
    
    if ((self = [super init])) {
		self.anchorPoint = CGPointMake (0, 0);
		self.bounds = CGRectMake (
			0, 0, 1, 1
			
		);
		
    }
    return self;
	
}

extern NSString *SHEET_COLOR_SCHEME_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_NEGATIVE;

extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE;


- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[super setColorScheme: _colorScheme];
	
	if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE] ||
		[colorScheme isEqualToString: SHEET_COLOR_SCHEME_NEGATIVE]) {
		self.shadowOpacity = 1.;
		self.shadowOffset = CGSizeMake (0, 3);
		
	} else {
		self.shadowOpacity = 0.;
		
	}
	
	[self setNeedsDisplay];
	
}

- (void) adjustBounds {
	CGFloat width = (CGFloat) ceil (localBounds.size.width * scale);
	CGFloat height = (CGFloat) ceil (localBounds.size.height * scale);
	CGRect bounds = CGRectMake (0, 0, width, height);
	
	self.bounds = bounds;
	
	[self setNeedsDisplay];
	
}

- (void) setScale: (float) _scale {
	[super setScale: _scale];
	[self adjustBounds];
//	[self updateScaledPosition];
	
}

- (void) snapToRect: (CGRect) rect {
	
	localBounds = CGRectMake (
		0, 0,
		rect.size.width,
		rect.size.height
		
	);
	[self setNeedsRecalcConcatenatedBounds: YES];
	
	[self setScaledPosition: rect.origin];
	[self updateScaledPosition];
	
	[self adjustBounds];
	
}

void drawRoundedBox (CGContextRef context, CGRect bounds);
void drawRoundedBox (CGContextRef context, CGRect bounds) {
	CGFloat radius = 4;
	// NOTE: At this point you may want to verify that your radius is no more than half
	// the width and height of your rectangle, as this technique degenerates for those cases.
	
	// In order to draw a rounded rectangle, we will take advantage of the fact that
	// CGContextAddArcToPoint will draw straight lines past the start and end of the arc
	// in order to create the path from the current position and the destination position.
	
	// In order to create the 4 arcs correctly, we need to know the min, mid and max positions
	// on the x and y lengths of the given rectangle.
	CGFloat minx = CGRectGetMinX(bounds), midx = CGRectGetMidX(bounds), maxx = CGRectGetMaxX(bounds);
	CGFloat miny = CGRectGetMinY(bounds), midy = CGRectGetMidY(bounds), maxy = CGRectGetMaxY(bounds);
	
	// Next, we will go around the rectangle in the order given by the figure below.
	//       minx    midx    maxx
	// miny    2       3       4
	// midy   1 9              5
	// maxy    8       7       6
	// Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
	// form a closed path, so we still need to close the path to connect the ends correctly.
	// Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
	// You could use a similar tecgnique to create any shape with rounded corners.
	
	// Start at 1
	CGContextMoveToPoint(context, minx, midy);
	// Add an arc through 2 to 3
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	// Add an arc through 4 to 5
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	// Add an arc through 6 to 7
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	// Add an arc through 8 to 9
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	// Close the path
	CGContextClosePath(context);
	
	CGContextDrawPath(context, kCGPathFill);
	
}

void drawBox (CGContextRef context, CGRect bounds);
void drawBox (CGContextRef context, CGRect bounds) {
	CGContextFillRect (context, bounds);
	
}

- (void) drawInContext: (CGContextRef) context {
	BOOL drawPositive = NO;
	float cursorShade = 0.f;
	
	BOOL drawRounded = NO;
	
	if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE]) {
		drawPositive = YES;
		cursorShade = 1;
		
		drawRounded = YES;
		
	} else if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE]) {
		drawPositive = NO;
		cursorShade = 75.f / 255.f;
		
		drawRounded = NO;
		
	} else if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_NEGATIVE]) {
		drawPositive = NO;
		cursorShade = .3f;
		
		drawRounded = YES;
		
	} else if ([colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE]) {
		drawPositive = NO;
		cursorShade = 213.f / 255.f;
		
		drawRounded = NO;
		
	}
	(void) drawPositive;
	
	CGContextSetRGBFillColor (context, cursorShade, cursorShade, cursorShade, 1);
	
	CGFloat width = (CGFloat) ceil (localBounds.size.width * scale);
	CGFloat height = (CGFloat) ceil (localBounds.size.height * scale);
	CGRect bounds = CGRectMake (0, 0, width, height);
	
	if (drawRounded) {
		drawRoundedBox (context, bounds);
		
	} else {
		drawBox (context, bounds);
		
	}
		
}

- (void) dealloc {
    [super dealloc];
	
}


@end
