//
//  EditableTextLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 14.01.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>

#import "TextLayer.h"


@interface EditableTextLayer : TextLayer {

	NSString* label;
	
	@public
	
	float editorYPadding;
	
	float editorMinWidth;
	
}

@property (readwrite, copy) NSString* label;

@end
