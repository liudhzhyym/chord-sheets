//
//  PlaylistDetailViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 17.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "MultipeerConnectivity/MultipeerConnectivity.h"

#import "Playlist.h"
#import "SongIndex.h"
#import "SheetSetterViewController.h"
#import "Database.h"
#import "AddSongsViewController.h"
#import "SelectSongsViewController.h"
#import "ShareSongsViewController.h"


@interface PlaylistViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate,  AddSongsViewControllerDelegate, ShareSongsViewControllerDelegate, MFMailComposeViewControllerDelegate, MCBrowserViewControllerDelegate, MCSessionDelegate> {
	
}

@property (nonatomic, retain) Playlist *playlist;
@property (nonatomic, retain) Database *playlistDataSource;
@property (nonatomic, retain) NSString *letters;
@property (nonatomic, retain) NSArray *lettersPresent;
@property (nonatomic, retain) NSString *sortKeyName;
@property (nonatomic, retain) SheetSetterViewController *sheetController;

@property (nonatomic, assign) IBOutlet UITableView *table;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UISegmentedControl *sortingStyleSelector;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;


@property (retain, nonatomic) IBOutlet MCBrowserViewController* currentBrowserViewController;
@property (retain, nonatomic) IBOutlet MCAdvertiserAssistant* currentAssistant;

@property (nonatomic) BOOL didPresentSelector;


- (IBAction)sortingChanged:(id)sender;
- (IBAction)sharePaylist:(id)sender;
- (IBAction)composeNewSong:(id)sender;
- (IBAction)addExistingSong:(id)sender;

- (id)initWithPlaylist:(Playlist *)newPlaylist dataSource:(Database *)newDataSource;
- (void)reloadTable:(NSNotification *)notification;
- (void)reactToLightsOutModeChange;
- (void)determineSongIndexLettersPresent;
- (Song *)songForRowAtIndexPath:(NSIndexPath *)indexPath;
- (SongIndex *)songIndexForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void) presentMCBrowserController;

- (void) browserViewControllerDidFinish: (MCBrowserViewController*) browserViewController;
- (void) browserViewControllerWasCancelled: (MCBrowserViewController*) browserViewController;

- (void) session: (MCSession*) session didReceiveData: (NSData*) data fromPeer: (MCPeerID*) peerID;
- (void) session: (MCSession*) session didStartReceivingResourceWithName: (NSString*) resourceName fromPeer: (MCPeerID*) peerID withProgress: (NSProgress*) progress;
- (void) session: (MCSession*) session didFinishReceivingResourceWithName:(NSString*) resourceName fromPeer: (MCPeerID*) peerID atURL: (NSURL*) localURL withError: (NSError*) error;
- (void) session: (MCSession*) session didReceiveStream: (NSInputStream*) stream withName: (NSString*) streamName fromPeer: (MCPeerID*) peerID;
- (void) session: (MCSession*) session peer: (MCPeerID*) peerID didChangeState: (MCSessionState) state;

@end
