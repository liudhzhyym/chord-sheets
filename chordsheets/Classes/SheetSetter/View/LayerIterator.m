//
//  LayerIterator.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "LayerIterator.h"

#import "ScalableLayer.h"


@implementation LayerIterator

- (id) copyWithZone: (NSZone*) zone {
	LayerIterator* instance = [[[self class] allocWithZone: zone] init];
	instance -> currentLayer = currentLayer;
	return instance;
	
}

@synthesize currentLayer;

- (ScalableLayer*) nextLayer {
	currentLayer = currentLayer.nextEditableElement;
	return currentLayer;
	
}

- (ScalableLayer*) previousLayer {
	currentLayer = currentLayer.previousEditableElement;
	return currentLayer;
	
}

- (BOOL) hasNext {
	return currentLayer.nextEditableElement ? YES : NO;
	
}

- (BOOL) hasPrevious {
	return currentLayer.previousEditableElement ? YES : NO;
	
}

@end
