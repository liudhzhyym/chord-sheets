//
//  AddSongsViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 27.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import "Playlist.h"
#import "SelectSongsViewController.h"

@class AddSongsViewController;

@protocol AddSongsViewControllerDelegate <NSObject>

@required

- (void)doneButtonPressed:(AddSongsViewController *)addSongsViewController;

@end

@interface AddSongsViewController : SelectSongsViewController

@property (nonatomic, retain) id <AddSongsViewControllerDelegate> delegate;
@property (nonatomic, retain) Playlist *playlistToBeFilled;

- (IBAction)done:(id)sender;

- (id)initWithPlaylist:(Playlist *)newPlaylist playlistToBeFilled:(Playlist *)newPlaylistToBeFilled;

@end


