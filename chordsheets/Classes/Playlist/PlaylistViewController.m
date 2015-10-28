//
//  PlaylistDetailViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 17.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "PlaylistViewController.h"
#import "PlaylistAdministrationViewController.h"
#import "Playlist.h"
#import "SongIndex.h"
#import "Song.h"
#import "AppDelegate.h"

#import "Sheet.h"
#import "ParserContext.h"
#import "SheetSetterViewController.h"
#import "AddSongsViewController.h"
#import "ShareSongsViewController.h"


@implementation PlaylistViewController

@synthesize playlist;
@synthesize playlistDataSource;
@synthesize letters;
@synthesize lettersPresent;
@synthesize sortKeyName;
@synthesize sheetController;
@synthesize table;
@synthesize sortingStyleSelector;
@synthesize editButton;

@synthesize currentBrowserViewController;
@synthesize currentAssistant;


- (id)initWithPlaylist:(Playlist *)newPlaylist dataSource:(Database *)newDataSource
{
    self = [super initWithNibName:@"PlaylistView" bundle:[NSBundle mainBundle]];
    
    if (self) {
        [self setPlaylist:newPlaylist];
        [self setPlaylistDataSource:newDataSource];
        self.navigationItem.title = [newPlaylist name];
        
		
        [self setLetters:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        [self setLettersPresent:[NSArray array]];
        [self setSortKeyName:@"title"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:UIApplicationDidBecomeActiveNotification object:nil];
		
		// [[self table] setNeedsLayout];
        if ([[playlist name] isEqualToString:@"Library"] || [[playlist name] isEqualToString:@"MySongs"]) {
			
            UIBarButtonItem *newButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeNewSong:)];
			
			
            self.navigationItem.rightBarButtonItem = newButton;
            [newButton release];
			
        }
        else if ([[playlist name] isEqualToString:@"Edited"]) {
            
        }
        else {
            UIBarButtonItem *newButton =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addExistingSong:)];
			
            self.navigationItem.rightBarButtonItem = newButton;
            [newButton release];
			
        }
		
		// [[self table] reloadData];
		
    }
    
    return self;
}

- (void) releaseReferences {
    [playlist release];
	self.playlistDataSource = nil;
	
    [letters release];
    [lettersPresent release];
    [sortKeyName release];
    [sheetController release];
	
	self.table = nil;
	self.sortingStyleSelector = nil;
    [editButton release];
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
	
    // custom sorting is diabled for the library
    if ([[playlist name] isEqualToString:@"Library"]) {
        [sortingStyleSelector setEnabled:NO forSegmentAtIndex:2];
    }
    
    [self reactToLightsOutModeChange];
    [[self sortingStyleSelector] setSelectedSegmentIndex:1];
	
	[self setNeedsStatusBarAppearanceUpdate];
	
}

-(UIStatusBarStyle) preferredStatusBarStyle {
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
	return isLightsOut ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    if (!self.didPresentSelector &&
		[[[self playlist] songs] count] == 0 &&
        ![[[self playlist] name] isEqualToString:@"Library"] &&
        ![[[self playlist] name] isEqualToString:@"MySongs"] &&
        ![[[self playlist] name] isEqualToString:@"Edited"]) {
		
		self.didPresentSelector = YES;
		
        Playlist *library = [[[self playlistDataSource] playlistArray] objectAtIndex:0];
        AddSongsViewController *newController = [[AddSongsViewController alloc] initWithPlaylist:library playlistToBeFilled:[self playlist]];
        [newController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [newController setDelegate:self];
        [self presentViewController:newController animated:YES completion:nil];
        [newController release];
    }
	
}

- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	[self setNeedsStatusBarAppearanceUpdate];
	
}

#pragma mark - Sorting related methods

