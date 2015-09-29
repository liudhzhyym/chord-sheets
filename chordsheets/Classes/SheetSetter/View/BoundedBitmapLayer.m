//
//  BitmapLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "BoundedBitmapLayer.h"


@interface Pattern : NSObject {
	@public
	CGPatternRef fillPattern;
	CGColorSpaceRef fillPatternSpace;
	
}

@end

@implementation Pattern

- (id) initWithPattern: (CGPatternRef) _fillPattern space: (CGColorSpaceRef) _fillPatternSpace {
	
	if (self = [super init]) {
		CGPatternRetain (_fillPattern);
		CGColorSpaceRetain (_fillPatternSpace);
		
		fillPattern = _fillPattern;
		fillPatternSpace = _fillPatternSpace;
		
	}
	return self;
	
}

- (void) dealloc {
	[super dealloc];
	
	CGPatternRelease (fillPattern);
	CGColorSpaceRelease (fillPatternSpace);
	
}

@end


@interface PatternProvider : NSObject {
	NSMutableDictionary* patterns;
	
}

@end

@implementation PatternProvider

+ (PatternProvider*) sharedInstance {
	static PatternProvider* instance = nil;
	
	if (!instance) {
		instance = [[PatternProvider alloc] init];
		
	}
	return instance;
	
}

- (id) init {
	if (self = [super init]) {
		patterns = [[NSMutableDictionary alloc] init];
		
	}
	return self;
	
}

- (Pattern*) patternForKey: (NSString*) key {
	Pattern* pattern = [patterns objectForKey: key];
	return pattern;
	
}

- (void) storePattern: (Pattern*) pattern ForKey: (NSString*) key {
	[patterns setObject: pattern forKey: key];
	
}

@end


@implementation BoundedBitmapLayer

- (id) initWithBundleImage: (NSString*) _imageFileName {
	if ((self = [super init])) {
		[self loadBundleImage: _imageFileName];
		
	}
	return self;
	
}

- (UIImage*) image {
	return image;
	
}

- (void) setImage: (UIImage*) _image {
	if (image == _image)
		return;
	if (image != nil)
		[image release];
	
	image = [_image retain];
	
}

@synthesize imageFileName;

- (void) loadBundleImage: (NSString*) _imageFileName {
	self.imageFileName = _imageFileName;
	self.image = [UIImage imageNamed: _imageFileName];	
	self.scaledSize = image.size;
	
}

- (CGSize) scaledSize {
	return scaledSize;
	
}

- (void) setScaledSize: (CGSize) _scaledSize {
	
	if (CGSizeEqualToSize (scaledSize, _scaledSize))
		return;
	
	scaledSize = _scaledSize;
	[self updateBounds];
	
	[self setNeedsDisplay];	
	
}

- (void) updateBounds {
	// CGSize size = image.size;
	// NSLog (@"%f x %f", size.width, size.height);
	
	self -> localBounds = CGRectMake (0.0f, 0.0f, scaledSize.width, scaledSize.height);
	[self setNeedsRecalcConcatenatedBounds: YES];
	
	self.anchorPoint = CGPointMake (0, 0);
	self.bounds = CGRectMake (0.0f, 0.0f,
		scaledSize.width * scale, scaledSize.height * scale);
	
	[self setNeedsRecalcConcatenatedBounds: YES];
	
}

- (void) setScale: (float) _scale  {
//	if (self -> scale != scale) {
		[super setScale: _scale];
		if (lockTextureScale)
			[self setNeedsDisplay];
		
		[self updateBounds];
		
//	}
	// NSLog (@"bitmap scale %f", _scale);
	
}


void drawPattern (void* info, CGContextRef context);
void drawPattern (void* info, CGContextRef context) {
	// NSLog (@"draw");
	
	UIImage* image = info;
	CGSize imageSize = image.size;
	
	CGContextDrawImage (
		context,
		CGRectMake (0.0f, 0.f, (imageSize.width), (imageSize.height + 1)),
		image.CGImage
		
	);
	
}

void releaseInfo (void* info);
void releaseInfo (void* info) {
	UIImage* image = info;
	[image release];
	
}

- (void) drawInContext: (CGContextRef) context {
	// NSLog (@"draw img");
	// return;
	
	CGSize imageSize = image.size;
	
	if (lockTextureScale) {
		PatternProvider* patternProvider = [PatternProvider sharedInstance];
		
		Pattern* pattern = [patternProvider patternForKey: imageFileName];
		CGPatternRef fillPattern;
		CGColorSpaceRef fillPatternSpace;
		
		if (pattern) {
			fillPattern = pattern -> fillPattern;
			fillPatternSpace = pattern -> fillPatternSpace;
			
		} else {
			fillPatternSpace = CGColorSpaceCreatePattern (NULL);
			
			CGPatternCallbacks patternCallbacks =
				(CGPatternCallbacks) {0, &drawPattern, &releaseInfo};
			
			fillPattern = CGPatternCreate (
				[image retain], // info
				
				CGRectMake (0, 0, imageSize.width, imageSize.height),
				
				CGAffineTransformIdentity,
				imageSize.width, imageSize.height,
				
				kCGPatternTilingConstantSpacing,
				true,
				
				&patternCallbacks
				
			);
			
			pattern = [[Pattern alloc] initWithPattern: fillPattern space: fillPatternSpace];
			[patternProvider storePattern: pattern ForKey: imageFileName];
			[pattern release];
			
			CGPatternRelease (fillPattern);
			CGColorSpaceRelease (fillPatternSpace);
			
		}
		
		CGContextSetFillColorSpace (context, fillPatternSpace);
			
		const CGFloat alpha = 1.f;
		CGContextSetFillPattern (context, fillPattern, &alpha);
		
		CGContextFillRect (
			context,
			CGRectMake (0.f, 0.f, MAX (1.f, scaledSize.width / 8.f * scale), (scaledSize.height + 0.f) * scale)
			
		);
		
	} else {
		CGContextConcatCTM (context, CGAffineTransformMakeScale (
			(scaledSize.width + 0.f) / (imageSize.width + 0.f)  * scale,
			(scaledSize.height + 0.f) / (imageSize.height + 0.f) * -scale
			
		));
		CGContextConcatCTM (context, CGAffineTransformMakeTranslation (0.f, -imageSize.height));
		
		CGContextDrawImage (
			context,
			CGRectMake (0.0f, 0.f, imageSize.width + 1, imageSize.height + 1),
			image.CGImage
			
		);
		
	}
	
}

- (void) dealloc {
	if (image)
		[image release];
	if (imageFileName)
		[imageFileName release];
	
	[super dealloc];
	
}

@end
