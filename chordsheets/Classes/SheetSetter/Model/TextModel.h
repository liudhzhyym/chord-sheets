//
//  TextModel.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 12.01.11.
//  Copyright 2011 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>


@interface TextModel : NSObject {
	
	BOOL isFirstElement;
	
	NSString* label;
	NSString* text;
	
}

@property (readwrite, retain) NSString* label;
@property (readwrite, retain) NSString* text;

@property (readwrite) BOOL isFirstElement;

@end