- (void)determineSongIndexLettersPresent
{
    NSMutableDictionary *tempLettersPresent = [NSMutableDictionary dictionaryWithCapacity:5];
    
    if ([sortKeyName isEqualToString:@"title"]) {
        for (SongIndex *tempIndex in [[self playlist] songs]) {
            NSString *firstTitleLetter = [[[tempIndex song] title] substringToIndex:1];
            
            NSRange searchRange = [[self letters] rangeOfString:firstTitleLetter];
            
            if (searchRange.location != NSNotFound) {
                [tempLettersPresent setValue:[NSNumber numberWithBool:YES] forKey:firstTitleLetter];
            }
            else {
                [tempLettersPresent setValue:[NSNumber numberWithBool:YES] forKey:@"#"];
            }
        }
    }
    else if ([sortKeyName isEqualToString:@"artist"]) {        
        for (SongIndex *tempIndex in [[self playlist] songs]) {
            NSString *firstArtistLetter = [[[tempIndex song] artist] substringToIndex:1];
            
            NSRange searchRange = [[self letters] rangeOfString:firstArtistLetter options:NSCaseInsensitiveSearch];
            
            if (searchRange.location != NSNotFound) {
                [tempLettersPresent setValue:[NSNumber numberWithBool:YES] forKey:firstArtistLetter];
            }
            else {
                [tempLettersPresent setValue:[NSNumber numberWithBool:YES] forKey:@"#"];
            }
        }
    }
    
    [self setLettersPresent:[[tempLettersPresent allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
}

- (IBAction)sortingChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    NSString *selectedText = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
    
    NSRange testRange = {0, 3};
    
    if (![[selectedText substringWithRange:testRange] isEqualToString:@"custom"]) {
        [self setSortKeyName:selectedText];
        
        // abort editing mode (if active) since the user could just be leaving custom sorting view (where edit is allowed)
        if ([table isEditing]) {
            [table setEditing: NO animated: YES];
            [editButton setTitle:@"Edit"];
        }
    }
    else {
        [self setSortKeyName:selectedText];
    }
    
    [table reloadData];
}

- (SongIndex *)songIndexForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *song = [self songForRowAtIndexPath:indexPath];
    
    for (id object in self.playlist.songs) {
        SongIndex *songIndex = (SongIndex *)object;
        Song *tempSong = [songIndex song];
        
        if (tempSong == song) {
            return songIndex;
        }
    }
    
    return nil;
}

- (Song *)songForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *songArray;
    
    if ([sortKeyName isEqualToString:@"custom"]) {
        songArray = [[self playlist] getSongsSortedByAttribute:@"index" ascending:YES];
        return [songArray objectAtIndex:[indexPath row]];
    }
    else
    {
        songArray = [[self playlist] getSongsSortedByAttribute:sortKeyName ascending:YES];
    }
    
    int songRowNumber = 0;
    
    NSString *indexCharacter = [[self lettersPresent] objectAtIndex:[indexPath section]];
    
    for (Song *song in songArray) {        
        NSString *primaryProperty;
        
        if ([sortKeyName isEqualToString:@"artist"]) {
            primaryProperty = [song artist];
        }
        else {
            primaryProperty = [song title];
        }
        
        NSString *firstLetterOfSortKey = [primaryProperty substringWithRange:NSMakeRange(0, 1)];
        NSRange range = [letters rangeOfString:firstLetterOfSortKey];
        
        BOOL isNotALetter = (range.location == NSNotFound);
        
        if ([[primaryProperty substringToIndex:1] isEqualToString:indexCharacter] || ([indexCharacter isEqualToString:@"#"] && isNotALetter)) {
            if (songRowNumber == [indexPath row]) {
                return song;
            }
            
            songRowNumber++;
        }
    }
    
    return nil;
}

#pragma mark - Editing the playlist

