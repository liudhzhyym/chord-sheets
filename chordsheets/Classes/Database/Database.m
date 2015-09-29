//
//  Database.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 17.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "Database.h"
#import <CoreData/CoreData.h>
#import "Playlist.h"
#import "SongIndex.h"
#import "Song.h"
#import "Importer.h"

@implementation Database

@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize documentsDirectoryURL;
@synthesize playlistArray;
@synthesize importer;
@synthesize library;
@synthesize edited;
@synthesize mySongs;

/**
 * DocumentsDirectoryURL is passed as param to avoid circular importing
 * with AppDelegate.
 */
- (id) initWithDocumentsDirectoryURL:(NSURL *)newDocumentsDirectoryURL
{
    self = [super init];
        
    if (self) {
        [self setDocumentsDirectoryURL:newDocumentsDirectoryURL];
        
        Importer *newImporter = [[Importer alloc] initWithObjectContext:[self managedObjectContext]];
        [self setImporter:newImporter];
        [newImporter release];
        
        /*
         * This also triggers the getter for the persistentStoreCoordinator, who in turn tries to load
         * an already existing DB file or a default file from the documents folder.
         */
        [self syncWithDB];
        
        /*
         * If there is no library, we couldnt get it from any DB file, so we have to fill the current DB with the sheets.
         * This happens for instance when the DB scheme has changed and we need to create a new seeded DB.
         */
        if (![self library]) {
            [self reparseSheets];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_managedObjectModel release];
    [_managedObjectContext release];
	[_persistentStoreCoordinator release];
	
	self.documentsDirectoryURL = nil;
	
    [playlistArray release];
	
	self.importer = nil;
	self.library = nil;
	self.edited = nil;
	self.mySongs = nil;
	
    [super dealloc];
	
}

#pragma mark - Core Data stack

/**
 * Returns the managed object context for the application.
 * If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

/**
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"chordsheets" withExtension:@"momd"];
        _managedObjectModel =[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    
    return _managedObjectModel;
}

/**
 * Returns the persistent store coordinator for the application.
 * If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSError *error = nil;
        
    NSURL *storeURL = [[self documentsDirectoryURL] URLByAppendingPathComponent:@"chordsheets.sqlite"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // if there is no SQLite DB file present, try to use the one supplied in the bundle
    if (![storeURL checkResourceIsReachableAndReturnError:&error]) {
        [self restoreDefaultDB];
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error while opening the database file:\n%@", error);
        
        // this error results most likely from a wrong DB scheme, so delete the old db file and use a blank one instead
        NSLog(@"Setting up a blanc database");
        [fileManager removeItemAtURL:storeURL error:nil];
        [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
    }    
    
    return _persistentStoreCoordinator;
}

- (void)saveContext
{
    [[self managedObjectContext] save:nil];
    [self syncWithDB];
}

#pragma mark - Methods to load songs and playlists from the DB

- (void)syncWithDB
{    
    // prepare a fetch for the system playlists
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Playlist" inManagedObjectContext:[self managedObjectContext]]];
    
    // we want the fetch to be sorted by index number
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
    NSArray *sortDescriptorArray = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptorArray];
    
    NSMutableArray *newPlaylistArray = [[[self managedObjectContext] executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    [self setPlaylistArray:newPlaylistArray];
    
    [newPlaylistArray release];
    [fetchRequest release];
    [sortDescriptorArray release];
    [sortDescriptor release];
    
    for (Playlist *tempPlaylist in [self playlistArray]) {
        if ([[tempPlaylist name] isEqualToString:@"Library"]) {
            [self setLibrary:tempPlaylist];
        }
        else if ([[tempPlaylist name] isEqualToString:@"Edited"]) {
            [self setEdited:tempPlaylist];
        }
        else if ([[tempPlaylist name] isEqualToString:@"MySongs"]) {
            [self setMySongs:tempPlaylist];
        }
    }
}

/**
 * Copies in the backup DB which is already seeded with standard library songs parsed from sheet XMLs.
 * The preseeded DB needs to have been created in iOS simulator.
 */
- (BOOL)restoreDefaultDB
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    
    NSURL *storeURL = [[self documentsDirectoryURL] URLByAppendingPathComponent:@"chordsheets.sqlite"];
    NSURL *defaultStoreURL = [[NSBundle mainBundle] URLForResource:@"chordsheets" withExtension:@"sqlite"];
    
    // abort if we couldnt find a default SQLite file
    if (defaultStoreURL == nil) {
        NSLog(@"Couldnt restore default DB");
        return false;
    }
    
    if(![fileManager copyItemAtURL:defaultStoreURL toURL:storeURL error:&error]) {
        NSLog(@"Unresolved error while trying to copy in the DB: %@, %@", error, [error userInfo]);
        return false;
    }
    else {
        NSLog(@"Copied in new chordsheets.sqlite");
        return true;
    }
}

