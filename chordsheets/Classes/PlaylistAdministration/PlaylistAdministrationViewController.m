//
//  PlaylistViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 14.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "PlaylistAdministrationViewController.h"
#import "PlaylistViewController.h"
#import "AddSongsViewController.h"
#import "Playlist.h"
#import "Song.h"
#import "AppDelegate.h"


@implementation PlaylistAdministrationViewController

@synthesize table;
@synthesize editButton;
@synthesize dataSource;

@synthesize currentBrowserViewController;
@synthesize currentAssistant;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        [self setDataSource:[(AppDelegate *)[[UIApplication sharedApplication] delegate] database]];
        
        self.navigationItem.title = @"Playlists";
        UIBarButtonItem *plusButton = 
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewPlaylist:)];
        self.navigationItem.rightBarButtonItem = plusButton;
        [plusButton release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:UIApplicationDidBecomeActiveNotification object:nil];
		
    }
    
    return self;
}

- (void) releaseReferences {
    [table release];
	self.editButton = nil;
	
    [dataSource release];
	
}

- (void) dealloc
{
    [self releaseReferences];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[_toolbar release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	table.contentInset = UIEdgeInsetsMake (0, 0, self.toolbar.bounds.size.height, 0);
	table.scrollIndicatorInsets = UIEdgeInsetsMake (0, 0, self.toolbar.bounds.size.height, 0);
	
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (animated)
		[[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self reactToLightsOutModeChange];
	
    [[self table] reloadData];
	
}

- (void) viewDidAppear:(BOOL)animated {
	[[self navigationController] setNavigationBarHidden:NO animated:YES];
	
	[super viewDidAppear:animated];

	[self setNeedsStatusBarAppearanceUpdate];
	
}

-(void)reloadTable:(NSNotification *)notification
{
    [[self table] reloadData];
}

- (IBAction)toggleEditingMode:(id)sender
{
    [table setEditing: ![table isEditing] animated: YES];
    
    if ([table isEditing]) {
        [editButton setTitle:@"Done"];
    }
    else {
        [editButton setTitle:@"Edit"];
    }
}

- (IBAction)toggleLightsOutMode:(id)sender
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [appDelegate setLightsOutModeEnabled:![appDelegate isLightsOutModeEnabled]];
    
    [self reactToLightsOutModeChange];
    
    [[self table] reloadData];
}

- (IBAction)addNewPlaylist:(id)sender
{
	
	UIAlertController* alert = [UIAlertController
		alertControllerWithTitle: @"New Playlist"
		message: @"Enter a name for the new playlist"
        preferredStyle: UIAlertControllerStyleAlert
		
	];
	
	[alert addTextFieldWithConfigurationHandler: nil];
	
	[alert addAction:
		[UIAlertAction
			actionWithTitle: @"Add"
			style: UIAlertActionStyleDefault
			handler: ^(UIAlertAction * _Nonnull action) {
				UITextField *textField = [alert.textFields objectAtIndex: 0];
				
				if ([[textField text] length] > 0) {
					[[self dataSource] createAndStoreCustomPlaylistWithName:[textField text] songList:nil];
					[table reloadData];
					
				}
				
			}
			
		]
		
	];
	[alert addAction:
		[UIAlertAction
			actionWithTitle: @"Cancel"
			style: UIAlertActionStyleCancel
			handler: ^(UIAlertAction * _Nonnull action) {
				NSLog (@"cancel");
				
			}
			
		]
		
	];
	
	[self presentViewController: alert animated: YES completion: nil];
	
}

- (void)reactToLightsOutModeChange
{
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
    
	if (isLightsOut) {
        table.backgroundColor = [UIColor colorWithWhite: .05f alpha: 1];
        table.separatorColor = [UIColor colorWithWhite: .5 alpha: 1];
		table.indicatorStyle = UIScrollViewIndicatorStyleWhite;
		
    } else {
		table.backgroundColor = [UIColor colorWithWhite: 1 alpha: 1];
		table.separatorColor = [UIColor colorWithWhite: .5 alpha: .5];
		table.indicatorStyle = UIScrollViewIndicatorStyleDefault;
		
    }
	
	[self setNeedsStatusBarAppearanceUpdate];
 
	UINavigationBar* navigationBar = self.navigationController.navigationBar;
	
	navigationBar.barTintColor = isLightsOut ?
		[UIColor colorWithRed: 0x25 / 255.f green: 0x0e / 255.f blue: 0x12 / 255.f alpha: .75] :
		nil;
	
	navigationBar.tintColor = isLightsOut ?
		[UIColor colorWithWhite: .5 alpha: 1.] : // [UIColor colorWithRed: 215 / 255.f green: 235 / 255.f blue: 255 / 255.f alpha: 1.] :
		[UIColor colorWithRed: 0x25 / 255.f green: 0x0e / 255.f blue: 0x12 / 255.f alpha: .75]; // [UIColor colorWithWhite: 0 alpha: 1];
	
	navigationBar.titleTextAttributes = isLightsOut ?
		// @{UITextAttributeTextColor: [UIColor colorWithWhite: .5 alpha: 1]} :
		@{NSForegroundColorAttributeName: [UIColor colorWithWhite: (CGFloat) .7 alpha: 1]} :
		@{NSForegroundColorAttributeName: [UIColor colorWithWhite: 0 alpha: 1]};
	
	_toolbar.barTintColor = navigationBar.barTintColor;
	_toolbar.tintColor = navigationBar.tintColor;
	
	appDelegate.barTintColor = navigationBar.barTintColor;
	appDelegate.tintColor = navigationBar.tintColor;
	
	// UIColor* navigationBarTintColor = navigationBar.barTintColor;
	// const float* tintColorComponents = CGColorGetComponents (navigationBarTintColor.CGColor);
	// UIColor* tintColor = [UIColor colorWithRed: tintColorComponents [0] green: tintColorComponents [1] blue: tintColorComponents [2] alpha: 1.f];
	
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
	return isLightsOut ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
	
}

#pragma mark -
#pragma mark Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the Playlist
    Playlist *playList = [[[self dataSource] playlistArray] objectAtIndex:indexPath.row];
    
    UIViewController *newController = [[PlaylistViewController alloc] initWithPlaylist:playList dataSource:[self dataSource]];
    [self.navigationController pushViewController:newController animated:YES];
    [newController release];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[((Playlist *)[dataSource.playlistArray objectAtIndex:[indexPath row]]) createdBySystem] boolValue]) {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
}