- (IBAction)editButtonPressed:(id)sender
{
    // show action sheet if button was in "Edit" mode
    if ([[editButton title] isEqualToString:@"Edit"]) {
        if ([[playlist name] isEqualToString:@"Library"]) {
            // turn editing mode on
            [table setEditing: YES animated: YES];
            [editButton setTitle:@"Done"];
        }
        else if ([[playlist name] isEqualToString:@"MySongs"] || [[playlist name] isEqualToString:@"Edited"]) {
            // turn editing mode on
            [table setEditing: YES animated: YES];
            [editButton setTitle:@"Done"];
        }
        else {
			UIAlertController* myMenu =
				[UIAlertController alertControllerWithTitle: @"Edit Options"
					message: @""
					preferredStyle: UIAlertControllerStyleActionSheet
					
				];
			
			[myMenu addAction:
				[UIAlertAction
					actionWithTitle: @"Rename playlist"
					style: UIAlertActionStyleDefault
					handler: ^(UIAlertAction * _Nonnull action) {
                        
                        UIAlertController* alert = [UIAlertController
                            alertControllerWithTitle: [playlist name]
                            message: @"Enter a new name"
                            preferredStyle: UIAlertControllerStyleAlert
                            
                        ];
                        
                        [alert addTextFieldWithConfigurationHandler: ^(UITextField * _Nonnull textField) {
                            [textField setText: [playlist name]];
                            
                        }];
                        
                        [self presentViewController: alert animated: YES completion: nil];
                        
					}
					
				]
				
			];
			
			[myMenu addAction:
				[UIAlertAction
					actionWithTitle: @"Organize songs"
					style: UIAlertActionStyleDefault
					handler: ^(UIAlertAction * _Nonnull action) {
						// turn editing mode on
						[table setEditing: YES animated: YES];
						[editButton setTitle:@"Done"];
						
					}
					
				]
				
			];
			
			[myMenu addAction:
				[UIAlertAction
					actionWithTitle: @"Cancel"
					style: UIAlertActionStyleCancel
					handler: ^(UIAlertAction * _Nonnull action) {
						// NSLog(@"cancel");
						
					}
					
				]
				
			];
			
			UIView* sourceView = self.toolbar;
			
			myMenu.popoverPresentationController.sourceView = sourceView;
			myMenu.popoverPresentationController.sourceRect = CGRectMake (
				sourceView.bounds.size.width - 60,
				0,
				60,
				sourceView.bounds.size.height
				
			);
			
			
			[self presentViewController: myMenu animated: YES completion: nil];
			
			/*
            UIActionSheet *myMenu;
            myMenu = [[[UIActionSheet alloc]
                       initWithTitle: @""
                       delegate:self
                       cancelButtonTitle:@"Cancel"
                       destructiveButtonTitle:nil
                       otherButtonTitles:@"Rename playlist", @"Organize songs", nil] autorelease];
            
            [myMenu showInView:[self view]];
			
			*/
			
        }
    }
    // end editing when button was in "Done" mode
    else {
        [table setEditing: NO animated: YES];
        [editButton setTitle:@"Edit"];
    }
}

