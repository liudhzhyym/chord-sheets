//
//  BitmapLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "ScalableLayer.h"


@interface BoundedBitmapLayer : ScalableLayer {
	
	UIImage* image;
	NSString* imageFileName;
	
	CGSize scaledSize;
	
	
	@public
	
	BOOL lockTextureScale;
	
}

@property (readwrite, retain) UIImage* image;
@property (readwrite, retain) NSString* imageFileName;

- (id) initWithBundleImage: (NSString*) imageFileName;

- (void) loadBundleImage: (NSString*) imageFileName;

@property (readwrite) CGSize scaledSize;

- (void) updateBounds;


@end
