//
//  TextLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

#import <UIKit/UIKit.h>


#import "ScalableLayer.h"


@interface TextLayer : ScalableLayer {
	
	NSString* text;
	
	NSString* fontName;
	float fontSize;
	
	CGSize textSize;
	
	BOOL drawsBorder;
	
	BOOL needsRecreateFont;
	BOOL needsRecreateAttributes;
	
	CTFontRef font;
	CTLineRef textLine;
	
	BOOL shouldConvertToPathOnExport;
	
	@public

	float fontColor [4];
	BOOL lockFontColor;
	
	float backgroundColor [4];
	
	float cropX, cropY;
	
}

@property (readwrite, copy) NSString* text;

@property (readwrite, copy) NSString* fontName;
@property (readwrite) float fontSize;

@property (readwrite) BOOL drawsBorder;

@property (readonly) float width;


- (void) updateBounds;


@end
