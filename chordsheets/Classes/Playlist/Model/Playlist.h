//
//  Playlist.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 08.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SongIndex;

@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSNumber *createdBySystem;
@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *songs;

- (NSArray *)getSongsSortedByAttribute:(NSString *)newAttributeName ascending:(BOOL)newAscending;

@end

@interface Playlist (CoreDataGeneratedAccessors)

- (void)addSongsObject:(SongIndex *)value;
- (void)removeSongsObject:(SongIndex *)value;
- (void)addSongs:(NSSet *)values;
- (void)removeSongs:(NSSet *)values;

@end
