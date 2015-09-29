//
//  ShareSongsViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 12.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "ShareSongsViewController.h"
#import "AppDelegate.h"
#import "Song.h"
#import "SongIndex.h"

@implementation ShareSongsViewController

@synthesize delegate;
@synthesize confirmed;

- (id)initWithPlaylist:(Playlist *)newPlaylist
{
    return [super initWithNibName:@"ShareSongsView" playlist:newPlaylist];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [delegate shareControllerDisappeared:self];
	
	[super viewDidDisappear:animated];
	
}

- (IBAction)share:(id)sender
{
    [self setConfirmed:YES];
    [delegate removeShareController:self];
}

- (IBAction)cancel:(id)sender
{
    [delegate removeShareController:self];
}

- (void)dealloc {
	[super dealloc];
}
@end