#pragma mark -
#pragma mark Methods formatting the cells and defining the possible actions

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Playlist *playList = [[[self dataSource] playlistArray] objectAtIndex:[indexPath row]];
    
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.backgroundColor = [UIColor clearColor];
		
		UIView* selectionBackgroundView = [[[UIView alloc] init] autorelease];
		selectionBackgroundView.backgroundColor = [UIColor colorWithWhite: .5 alpha: .25];
		cell.selectedBackgroundView = selectionBackgroundView;
		
    }
    
    // since the cells are reused, we always have to set the font 
    if ([[playList createdBySystem] boolValue]) {
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
    }
    else {
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    }
    
    [cell.textLabel setText:[playList name]];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%lu", (unsigned long)playList.songs.count]];
    
    BOOL lightsOut = [(AppDelegate *)[[UIApplication sharedApplication] delegate] isLightsOutModeEnabled];
    
    if (!lightsOut) {
        [cell.textLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
        [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1]];
    }
    else {
        [cell.textLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [cell.detailTextLabel setTextColor:[UIColor colorWithRed:.75f green:.75f blue:.75f alpha:1]];
    }
	
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self dataSource] playlistArray] count];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Playlist *tempPlayList = [[[self dataSource] playlistArray] objectAtIndex:[fromIndexPath row]];
    [[[self dataSource] playlistArray] removeObjectAtIndex:[fromIndexPath row]];
    [[[self dataSource] playlistArray] insertObject:tempPlayList atIndex:[toIndexPath row]];
    
    for (int n = 0; n < [[[self dataSource] playlistArray] count]; n++) {
        Playlist *tempPlayList = [[[self dataSource] playlistArray] objectAtIndex:n];
        [tempPlayList setIndex:[NSNumber numberWithInt:n]];
    }
    
    [[self dataSource] saveContext];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Playlist *playlist = [[[self dataSource] playlistArray] objectAtIndex:[indexPath row]];
        [[[self dataSource] playlistArray] removeObjectAtIndex:[indexPath row]];
        
        [[[self dataSource] managedObjectContext] deleteObject:playlist];
        
        // set the correct indices again
        for (int n = 0; n < [[[self dataSource] playlistArray] count]; n++) {
            Playlist *tempPlayList = [[[self dataSource] playlistArray] objectAtIndex:n];
            [tempPlayList setIndex:[NSNumber numberWithInt:n]];
        }
    }
    
    [[self dataSource] saveContext];
    
    [tableView reloadData];
}

