//
//  TitleLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "TitleLayer.h"

#import "TextLayer.h"


@implementation TitleLayer

- (id) init {
	if ((self = [super init])) {
		title = [EditableTextLayer layer];
		title.fontName = @"Helvetica-Bold";
		title.fontSize = 18;
		title.label = @"Song Title";

		[self addSublayer: title];
		
		artist = [EditableTextLayer layer];
		artist.fontName = @"Helvetica";
		artist.fontSize = 18;
		artist.label = @"Artist";
		artist.scaledPosition = CGPointMake (0, 24 - 1);
		
//		artist.scaledPosition = CGPointMake (0, 7);
		[self addSublayer: artist];
		
		title.isEditable = YES;
		artist.isEditable = YES;
		
		localBounds = CGRectMake (0, 0, 1, 20);
		
	}
	return self;
	
}

//

@synthesize title;
@synthesize artist;

- (void) setTitleText: (NSString*) titleText {
	title.text = titleText;
	[self updateLayout];
	
}

- (void) setArtistText: (NSString*) artistText {
	artist.text = artistText;
	[self updateLayout];
	
}

//

- (void) updateLayout {
//	artist.scaledPosition = CGPointMake (title.width + 4, artist.scaledPosition.y);
	
	localBounds = CGRectMake (
		0, 0,
		MAX (title.width, artist.width),
		artist.scaledPosition.y + artist.localBounds.size.height
		
	);
	needsRecalcConcatenatedBounds = YES;
	
}

@end