/**
 * Copies in missing standard songs from the backup database.
 */
- (void)restoreDefaultSongs
{
    NSError *error = nil;
    
    // this check is also made to trigger the getter, which in turn initializes the database
    if (![self managedObjectContext]) {
        NSLog(@"Standard object context not present while restoring default songs!");
        return;
    }
    
    NSURL *defaultStoreURL = [[NSBundle mainBundle] URLForResource:@"chordsheets" withExtension:@"sqlite"];
    
    if(defaultStoreURL == nil) {
        NSLog(@"Could not locate default DB file while trying to restore standard songs!");
        return;
    }
    
    NSPersistentStoreCoordinator *defaultStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSReadOnlyPersistentStoreOption, nil];
    
    if (![defaultStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:defaultStoreURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSManagedObjectContext *defaultObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
    [defaultObjectContext setPersistentStoreCoordinator:defaultStoreCoordinator];
    
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Song" inManagedObjectContext:defaultObjectContext]];
    
    // we want the fetch to be sorted by index number
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptorArray = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptorArray];
    
    NSArray *songArray = [defaultObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (Song *tempSong in songArray) {
        BOOL songPresentInLibrary = NO;
        
        for (SongIndex *tempLibrarySongIndex in [[self library] songs]) {
            Song *tempLibrarySong = [tempLibrarySongIndex song];
            BOOL isTitleEqual = [[tempLibrarySong title] isEqualToString:[tempSong title]];
            BOOL isArtistEqual = [[tempLibrarySong artist] isEqualToString:[tempSong artist]];
            BOOL isNonUniqueIndexZero = ([tempLibrarySong nonUniqueTitleIndex] == [NSNumber numberWithInt:0]);
            
            if (isTitleEqual && isArtistEqual && isNonUniqueIndexZero) {
                songPresentInLibrary = YES;
                break;
            }
        }
        
        if (!songPresentInLibrary) {
            //NSLog(@"%@", [tempSong title]);
            
            Song *newSong = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:[self managedObjectContext]];
            [newSong setTitle:[tempSong title]];
            [newSong setArtist:[tempSong artist]];
            [newSong setContent:[tempSong content]];
            
            [self addSong:newSong toPlaylist:[self library]];
        }
    }
    
    [self saveContext];
    
    [defaultStoreCoordinator release];
    [sortDescriptor release];
    [sortDescriptorArray release];
    [fetchRequest release];
    [defaultObjectContext release];
}

/**
 * This method is intended to be used when running on simulator in order to create
 * a DB already seeded with the XML song sheets.
 */
- (void)reparseSheets
{
    NSLog(@"Reparsing DB content from XML sheets");
    [self createAndStoreSystemPlaylists];
    [[self importer] importAllSheets];
    [self syncSongsWithSystemPlaylists];
}

- (void)createAndStoreSystemPlaylists
{
    Playlist *newLibrary = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:[self managedObjectContext]];
    [newLibrary setValue:@"Library" forKey:@"name"];
    [newLibrary setValue:[NSNumber numberWithInt:0] forKey:@"index"];
    [newLibrary setValue:[NSNumber numberWithBool:YES] forKey:@"createdBySystem"];
    
    Playlist *newEdited = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:[self managedObjectContext]];
    [newEdited setValue:@"Edited" forKey:@"name"];
    [newEdited setValue:[NSNumber numberWithInt:1] forKey:@"index"];
    [newEdited setValue:[NSNumber numberWithBool:YES] forKey:@"createdBySystem"];
    
    Playlist *newMySongs = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:[self managedObjectContext]];
    [newMySongs setValue:@"MySongs" forKey:@"name"];
    [newMySongs setValue:[NSNumber numberWithInt:2] forKey:@"index"];
    [newMySongs setValue:[NSNumber numberWithBool:YES] forKey:@"createdBySystem"];
    
    [self saveContext];
}

