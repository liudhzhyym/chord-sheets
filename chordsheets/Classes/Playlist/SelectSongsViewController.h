//
//  SelectSongsViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 16.01.12.
//  copyright (c) 2012 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import "Playlist.h"

/**
 * Abstract base class for selecting songs from a given playlist.
 * Derived classes are responsible for actually doing something with
 * these songs, which is usually implemented by using a delegate.
 */

@interface SelectSongsViewController : UIViewController


@property (nonatomic, retain) NSString *letters;
@property (nonatomic, retain) NSArray *lettersPresent;
@property (nonatomic, retain) Playlist *playlist;

@property (nonatomic, assign) IBOutlet UITableView *table;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

@property (retain, nonatomic) IBOutlet UIView *statusBarBackground;


- (id)initWithNibName:(NSString *)newNibName playlist:(Playlist *)newPlaylist;
- (void)releaseReferences;
- (void)reactToLightsOutModeChange;
- (void)determineSongIndexLettersPresent;
- (void)setAllSongsSelected:(BOOL)newSelected;
- (void)setSongAtIndexPath:(NSIndexPath *)indexPath selected:(BOOL) newSelected;

- (IBAction)clickSelectAll:(id)sender;
- (IBAction)clickDeselectAll:(id)sender;


@end
