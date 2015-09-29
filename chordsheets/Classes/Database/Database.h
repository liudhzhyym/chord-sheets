//
//  Database.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 17.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Importer.h"
#import "Playlist.h"
#import "Song.h"

/**
 * Class providing the interface to the Core Data layer and the SQLite DB
 * beneath it.
 *
 * Can be accessed from everywhere by using the member of AppDelegate.
 */
@interface Database : NSObject

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) NSURL *documentsDirectoryURL;
@property (nonatomic, retain) NSMutableArray *playlistArray;
@property (nonatomic, retain) Importer *importer;
@property (nonatomic, retain) Playlist *library;
@property (nonatomic, retain) Playlist *edited;
@property (nonatomic, retain) Playlist *mySongs;

- (id)initWithDocumentsDirectoryURL:(NSURL *)newDocumentsDirectoryURL;
- (void)saveContext;
- (void)syncWithDB;
- (BOOL)restoreDefaultDB;
- (void)restoreDefaultSongs;
- (void)reparseSheets;
- (void)createAndStoreSystemPlaylists;
- (void)createAndStoreCustomPlaylistWithName:(NSString *)newName songList:(NSArray *)newSongList;
- (void)syncSongsWithSystemPlaylists;
- (void)addSong:(Song *)newSong toPlaylist:(Playlist *)newPlaylist;

- (NSNumber *)determineNonUniqueIndexForSong:(Song *)song;

- (void)importSongWithData:(NSData *)data;

@end
