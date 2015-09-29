//
//  LayerIterator.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

@class ScalableLayer;

@interface LayerIterator : NSObject <NSCopying> {
	
	ScalableLayer* currentLayer;
	
}

@property (readwrite, assign) ScalableLayer* currentLayer;
- (ScalableLayer*) nextLayer;
- (ScalableLayer*) previousLayer;

- (BOOL) hasNext;
- (BOOL) hasPrevious;

@end