# pragma mark - Methods for bluetooth receival

- (IBAction)startBluetoothReceival:(id)sender
{
	MCPeerID* peerId = [[MCPeerID alloc] initWithDisplayName: @"Chord Sheets Receiver"];
	MCSession* session = [[MCSession alloc] initWithPeer: peerId];
	session.delegate = self;
	
	/*
	MCAdvertiserAssistant *assistant = [[MCAdvertiserAssistant alloc]
		initWithServiceType: @"idb-share"
		discoveryInfo: nil
        session: session];
	
	[assistant start];
	*/
	
    MCBrowserViewController* browserViewController = [[MCBrowserViewController alloc] initWithServiceType: @"idb-share" session: session];
    browserViewController.delegate = self;
	
	[self presentViewController: browserViewController animated: YES completion: ^{
		
	}];
	
	self.currentBrowserViewController = browserViewController;
	//self.currentAssistant = assistant;
	
	//[assistant release];
	[browserViewController release];
	[session release];
	[peerId release];
	
}

- (void) stopBluetoothReceival {
	[self.currentAssistant stop];
	self.currentAssistant = nil;
	
	[self.currentBrowserViewController dismissViewControllerAnimated: YES completion: ^{
		
	}];
	self.currentBrowserViewController.delegate = nil;
	self.currentBrowserViewController = nil;
	
}

- (void) browserViewControllerDidFinish: (MCBrowserViewController*) browserViewController {
	[self stopBluetoothReceival];
	
}

- (void) browserViewControllerWasCancelled: (MCBrowserViewController*) browserViewController {
	[self stopBluetoothReceival];
	
}

- (void) session: (MCSession*) session didReceiveData: (NSData*) data fromPeer: (MCPeerID*) peerID {
    [[self dataSource] importSongWithData:data];
    [[self table] reloadData];
	
	session.delegate = nil;
	[session disconnect];
	
	[self stopBluetoothReceival];
	
}

- (void) session: (MCSession*) session didStartReceivingResourceWithName: (NSString*) resourceName fromPeer: (MCPeerID*) peerID withProgress: (NSProgress*) progress {

}

- (void) session: (MCSession*) session didFinishReceivingResourceWithName:(NSString*) resourceName fromPeer: (MCPeerID*) peerID atURL: (NSURL*) localURL withError: (NSError*) error {

}

- (void) session: (MCSession*) session didReceiveStream: (NSInputStream*) stream withName: (NSString*) streamName fromPeer: (MCPeerID*) peerID {

}

- (void) session: (MCSession*) session peer: (MCPeerID*) peerID didChangeState: (MCSessionState) state {
	
}

@end