- (IBAction)composeNewSong:(id)sender
{
    NSManagedObjectContext *objectContext = [[self playlistDataSource] managedObjectContext];
    
    Song *newSong = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:objectContext];
    [newSong setValue:@"New Song" forKey:@"title"];
    [newSong setValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"selfcomposedArtist"] forKey:@"artist"];
    [newSong setValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"selfcomposedAuthor"] forKey:@"author"];
    [newSong setCompositionPrototype:YES];
    [newSong setValue:@"" forKey:@"content"];
    
    Playlist *library;
    Playlist *mySongs;
    
    for (id tempPlaylist in [playlistDataSource playlistArray]) {
        if ([[(Playlist *) tempPlaylist name] isEqualToString:@"Library"]) {
            library = (Playlist *) tempPlaylist;
            
            SongIndex *librarySongIndex = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:objectContext];
            [librarySongIndex setValue:[NSNumber numberWithInt: (int) [[library songs] count]] forKey:@"index"];
            [librarySongIndex setSong:newSong];
            [librarySongIndex setPlaylist: library];
            [library addSongsObject:librarySongIndex];
        }
        
        if ([[(Playlist *) tempPlaylist name] isEqualToString:@"MySongs"]) {
            mySongs = (Playlist *) tempPlaylist;
            
            SongIndex *mySongsSongIndex = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:objectContext];
            [mySongsSongIndex setValue:[NSNumber numberWithInt: (int) [[mySongs songs] count]] forKey:@"index"];
            [mySongsSongIndex setSong:newSong];
            [mySongsSongIndex setPlaylist: mySongs];
            [mySongs addSongsObject:mySongsSongIndex];
        }
    }
    
    Database *db = [self playlistDataSource];
    Playlist *list = [self playlist];
    NSString *sortKey = [self sortKeyName];
    
    SheetSetterViewController *newSheetController = [[SheetSetterViewController alloc] initWithDataSource:db playlist:list sortKey:sortKey song:newSong];
    newSheetController.isEditingNewSong = YES;
	
    [self setSheetController:newSheetController];
    [self.navigationController pushViewController:newSheetController animated:YES];
    [newSheetController release];
}

