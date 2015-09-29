//
//  TitleLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "ScalableLayer.h"

#import "EditableTextLayer.h"


@interface TitleLayer : ScalableLayer {
	
	EditableTextLayer* title;
	EditableTextLayer* artist;
	
}

@property (readonly) TextLayer* title;
@property (readonly) TextLayer* artist;

- (void) setTitleText: (NSString*) title;
- (void) setArtistText: (NSString*) artist;


@end
