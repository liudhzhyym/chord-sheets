//
//  AnnotationLayer.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 11.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "EditableTextLayer.h"


@class BoundedBitmapLayer;


@interface AnnotationLayer : EditableTextLayer {
		
	BoundedBitmapLayer* shadowLayer;
	
}

@end