- (void)createAndStoreCustomPlaylistWithName:(NSString *)newName songList:(NSArray *)newSongList
{
    Playlist *newList = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:[self managedObjectContext]];
    [newList setValue:newName forKey:@"name"];
    [newList setValue:[NSNumber numberWithInt: (int) [[self playlistArray] count]] forKey:@"index"];
    [newList setValue:[NSNumber numberWithBool:NO] forKey:@"createdBySystem"];
    
    NSMutableSet *songSet = [[NSMutableSet alloc]initWithCapacity:5];
    
    for (int n = 0; n < [newSongList count]; n++) {
        SongIndex *index = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:[self managedObjectContext]];
        [index setValue:[NSNumber numberWithInt:1] forKey:@"index"];
        [index setSong:[newSongList objectAtIndex:n]];
        [index setPlaylist:newList];
        [songSet addObject:index];
    }
    
    [newList setSongs:songSet];
    [songSet release];
    
    [self saveContext];
}

- (void)syncSongsWithSystemPlaylists
{
    NSError *error = nil;
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Song" inManagedObjectContext:[self managedObjectContext]]];
    
    // we want the fetch to be sorted by index number
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptorArray = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptorArray];
    
    NSMutableArray *songArray = [[[self managedObjectContext] executeFetchRequest:fetchRequest error:&error] mutableCopy];
    
    [fetchRequest release];
    [sortDescriptorArray release];
    [sortDescriptor release];
    
    for (id tempSong in songArray) {
        BOOL isInLibrary = false;
        BOOL isInEdited = false;
        BOOL isInMySongs = false;
        
        Song *song = (Song *)tempSong;
        
        for (id tempSongIndex in [song indices]) {
            SongIndex *songIndex = (SongIndex *)tempSongIndex;
            
            if ([[[songIndex playlist] name] isEqualToString:@"Library"]) {
                isInLibrary = YES;
            }
            
            if ([[[songIndex playlist] name] isEqualToString:@"Edited"]) {
                isInEdited = YES;
            }
            
            if ([[[songIndex playlist] name] isEqualToString:@"MySongs"]) {
                isInMySongs = YES;
            }
        }
        
        if (!isInLibrary) {
            [self addSong:song toPlaylist:[self library]];
        }
        
        if (!isInEdited && [[song cover] boolValue]) {
            [self addSong:song toPlaylist:[self edited]];
        }
        
        if (!isInMySongs && [[song selfComposed] boolValue]) {
            [self addSong:song toPlaylist:[self mySongs]];
        }
    }
    
    [self saveContext];
    [songArray release];
}

- (void)addSong:(Song *)newSong toPlaylist:(Playlist *)newPlaylist
{
    SongIndex *index = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:[self managedObjectContext]];
    [index setValue:[NSNumber numberWithInt: (int) [[newPlaylist songs] count]] forKey:@"index"];
    [index setSong:newSong];
    [index setPlaylist:newPlaylist];
}

/**
 * Used to import a new song from data, when NOT seeding the DB from
 * the XML sheet files.
 *
 * The only difference to [[self importer] readSongWithData] is that
 * the member nonUniqueTitleIndex is calculated and not automatically 0.
 * (Songs not coming from the initial parsing of the XML sheets
 * may already be contained in the DB).
 */
- (void)importSongWithData:(NSData *)data
{
    Song *newSong = [[self importer] readSongWithData:data];
    
    [newSong setValue:[NSNumber numberWithBool:YES] forKey:@"cover"];
    [newSong setValue:[self determineNonUniqueIndexForSong:newSong] forKey:@"nonUniqueTitleIndex"];
    
    [self syncSongsWithSystemPlaylists];
}

#pragma mark - Methods for creating unique song titles

- (NSNumber *)determineNonUniqueIndexForSong:(Song *)song
{
    NSString *newTitle =[song title];
    NSString *newArtist =[song artist];
               
    int largestIndex = 0;
    
    for (SongIndex *tempIndex in [library songs]) {
        Song *tempSong = [tempIndex song];
        
        // never match the song against itself
        if ([tempSong objectID] == [song objectID]) {
            continue;
        }
        
        if ([[tempSong title] isEqualToString:newTitle] && [[tempSong artist] isEqualToString:newArtist]) {
            if ([[tempSong nonUniqueTitleIndex] intValue] >= largestIndex) {
                largestIndex = [[tempSong nonUniqueTitleIndex] intValue] + 1;
            }
        }
    }
    
    return [NSNumber numberWithInt:largestIndex];
}

@end
