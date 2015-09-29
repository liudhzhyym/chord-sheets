//
//  ScrubbingSlider.m
//  ScrubbingSlider
//
//  Created by Pattrick Kreutzer on 02.12.13.
//  Cleaned up from https://github.com/ole/OBSlider/releases
//
//  Released into the public domain in 2015 2013 Pattrick Kreutzer.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "ScrubbingSlider.h"

@implementation ScrubbingSlider

- (BOOL) beginTrackingWithTouch: (UITouch*) touch withEvent: (UIEvent*) event {
	BOOL beginTracking = [super beginTrackingWithTouch: touch withEvent: event];
	if (beginTracking) {
		startValue = self.value;
		
		CGRect thumbRect = [self thumbRectForBounds: self.bounds
			trackRect: [self trackRectForBounds: self.bounds]
			value: (float) startValue];
		startLocation = CGPointMake (
			thumbRect.origin.x + thumbRect.size.width / 2,
			thumbRect.origin.y + thumbRect.size.height / 2
			
		);
		
	}
	return beginTracking;
	
}

- (BOOL) continueTrackingWithTouch: (UITouch*) touch withEvent: (UIEvent*) event {
	if (self.tracking) {
		CGPoint previousLocation = [touch previousLocationInView:self];
		CGPoint currentLocation  = [touch locationInView:self];
		CGFloat trackingOffset = currentLocation.x - previousLocation.x;
		
		CGFloat verticalOffset = ABS (currentLocation.y - startLocation.y);
		float scrubbingSpeed = verticalOffset > 50 ? .1f : 1;
		 
		CGRect trackRect = [self trackRectForBounds: self.bounds];
		startValue = startValue + (self.maximumValue - self.minimumValue) * (trackingOffset / trackRect.size.width);

		CGFloat valueAdjustment = scrubbingSpeed * (self.maximumValue - self.minimumValue) * (trackingOffset / trackRect.size.width);
		CGFloat thumbAdjustment = 0.0f;
		if (((startLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) ||
			((startLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y))) {
			thumbAdjustment = (CGFloat) (startValue - self.value) / (1 + ABS (currentLocation.y - startLocation.y));
			
		}
		self.value += (float) (valueAdjustment + thumbAdjustment);
		
		if (self.continuous)
			[self sendActionsForControlEvents: UIControlEventValueChanged];
		
	}
	return self.tracking;
	
}

- (void) endTrackingWithTouch: (UITouch*) touch withEvent: (UIEvent*) event {
	if (self.tracking)
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	
}

@end
