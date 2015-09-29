//
//  EditableTextLayer.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 14.01.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import "EditableTextLayer.h"

#import "TextModel.h"


@implementation EditableTextLayer


- (id) init {
	if ((self = [super init])) {
		editorMinWidth = 64;
		
	}
	return self;
	
}

@synthesize label;

- (id) modelObject {
	if (!modelObject) {
		TextModel* textModel = [[TextModel alloc] init];
		if (!self.previousEditableElement) {
			textModel.isFirstElement = YES;
			
		}
		textModel.text = text;
		textModel.label = label;
		
		modelObject = textModel;
		
	}
	return modelObject;
	
}

- (void) updateFromModelObject {
	if (modelObject && [modelObject isKindOfClass: [TextModel class]])
		self.text = ((TextModel*) modelObject).text;
	
}

- (CGRect) localBoundsForEditor {
	return CGRectMake (
		0, 0,
		MAX (editorMinWidth, textSize.width + 10) - 22,
		textSize.height
		
	);
	
}

- (void) dealloc {
	[label release];
    [super dealloc];
	
}


@end
