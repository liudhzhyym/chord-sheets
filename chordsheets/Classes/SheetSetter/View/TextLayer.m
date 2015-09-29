//
//  TextLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "TextLayer.h"



@implementation TextLayer

- (id) init {
	if ((self = [super init])) {
		self.bounds = CGRectMake (0, 0, 1, 1);
		self.anchorPoint = CGPointMake (0, 0);
		
		self.fontName = @"Helvetica-Bold";
		self.fontSize = 16;
		
		fontColor [3] = 1.f;
		// self.contentsScale = [UIScreen mainScreen].scale;
		
		// self.masksToBounds = YES;
		
	}
	return self;
	
}

//

- (NSString*) text {
	return [[text copy] autorelease];
	
}

- (void) setText: (NSString*) _text {
	if (text && text == _text)
		return;
	
	if (text)
		[text release];
	text = [_text copy];
	
	needsRecreateAttributes = YES;
	
	UIFont* uiFont = [UIFont fontWithName: fontName size: fontSize];
	textSize = [text sizeWithAttributes: @{NSFontAttributeName: uiFont}];
	
	if (textSize.width != 0)
		textSize.width += 2;
	
	[self updateBounds];
	[self setNeedsRendering: YES];
	[self setNeedsUpdateRenderQueueState];
	
	// NSLog (@"draw scale %f", scale);
	// [self setNeedsDisplay];
	
}

- (void) updateBounds {
	
	double left = textSize.width * cropX * scale;
	double top = fontSize * scale * cropY * 1.3;
	double right = left + textSize.width * scale * (1 - 2.5 * cropX);
	double bottom = top + textSize.height * scale * (1 - 2.1 * cropY);
	
	self.bounds = CGRectMake (
		(CGFloat) floor (left),
		(CGFloat) floor (top),
		(CGFloat) (floor (right) - floor (left)),
		(CGFloat) (ceil (bottom) - floor (top))
		
	);
	self -> localBounds = CGRectMake (
		0, 0,
		textSize.width, textSize.height
		
	);
	
}

- (NSString*) fontName {
	return fontName;
	
}

- (void) setFontName: (NSString*) _fontName {
	if (fontName != _fontName) {
		[fontName release];
		fontName = [_fontName copy];
		
		shouldConvertToPathOnExport =
			[fontName isEqualToString: @"iDBsheet-Regular"];
		
		needsRecreateFont = YES;
		needsRecreateAttributes = YES;
		
	}
	
}

- (float) fontSize {
	return fontSize;
	
}

- (void) setFontSize: (float) _fontSize {
	fontSize = _fontSize;
	
	needsRecreateFont = YES;
	needsRecreateAttributes = YES;
	
}

- (BOOL) drawsBorder {
	return drawsBorder;
	
}

- (void) setDrawsBorder: (BOOL) _drawsBorder {
	if (drawsBorder == _drawsBorder)
		return;
	
	drawsBorder = _drawsBorder;
	
return;
	
	if (_drawsBorder) {
		self.shadowOpacity = .125;
		self.shadowOffset = CGSizeMake (0, 2);
		self.shadowRadius = 1;
		
	} else {
		self.shadowOpacity = 0;
		
	}
	
}

extern NSString *SHEET_COLOR_SCHEME_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_NEGATIVE;
extern NSString *SHEET_COLOR_SCHEME_PRINT;

extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_POSITIVE;
extern NSString *SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE;

- (void) setColorScheme: (NSString*) _colorScheme {
	if (_colorScheme == colorScheme)
		return;
	
	[super setColorScheme: _colorScheme];
	if (lockFontColor)
		return;
	
	BOOL drawPositive =
		[colorScheme isEqualToString: SHEET_COLOR_SCHEME_POSITIVE] ||
		[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PLAYBACK_NEGATIVE] ||
		[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PRINT];
	
	if (drawPositive) {
		fontColor [0] = 0;
		fontColor [1] = 0;
		fontColor [2] = 0;
		
	} else {
		fontColor [0] = 1;
		fontColor [1] = 1;
		fontColor [2] = 1;
		
	}
	
	[self setNeedsRendering: YES];
	[self setNeedsUpdateRenderQueueState];
	
}

- (void) recreateFontIfNeeded {
	if (!needsRecreateFont)
		return;
	
	needsRecreateFont = NO;
	
	if (font)
		CFRelease (font);
	
	CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithNameAndSize (
		(CFStringRef) fontName, fontSize
		
	);
	font = CTFontCreateWithFontDescriptor (
		fontDesc, fontSize, NULL
		
	);
	CFRelease (fontDesc);
	
}

- (void) recreateAttributesIfNeeded {
	if (!needsRecreateAttributes)
		return;
	
	needsRecreateAttributes = NO;
	
	if (textLine)
		CFRelease (textLine);
	
	CFStringRef keys [] = {
		kCTFontAttributeName,
		kCTForegroundColorFromContextAttributeName
		
	};

	CFTypeRef values [] = {
		font,
		kCFBooleanTrue
		
	};

	CFDictionaryRef attributes = CFDictionaryCreate (
		kCFAllocatorDefault,
		(const void**) &keys,
		(const void**) &values, sizeof (keys) / sizeof (keys [0]),
		&kCFTypeDictionaryKeyCallBacks,
		&kCFTypeDictionaryValueCallBacks
		
	);
	
	CFAttributedStringRef attributedText = CFAttributedStringCreate (
		kCFAllocatorDefault,
		(CFStringRef) text,
		attributes
		
	);

	textLine = CTLineCreateWithAttributedString (attributedText);
	
	CFRelease (attributedText);
	CFRelease (attributes);
	
}

