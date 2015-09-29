//
//  SongIndex.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 08.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Playlist, Song;

@interface SongIndex : NSManagedObject

@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Playlist *playlist;
@property (nonatomic, retain) Song *song;

@end
