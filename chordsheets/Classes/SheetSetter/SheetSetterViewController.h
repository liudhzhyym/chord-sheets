//
//  SheetSetterViewController.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.06.10.
//  Copyright wysiwyg* software design gmbh 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"
#import "Sheet.h"
#import "KeyViewController.h"
#import "PlayBackViewController.h"
#import "AttributedChord.h"
#import "KeySignature.h"
#import "TimeSignature.h"
#import "OpeningBarLine.h"
#import "ClosingBarLine.h"
#import "Database.h"
#import "Playlist.h"


@interface SheetSetterViewController : UIViewController <UIActionSheetDelegate, UIDocumentInteractionControllerDelegate, SheetEditingDelegate>

@property (nonatomic, retain) Playlist *playlist;
@property (nonatomic, retain) Song *song;
@property (nonatomic, retain) Sheet *sheet;
@property (nonatomic, retain) Sheet *sheetBeforeEditing;
@property (nonatomic, assign) BOOL isEditingNewSong;

@property (nonatomic, retain) SheetScrollView *sheetScrollView;
@property (nonatomic, retain) KeyViewController *keyController;
@property (nonatomic, retain) PlayBackViewController *playBackController;
@property (nonatomic, retain) Database *database;
@property (nonatomic, retain) NSString *sortKeyName;
@property (nonatomic, assign) float BPMBeforeEditing;
@property (nonatomic, assign) float BPMAfterEditing;

- (id)initWithDataSource:(Database *)newDataSource playlist:(Playlist *)newPlaylist sortKey:(NSString *)newSortKey song:(Song *)newSong;

- (void)openKeyControllerWithKeySet:(NSString *)keySetName element:(id)element sheetView:(SheetView *)sheetview;
- (void)closeKeyController;
- (void)openPlaybackController;
- (void)closePlaybackController;
- (void)saveSongIfEdited;
- (void)saveSelfComposedSong;
- (void)saveSongAsCopy;
- (void)setSong:(Song *)song;

- (IBAction)buttonTapped:(id)sender;
- (IBAction)keyTapped:(id)sender;
- (IBAction)transposeSheet:(id)sender;

- (void)showTransposeConfirmation;

- (void) presentExportMenu: (id) sender;

@end
