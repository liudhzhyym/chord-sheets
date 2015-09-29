//
//  LoaderCache.m
//  GameBase
//
//  Created by blinkenlichten on 28.09.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import "LoaderCache.h"


@interface CachedItem : NSObject {

@public
	LoaderJob* resultObject;
	int lastAccess;
	
}

@end

@implementation CachedItem

- (NSString*) description {
	return [NSString stringWithFormat:
		@"[CachedItem last access: %i content: %@]", lastAccess, resultObject];
}

@end


@interface LoaderCache (Private)

- (void) flushWithLimit: (uint) limit keepTail: (uint) tail;

@end


@implementation LoaderCache

+ (LoaderCache*) sharedInstance {
	static LoaderCache* instance;
	if (!instance)
		instance = [[LoaderCache alloc] init];
	
	return instance;
	
}

static int accessCount = 0;


- (id) init {
	self = [super init];
	
	if (self) {
		itemList = [[NSMutableArray alloc] init];
		itemMap = [[NSMutableDictionary alloc] init];
		
	}
	return self;
	
}

static const int CAPACITY = 32;



- (void) storeJob: (LoaderJob*) resultObject {
	// NSLog (@"    ..... pushing %@", resultObject);
	NSString* keyPath = resultObject -> path;
	if ([itemMap objectForKey: keyPath]) {
		NSLog (@"warning. key path %@ already cached", keyPath);
		return;
		
	}
	
	CachedItem* item = [CachedItem new];
	item -> resultObject = [resultObject retain];
	item -> lastAccess = accessCount++;
	[resultObject addListener: self selector: @selector (destroyResult:) forEvent: @"destroy"];
	
	[itemList addObject: item];
	[itemMap setObject: item forKey: resultObject -> path];
    
    [item release];
	
	[self flushWithLimit: CAPACITY keepTail: 1];
	
}

- (void) flush {
	[self flushWithLimit: 0 keepTail: 0];
	
}

NSInteger compareCachedItems (id first_param, id second_param, void* context) {
    CachedItem* a = (CachedItem *)first_param;
    CachedItem* b = (CachedItem *)second_param;
    // NSLog (@"compare %@ to %@ (%f to %f)", a, b, a -> lastAccess, b -> lastAccess);
    return
    a -> lastAccess > b -> lastAccess ? NSOrderedAscending :
    a -> lastAccess == b -> lastAccess ? NSOrderedSame :
    NSOrderedDescending;
    
}

- (void) flushWithLimit: (uint) limit keepTail: (uint) tail {
	int numCachedObjects = (int) [itemList count];
    
	if (numCachedObjects > limit) {
		[itemList sortUsingFunction:compareCachedItems context: nil];
		
		for (int i = numCachedObjects; i-- > tail && numCachedObjects > limit;) {
			CachedItem* item = [itemList objectAtIndex: i];
			if ([item -> resultObject retainCount] > 1) {
				NSLog (@"sorry. won't dispose now, item %@ is retained.", item -> resultObject);
				if (!i)
					NSLog (@"warning. cache is completely retained.");
				
			} else {
			
			
				LoaderJob* resultObject = item -> resultObject;
				(void) resultObject;
				 NSLog (@"removing %lu from cache", (unsigned long)item -> resultObject.retainCount);
				[item -> resultObject release];
				[itemMap removeObjectForKey: item -> resultObject -> path];
				[itemList removeObjectAtIndex: i];
				numCachedObjects--;
				
			}
			
		}
		
	}

}

- (void) destroyResult: (LoaderJob*) job {
	// NSLog (@"cache must invalidate %@", job -> path);
	[itemMap removeObjectForKey: job -> path];
	[itemList removeObjectIdenticalTo: job -> path];
	
}

- (LoaderJob*) cachedJobForPath: (NSString*) keyPath {
	CachedItem* item = [itemMap objectForKey: keyPath];
	if (item) {
		item -> lastAccess = accessCount++;
		return item -> resultObject;
		
	} else
		return nil;
		
}

- (void) dealloc {
	[itemList release];
	itemList = nil;
	
	[itemMap release];
	itemMap = nil;
	
	[super dealloc];

}

@end
