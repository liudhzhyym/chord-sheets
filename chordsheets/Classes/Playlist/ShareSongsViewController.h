//
//  ShareSongsViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 12.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import "Playlist.h"
#import "SelectSongsViewController.h"

@class ShareSongsViewController;

@protocol ShareSongsViewControllerDelegate <NSObject>

@required

- (void)removeShareController:(ShareSongsViewController *)shareSongsViewController;
- (void)shareControllerDisappeared:(ShareSongsViewController *)shareSongsViewController;

@end

@interface ShareSongsViewController : SelectSongsViewController

@property (nonatomic, retain) id <ShareSongsViewControllerDelegate> delegate;
@property (nonatomic, assign, getter = wasConfirmed) BOOL confirmed;

- (id)initWithPlaylist:(Playlist *)newPlaylist;

- (IBAction)share:(id)sender;
- (IBAction)cancel:(id)sender;

@end
