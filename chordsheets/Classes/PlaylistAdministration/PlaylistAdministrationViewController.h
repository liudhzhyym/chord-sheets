//
//  PlaylistViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 14.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import "MultipeerConnectivity/MultipeerConnectivity.h"

#import "Database.h"


/**
 * ViewController for the view showing all the Playlists.
 */
@interface PlaylistAdministrationViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MCBrowserViewControllerDelegate, MCSessionDelegate>


@property (nonatomic, retain) IBOutlet UITableView *table;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, retain) Database *dataSource;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;


@property (retain, nonatomic) IBOutlet MCBrowserViewController* currentBrowserViewController;
@property (retain, nonatomic) IBOutlet MCAdvertiserAssistant* currentAssistant;


- (void)reloadTable:(NSNotification *)notification;
- (IBAction)toggleLightsOutMode:(id)sender;
- (IBAction)toggleEditingMode:(id)sender;
- (IBAction)addNewPlaylist:(id)sender;
- (IBAction)startBluetoothReceival:(id)sender;

- (void)reactToLightsOutModeChange;

- (void) browserViewControllerDidFinish: (MCBrowserViewController*) browserViewController;
- (void) browserViewControllerWasCancelled: (MCBrowserViewController*) browserViewController;

- (void) session: (MCSession*) session didReceiveData: (NSData*) data fromPeer: (MCPeerID*) peerID;
- (void) session: (MCSession*) session didStartReceivingResourceWithName: (NSString*) resourceName fromPeer: (MCPeerID*) peerID withProgress: (NSProgress*) progress;
- (void) session: (MCSession*) session didFinishReceivingResourceWithName:(NSString*) resourceName fromPeer: (MCPeerID*) peerID atURL: (NSURL*) localURL withError: (NSError*) error;
- (void) session: (MCSession*) session didReceiveStream: (NSInputStream*) stream withName: (NSString*) streamName fromPeer: (MCPeerID*) peerID;
- (void) session: (MCSession*) session peer: (MCPeerID*) peerID didChangeState: (MCSessionState) state;

@end
