//
//  LoaderCache.h
//  GameBase
//
//  Created by blinkenlichten on 28.09.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>

#import "LoaderJob.h"


@interface LoaderCache : NSObject {
	
	NSMutableArray* itemList;
	NSMutableDictionary* itemMap;
	
}

+ (LoaderCache*) sharedInstance;

- (void) storeJob: (LoaderJob*) resultObject;

- (LoaderJob*) cachedJobForPath: (NSString*) path;
NSInteger compareCachedItems (id first_param, id second_param, void* context);

- (void) flush;


@end
