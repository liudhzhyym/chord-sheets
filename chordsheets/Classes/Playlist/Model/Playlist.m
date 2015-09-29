//
//  Playlist.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 08.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "Playlist.h"
#import "SongIndex.h"


@implementation Playlist

@dynamic createdBySystem;
@dynamic index;
@dynamic name;
@dynamic songs;

- (NSArray *)getSongsSortedByAttribute:(NSString *)newAttributeName ascending:(BOOL)newAscending
{
    // sort depending on the SongIndex objects index member
    if ([newAttributeName isEqualToString:@"index"]) {
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:newAscending]];
        NSArray *sortedSongIndexArray = [[self songs] sortedArrayUsingDescriptors:sortDescriptors];
        
        NSMutableArray *songArray = [NSMutableArray arrayWithCapacity:5];
        
        for (SongIndex *tempIndex in sortedSongIndexArray) {
            [songArray addObject:[tempIndex song]];
        }
        
        return songArray;
    }
    // sort depending on the songs title member, since there might be many also use nonUniqueTitleIndex member
    else if([newAttributeName isEqualToString:@"title"]) {
        NSMutableArray *songArray = [NSMutableArray arrayWithCapacity:5];
        
        for (SongIndex *tempIndex in [self songs]) {
            [songArray addObject:[tempIndex song]];
        }
        
        NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:newAscending];
        NSSortDescriptor *nonUniqueSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nonUniqueTitleIndex" ascending:newAscending];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:titleSortDescriptor, nonUniqueSortDescriptor, nil];
        
        return [songArray sortedArrayUsingDescriptors:sortDescriptors];
    }
    else {
        NSMutableArray *songArray = [NSMutableArray arrayWithCapacity:5];
        
        for (SongIndex *tempIndex in [self songs]) {
            [songArray addObject:[tempIndex song]];
        }
        
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:newAttributeName ascending:newAscending]];
        
        return [songArray sortedArrayUsingDescriptors:sortDescriptors];
    }
}

@end
