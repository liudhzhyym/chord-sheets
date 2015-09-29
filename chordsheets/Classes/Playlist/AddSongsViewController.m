//
//  AddSongsViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 27.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <CoreData/CoreData.h>
#import "AddSongsViewController.h"
#import "SongIndex.h"
#import "Song.h"
#import "AppDelegate.h"
#import "PlaylistAdministrationViewController.h"

@implementation AddSongsViewController

@synthesize delegate;
@synthesize playlistToBeFilled;

- (id)initWithPlaylist:(Playlist *)newPlaylist playlistToBeFilled:(Playlist *)newPlaylistToBeFilled
{
    self = [super initWithNibName:@"AddSongsView" playlist:newPlaylist];
    
    if (self) {
        [self setPlaylistToBeFilled:newPlaylistToBeFilled];
        [self setPlaylist:newPlaylist];
        self.navigationItem.title = @"Add to Playlist";
        [self setLetters:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    }
    
    return self;
}

- (void) releaseReferences {
    [super releaseReferences];
	self.playlistToBeFilled = nil;
}

#pragma mark -
#pragma mark IBAction methods

- (IBAction)done:(id)sender
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [[appDelegate database] managedObjectContext];
    
    for (int n= 0; n < [[[self playlist] songs] count]; n++) {
        for (SongIndex *songIndex in [[self playlist] songs]) {
            Song *song = [songIndex song];
            
            if ([[songIndex index] intValue] == n && [song isSelected])
            {
                NSMutableSet *songIndexSet = [[self playlistToBeFilled] mutableSetValueForKey:@"songs"];
                
                SongIndex *index = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:context];
                [index setValue:[NSNumber numberWithInt: (int) [songIndexSet count]] forKey:@"index"];
                [index setSong:song];
                [index setPlaylist:[self playlistToBeFilled]];
                
                [songIndexSet addObject:index];
                break;
            }
        }
    }
             
    NSError *saveError = nil;
    [context save:&saveError];
    
    [[self delegate] doneButtonPressed:self];
}

@end