- (IBAction)addExistingSong:(id)sender
{
    Playlist *library = [[[self playlistDataSource] playlistArray] objectAtIndex:0];
    AddSongsViewController *newController = [[AddSongsViewController alloc] initWithPlaylist:library playlistToBeFilled:[self playlist]];
    [newController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [newController setDelegate:self];
    [self presentViewController:newController animated:YES completion:nil];
    [newController release];
}

#pragma - Sharing songs from the playlist

- (IBAction)sharePaylist:(id)sender
{
    ShareSongsViewController *newController = [[ShareSongsViewController alloc] initWithPlaylist:[self playlist]];
    [newController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [newController setDelegate:self];
    [self presentViewController:newController animated:YES completion:nil];
    [newController release];
}

#pragma mark - UITableViewDataSource implementations

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[[self playlist] songs] count] == 0) {
        return 0;
    }
    
    [self determineSongIndexLettersPresent];
    
    if ([sortKeyName isEqualToString:@"title"] || [sortKeyName isEqualToString:@"artist"]) {
        return [[self lettersPresent] count];
    }
    // custom sorting always uses one section
    else {
        return 1;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    [self determineSongIndexLettersPresent];
    return [self lettersPresent];
}
 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.playlist) {
        return 0;
    }
    else if ([sortKeyName isEqualToString:@"artist"] || [sortKeyName isEqualToString:@"title"]) {        
        NSUInteger numEntries = 0;
        
        NSString *character = [[self lettersPresent] objectAtIndex:section];
        
        NSString *sortKey;
        
        for (SongIndex *object in [[self playlist ] songs]) {
            Song *song = [object song];
            
            if ([sortKeyName isEqualToString:@"title"]) {
                sortKey = [song title];
            }
            else {
                sortKey = [song artist];
            }
            
            if (![character isEqualToString:@"#"]) {
                if ([[sortKey substringToIndex:1] isEqualToString:character]) {
                    numEntries++;
                }
            }
            else {
                NSString *firstLetterOfSortKey = [sortKey substringWithRange:NSMakeRange(0, 1)];
                NSRange range = [letters rangeOfString : firstLetterOfSortKey];
                
                BOOL isNotALetter = (range.location == NSNotFound);
                
                if ([sortKey characterAtIndex:0] == '#' || isNotALetter) {
                    numEntries++;
                }
            }
            
        }
                
        return numEntries;
    }
    else {
        return [[[self playlist] songs] count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([sortKeyName isEqualToString:@"artist"] || [sortKeyName isEqualToString:@"title"]) {
		//[self determineSongIndexLettersPresent];
        return [[self lettersPresent] objectAtIndex:section];
    }
    else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
		[cell setBackgroundColor:[UIColor clearColor]];
		
		UIView* selectionBackgroundView = [[[UIView alloc] init] autorelease];
		selectionBackgroundView.backgroundColor = [UIColor colorWithWhite: .5 alpha: .25];
		cell.selectedBackgroundView = selectionBackgroundView;
		
    }
    
    Song *song = [self songForRowAtIndexPath:indexPath];
    
    // append the index to the title if this songs title is not unique
    NSString *originalSongTitle  = [song title];
    
    // define the range you're interested in
    NSRange stringRange = {0, MIN([originalSongTitle length], 15)};
    // adjust the range to include dependent chars
    stringRange = [originalSongTitle rangeOfComposedCharacterSequencesForRange:stringRange];
    // Now you can create the short string
    NSMutableString *completeSongTitle;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && stringRange.length == 15) {
        completeSongTitle = [[originalSongTitle substringWithRange:stringRange] mutableCopy];
        [completeSongTitle appendString:@"…"];
    }
    else {
        completeSongTitle = [originalSongTitle mutableCopy];
    }
    
    // get the songs key signature
    
    NSString *keySignatureXmlOpenTag = @"<keysignature>";
    NSString *keySignatureXmlCloseTag = @"</keysignature>";
    
    NSRange openTagRange = [[song content] rangeOfString:keySignatureXmlOpenTag];
    NSRange closeTagRange = [[song content] rangeOfString:keySignatureXmlCloseTag];
    
    unsigned long start = openTagRange.location + openTagRange.length;
    unsigned long finish = closeTagRange.location;
    long length = finish - start;
    
    NSRange keySignatureRange = NSMakeRange(start, length);
    
    NSString *keySignatureString;
	
	
	if (start != NSNotFound) {
		keySignatureString = [[song content] substringWithRange:keySignatureRange];
		keySignatureString = [keySignatureString stringByReplacingOccurrencesOfString:@"-" withString:@"m"];
		
		[completeSongTitle appendString:[NSString stringWithFormat:@" · %@", keySignatureString]];
		
	}
	
    //NSLog(@"%@", keySignatureString);
	
    /*
    if ([[song nonUniqueTitleIndex] intValue] > 0) {
        [completeSongTitle appendString:[NSString stringWithFormat:@" (%d)", [[song nonUniqueTitleIndex] intValue]]];
    }*/
    
    // set text and detailtext of this cell depending on sorting mode
    if ([sortKeyName isEqualToString:@"artist"]) {
        if ([[song selfComposed] boolValue]) {
            if ([[song cover] boolValue]) {
                [[cell textLabel] setText:[NSString stringWithFormat:@"★✎ %@", [song artist]]];
            }
            else {
                [[cell textLabel] setText:[NSString stringWithFormat:@"★ %@", [song artist]]];
            }
        }
        else if ([[song cover] boolValue]) {
            [[cell textLabel] setText:[NSString stringWithFormat:@"✎ %@", [song artist]]];
        }
        else {
            [[cell textLabel] setText:[song artist]];
        }
        
        [[cell detailTextLabel] setText:completeSongTitle];
    }
    else {
        if ([[song selfComposed] boolValue]) {
            if ([[song cover] boolValue]) {
                [[cell textLabel] setText:[NSString stringWithFormat:@"★✎ %@", completeSongTitle]];
            }
            else {
                [[cell textLabel] setText:[NSString stringWithFormat:@"★ %@", completeSongTitle]];
            }
        }
        else if ([[song cover] boolValue]) {
            [[cell textLabel] setText:[NSString stringWithFormat:@"✎ %@", completeSongTitle]];
        }
        else {
            [[cell textLabel] setText:completeSongTitle];
        }
        
       [[cell detailTextLabel] setText:[song artist]];
		
    }
    
    BOOL lightsOut = [(AppDelegate *)[[UIApplication sharedApplication] delegate] isLightsOutModeEnabled];
    
    if (!lightsOut) {
        [[cell textLabel] setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
        [[cell detailTextLabel] setTextColor:[UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1]];
    }
    else {
        [[cell textLabel] setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [[cell detailTextLabel] setTextColor:[UIColor colorWithRed:.4f green:.4f blue:.4f alpha:1]];
    }
    
    [cellIdentifier release];
    [completeSongTitle release];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we cant move songs in the library (no custom sorting mode there)
    if ([[playlist name] isEqualToString:@"Library"])
    {
        return NO;
    }
    
    // we cant move songs when not in custom sorting mode
    if (![sortKeyName isEqualToString:@"custom"]) {
        return NO;
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [[appDelegate database] managedObjectContext];
        
        if ([[[self playlist] createdBySystem] boolValue]) {
            Song *song = [[self songIndexForRowAtIndexPath:indexPath] song];
            [context deleteObject:song];
        }
        else {
            SongIndex *songIndex = [self songIndexForRowAtIndexPath:indexPath];
            [context deleteObject:songIndex];
        }
        
        NSError *error;
        [context save:&error];
    }
        
    [tableView reloadData];
}

/**
 * Moves songs in "custom" sorting mode (and only there) by changing member [SortIndex index].
 * If you want to sort ouside of "custom", you have to rewrite/extend this method.
 */
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [[appDelegate database] managedObjectContext];
    
    // we save a pointer to the index of the song we want to move
    SongIndex *movedSongIndex = [self songIndexForRowAtIndexPath:fromIndexPath];
    
    // adjust the indices of the other songs (song between old and new slot are falling down or raising up
    for (id object in self.playlist.songs) {
        SongIndex *songIndex = (SongIndex *)object;
        
        if ([fromIndexPath row] < [toIndexPath row]) {
            if ([[songIndex index] intValue] >= ([fromIndexPath row] + 1) && [[songIndex index] intValue] <= [toIndexPath row]) {
                [songIndex setIndex:[NSNumber numberWithInt:([[songIndex index] intValue] - 1)]];
            }
        }
        else {
            if ([[songIndex index] intValue] >= [toIndexPath row] &&[[songIndex index] intValue] <= ([fromIndexPath row] - 1)) {
                [songIndex setIndex:[NSNumber numberWithInt:([[songIndex index] intValue] + 1)]];
            }
        }
    }
    
    // finally set the index of the song to be moved to the new value
    [movedSongIndex setIndex:[NSNumber numberWithInt: (int) [toIndexPath row]]];
    
    NSError *error;
    [context save:&error];
    
    [tableView reloadData];
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *song =[self songForRowAtIndexPath:indexPath];
    
    Database *db = [self playlistDataSource];
    Playlist *list = [self playlist];
    NSString *sortKey = [self sortKeyName];
    
    SheetSetterViewController *newSheetController = [[SheetSetterViewController alloc] initWithDataSource:db playlist:list sortKey:sortKey song:song];
    
    [self setSheetController:newSheetController];
    [self.navigationController pushViewController:newSheetController animated:YES];
    [newSheetController release];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
    if (isLightsOut && [view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
		
		// tableViewHeaderFooterView.backgroundView.backgroundColor = [UIColor colorWithWhite: .25 alpha: 1.];
		tableViewHeaderFooterView.textLabel.textColor = [UIColor colorWithWhite: .75 alpha: 1.];
		
    }
	
}

- (void)reactToLightsOutModeChange
{
	
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
	UINavigationBar* navigationBar = self.navigationController.navigationBar;
	
    if (isLightsOut) {
		
        table.backgroundColor = [UIColor colorWithWhite: .05f alpha: 1];
        table.separatorColor = [UIColor colorWithWhite: .5 alpha: 1];
		
		table.sectionIndexColor = navigationBar.tintColor;
		table.sectionIndexBackgroundColor = table.backgroundColor;
		table.sectionIndexTrackingBackgroundColor = appDelegate.barTintColor;
		
		table.indicatorStyle = UIScrollViewIndicatorStyleWhite;
		
	} else {
        table.backgroundColor = [UIColor colorWithWhite: 1 alpha: 1];
        table.separatorColor = [UIColor colorWithWhite: .5 alpha: .5];
		
		table.sectionIndexColor = [UIColor colorWithWhite: .5f alpha: 1];
		table.sectionIndexBackgroundColor = nil;
		table.sectionIndexTrackingBackgroundColor = nil;
		
		table.indicatorStyle = UIScrollViewIndicatorStyleBlack;
		
    }
	
	_toolbar.barTintColor = navigationBar.barTintColor;
	_toolbar.tintColor = navigationBar.tintColor;
	
}

-(void)reloadTable:(NSNotification *)notification
{
    [[self table] reloadData];
}

#pragma mark - Delegate method for modally displayed AddSongsViewController

- (void) doneButtonPressed:(AddSongsViewController *)addSongsViewController
{
    [[self table] reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Delegate method for modally displayed ShareSongsViewController

/**
 * Removes the ShareSongsViewController from screen, which in turn triggers shareControllerDisappeared later on.
 */
- (void) removeShareController:(ShareSongsViewController *)shareSongsViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 * This method is neccessary since without it, the two modal view controllers (ShareSongs and MailCompose) would collide
 * in their animations and MailCompose wouldnt be shown.
 */
- (void) shareControllerDisappeared:(ShareSongsViewController *)shareSongsViewController
{
	shareSongsViewController.delegate = nil;
	
    if (![shareSongsViewController wasConfirmed])
        return;
	
	BOOL isSongSelected = NO;
	
    NSSet* songIndices = shareSongsViewController.playlist.songs;
	for (SongIndex* songIndex in songIndices.objectEnumerator) {
		if (songIndex.song.isSelected) {
			isSongSelected = YES;
			break;
			
		}
		
	}
	if (!isSongSelected)
		return;
	
	
	BOOL canSendMail = [MFMailComposeViewController canSendMail];
	
	if (canSendMail) {

		UIAlertController* myMenu =
			[UIAlertController alertControllerWithTitle: @"Share via …"
				message: @""
				preferredStyle: UIAlertControllerStyleActionSheet
				
			];
		
		[myMenu addAction:
			[UIAlertAction
				actionWithTitle: @"Email"
				style: UIAlertActionStyleDefault
				handler: ^(UIAlertAction * _Nonnull action) {
					MFMailComposeViewController *newController = [[MFMailComposeViewController alloc] init];
					[[newController navigationBar] setTintColor:[UIColor blackColor]];
					[newController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
					[newController setSubject:@"New sheet for Chord Sheets"];
					
					for (SongIndex *tempSongIndex in [[self playlist] songs]) {
						Song *tempSong = [tempSongIndex song];
						
						if ([tempSong isSelected]) {
							[newController addAttachmentData:[[tempSong content] dataUsingEncoding:NSUTF8StringEncoding]
													mimeType:@"application/idealbook"
													fileName:[tempSong createExportFileName]];
						}
					}
					
					[newController setToRecipients:[NSArray array]];
					[newController setMessageBody:@"Check out this song sheet! You’ll need the Chord Sheets app to view this file." isHTML:NO];
					[newController setMailComposeDelegate:self];
					
					[self presentViewController:newController animated:YES completion:nil];
					[newController release];
					
				}
				
			]
			
		];
		[myMenu addAction:
			[UIAlertAction
				actionWithTitle: @"Bluetooth"
				style: UIAlertActionStyleDefault
				handler: ^(UIAlertAction * _Nonnull action) {
					[self presentMCBrowserController];
					
				}
				
			]
			
		];
		
		[myMenu addAction:
			[UIAlertAction
				actionWithTitle: @"Cancel"
				style: UIAlertActionStyleCancel
				handler: ^(UIAlertAction * _Nonnull action) {
					
				}
				
			]
			
		];
		
		UIView* sourceView = self.navigationController.view;
		
		myMenu.popoverPresentationController.sourceView = sourceView;
		myMenu.popoverPresentationController.sourceRect = CGRectMake (
			sourceView.bounds.size.width - 116,
			sourceView.bounds.size.height - 44,
			65,
			44 / 2 // sourceView.bounds.size.height
			
		);
		
		[self presentViewController: myMenu animated: YES completion: nil];
		
		
	} else {
		[self presentMCBrowserController];
		
	}
	
}

#pragma mark - MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MCBrowserViewControllerDelegate

- (void) presentMCBrowserController {
	MCPeerID* peerId = [[MCPeerID alloc] initWithDisplayName: @"Chord Sheets Sender"];
	MCSession* session = [[MCSession alloc] initWithPeer: peerId];
	session.delegate = self;
	
	MCAdvertiserAssistant *assistant =[[MCAdvertiserAssistant alloc] initWithServiceType:@"idb-share"
		discoveryInfo:nil
		session:session];
	
	[assistant start];
	
	MCBrowserViewController* browserViewController = [[MCBrowserViewController alloc] initWithServiceType: @"idb-share" session: session];
	browserViewController.delegate = self;
	
	[self presentViewController: browserViewController animated: YES completion: ^{
		
	}];
	
	self.currentBrowserViewController = browserViewController;
	self.currentAssistant = assistant;
	
	[assistant release];
	[browserViewController release];
	[session release];
	[peerId release];

}

- (void) dismissMCBrowserController {
	[self.currentAssistant stop];
	self.currentAssistant = nil;
	
	[self.currentBrowserViewController.session disconnect];
	
	[self.currentBrowserViewController dismissViewControllerAnimated: YES completion: ^{
		
	}];
	self.currentBrowserViewController.delegate = nil;
	self.currentBrowserViewController = nil;
	
}

- (void) browserViewControllerDidFinish: (MCBrowserViewController*) browserViewController {
	[self dismissMCBrowserController];
	
}

- (void) browserViewControllerWasCancelled: (MCBrowserViewController*) browserViewController {
	[self dismissMCBrowserController];
	
}

- (void) session: (MCSession*) session didReceiveData: (NSData*) data fromPeer:(MCPeerID*) peerID {

}

- (void) session: (MCSession*) session didStartReceivingResourceWithName: (NSString*) resourceName fromPeer: (MCPeerID*) peerID withProgress: (NSProgress*) progress {

}

- (void) session: (MCSession*) session didFinishReceivingResourceWithName:(NSString*) resourceName fromPeer: (MCPeerID*) peerID atURL: (NSURL*) localURL withError: (NSError*) error {

}

- (void) session: (MCSession*) session didReceiveStream: (NSInputStream*) stream withName: (NSString*) streamName fromPeer: (MCPeerID*) peerID {

}

- (void) session: (MCSession*) session peer: (MCPeerID*) peerID didChangeState: (MCSessionState) state {
	NSError *error;
	
    switch (state) {
        case MCSessionStateConnected:
			for (SongIndex *tempSongIndex in [[self playlist] songs]) {
				Song *tempSong = [tempSongIndex song];
				
				if ([tempSong isSelected]) {
					NSData* data = [[tempSong content] dataUsingEncoding: NSUTF8StringEncoding];
					
					if (![session sendData:data toPeers: @[peerID] withMode: MCSessionSendDataReliable error: &error]) {
						NSLog(@"Could not send message due to %@, %@", error, [error userInfo]);
						
					}
					
				}
				
			}
			
			[self dismissMCBrowserController];
			session.delegate = nil;
			
			break;
            
        default:
			
			break;
			
		
    }
}

@end