- (void) drawInContext: (CGContextRef) context {
	// NSLog(@"drw %@", text);
	
	[self recreateFontIfNeeded];
	[self recreateAttributesIfNeeded];
	
	//
	
	CGContextConcatCTM (
		context,
		CGAffineTransformMakeScale (scale, scale)
		
	);
	
	CGRect contentRect = CGRectMake (
		0, 0,
		textSize.width + 1 / scale,
		textSize.height + 1 / scale
		
	);
	
	if (drawsBorder) {
		CGContextSetRGBFillColor (
			context,
			backgroundColor [0],
			backgroundColor [1],
			backgroundColor [2],
			backgroundColor [3]
			
		);
		CGContextFillRect (context, contentRect);
		
	}
	
	//
	
	CGContextSetRGBFillColor (
		context,
		fontColor [0],
		fontColor [1],
		fontColor [2],
		fontColor [3]
		
	);
	
	if (shouldConvertToPathOnExport &&
		[colorScheme isEqualToString: SHEET_COLOR_SCHEME_PRINT]) {
		
		CGContextSaveGState (context);
		
		NSUInteger textLength = [text length];
		unichar* characters = malloc (textLength * sizeof (unichar));
		[text getCharacters: characters range: NSMakeRange (0, textLength)];
		
		CGGlyph* glyphs = malloc (textLength * sizeof (CGGlyph));
		bool success = CTFontGetGlyphsForCharacters (
			font, characters, glyphs, textLength
			
		);
		(void) success;
		
		CGSize* advances = malloc(textLength * sizeof (CGSize));
		
		double lineWidth = ceil (CTFontGetAdvancesForGlyphs (
			font,
			kCTFontOrientationHorizontal,
			glyphs,
			advances,
			textLength
			
		));
		(void) lineWidth;
		
		CGContextTranslateCTM (context, drawsBorder ? 1 : 0, fontSize / 16.f * 14);
		CGContextTranslateCTM (context, -localRoundingError.x, -localRoundingError.y);
		CGContextScaleCTM (context, 1, -1);
		
		for (int i = 0; i < textLength; i++) {
			CGGlyph glyph = glyphs [i];
			CGPathRef path = CTFontCreatePathForGlyph (font, glyph, nil);
			
			CGContextAddPath (context, path);
			CGContextFillPath (context);
			
			CGPathRelease (path);
			
			CGSize advance = advances [i];
			CGContextTranslateCTM(context, advance.width, advance.height);
			
		}
		
		free (advances);
		free (glyphs);
		free (characters);
		
		CGContextRestoreGState (context);
		
	} else {
	
		CGAffineTransform textTransform = CGAffineTransformIdentity;
		textTransform = CGAffineTransformScale (textTransform, 1, -1);
		
		CGContextSetTextMatrix (context, textTransform);
		CGContextSetTextPosition (context,
			(drawsBorder ? 1 : 0) - localRoundingError.x,
			fontSize / 16.f * 14 - localRoundingError.y
			
		);
		
		@try {
			CTLineDraw (textLine, context);
			
		} @catch (NSException *exception) {
			NSLog(@"%@", exception);
			
		} @finally {
			
		}
		
	}
	
	[self updateLayout];
	
}

- (void) drawImmediatelyInContext: (CGContextRef) context {
	if (cropX == 0 && cropY == 0) {
		[super drawImmediatelyInContext: context];
		
	} else {
		CGContextSaveGState (context);
		
		CGContextClipToRect (context, self.bounds);
		[self drawInContext: context];
		
		CGContextRestoreGState (context);
		
	}
	
}

- (BOOL) hidden {
	return super.hidden || !text;
	
}

- (float) width {
	return (float) textSize.width;
	
}

- (float) widthForEditor {
	return (float) textSize.width;
	
}

- (void) setScale: (float) _scale {
	[super setScale: _scale];
	[self updateBounds];
	[self setNeedsRendering: YES];
	[self setNeedsUpdateRenderQueueState];

}

extern CGFloat screenScale;

- (void) updateScaledPosition {
	CGPoint parentError = designatedSuperlayer == nil ?
		CGPointZero :
		designatedSuperlayer -> localRoundingError;
	
	CGPoint localPosition = CGPointMake (
		(originalPosition.x + textSize.width * cropX) * scale - parentError.x,
		(originalPosition.y + fontSize * cropY * 1.3f) * scale - parentError.y
		
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

//

- (void) dealloc {
	if (text)
		[text release];
	if (fontName)
		[fontName release];
	
	if (font)
		CFRelease (font);
	if (textLine)
		CFRelease (textLine);
	
	[super dealloc];
	
}

@end
