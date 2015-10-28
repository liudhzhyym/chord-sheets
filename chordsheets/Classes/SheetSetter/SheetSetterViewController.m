//
//  SheetSetterViewController.m
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 07.06.10.
//  Copyright wysiwyg* software design gmbh 2010. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "SheetSetterViewController.h"
#import "SheetScrollView.h"
#import "KeyViewController.h"
#import "PlayBackViewController.h"

#import "Song.h"
#import "SongIndex.h"
#import "Playlist.h"
#import "AttributedChord.h"
#import "Key.h"
#import "KeySignature.h"
#import "Chord.h"
#import "OpeningBarLine.h"
#import "ClosingBarLine.h"
#import "AppDelegate.h"

#import "TextModel.h"



@interface SheetSetterViewController (Private)

- (void)initSheetScrollViewWithSheet:(Sheet *)newSheet;
- (void)showInserBarActionSheet;

@end


@implementation SheetSetterViewController

@synthesize playlist;
@synthesize sortKeyName;
@synthesize song;
@synthesize sheet;
@synthesize sheetBeforeEditing;
@synthesize isEditingNewSong;

@synthesize keyController;
@synthesize playBackController;
@synthesize sheetScrollView;
@synthesize database;
@synthesize BPMBeforeEditing;
@synthesize BPMAfterEditing;

BOOL optimizeLayout = YES;

- (id)initWithDataSource:(Database *)newDataSource playlist:(Playlist *)newPlaylist sortKey:(NSString *)newSortKey song:(Song *)newSong
{
    if (self = [super init]) {
        [self setDatabase:newDataSource];
        [self setPlaylist:newPlaylist];
        [self setSortKeyName:newSortKey];
        [self setSong:newSong];
    }
    
    return self;
}

- (void)releaseReferences
{
	self.playlist = nil;
	self.song = nil;
	
	self.sheet = nil;
	self.sheetBeforeEditing = nil;
	
	[sheetScrollView release];
	
	[self closeKeyController];
	[self closePlaybackController];
	
	[database release];
}

- (void)dealloc
{
	[self releaseReferences];
    [super dealloc];
}

- (NSString*) currentColorScheme
{
    BOOL lightsOut = [(AppDelegate *)[[UIApplication sharedApplication] delegate] isLightsOutModeEnabled];
    return lightsOut ? SHEET_COLOR_SCHEME_NEGATIVE : SHEET_COLOR_SCHEME_POSITIVE;
	
};

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.navigationItem.title = [[self song] title];
	
    
    [self initSheetScrollViewWithSheet:[self sheet]];

    [self openPlaybackController];
	[self updateScrollViewBoundsForClosedKeyController];
	
	
	UIBarButtonItem* transposeButton = playBackController.transposeButton;
	[transposeButton setTarget: self];
	[transposeButton setAction: @selector(transposeSheet:)];
	[transposeButton setTitle: [[[sheetScrollView sheetView] firstKeySignature] displayStringValue]];
	
	UIBarButtonItem* actionButton = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem: UIBarButtonSystemItemAction
		target: self
		action: @selector(presentExportMenu:)
		
	];
    self.navigationItem.rightBarButtonItem = actionButton;
	[actionButton release];
	
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
	[self reactToLightsOutModeChange];
	
}

- (void)reactToLightsOutModeChange
{
	
	UIToolbar* toolbar = playBackController.toolbar;
	UINavigationBar* navigationBar = self.navigationController.navigationBar;
	
	toolbar.barTintColor = navigationBar.barTintColor;
	toolbar.tintColor = navigationBar.tintColor;
	
	BOOL isLightsOut = [(AppDelegate *)[[UIApplication sharedApplication] delegate] isLightsOutModeEnabled];
	
	UISlider* bpmSlider = playBackController.bpmSlider;
	bpmSlider.thumbTintColor = isLightsOut ? [UIColor colorWithWhite: .5  alpha: 1.] : nil;
	
}


-(UIStatusBarStyle) preferredStatusBarStyle {
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
	return isLightsOut ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
	
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveSongIfEdited];
	
}

- (void)setSong:(Song *)newSong
{
	
	if (self->song == newSong)
		return;
	
    self->song = [newSong retain];
    
    ParserContext *parserContext;
    
    if ([[newSong content] length] > 0) {
        parserContext = [[ParserContext alloc] initWithString: [newSong content]];
    } else {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"New Song - Unknown Artist" ofType:@"xml"];
        parserContext = [[ParserContext alloc] initWithDocumentPath: filePath];
    }
    
    Sheet *newSheet = [[Sheet alloc] init];
    [newSheet registerWithParserContext: parserContext];
    [parserContext parse];
    [parserContext release];
    [self setSheet:newSheet];
    [self setBPMBeforeEditing:[[self sheet] tempo]];
    [newSheet release];
    
    [[self sheet] setArtist: [[self song] artist]];
    
    if ([[self song] author]) {
        [[self sheet] setCopyright: [[self song] author]];
    }
    
    Sheet *sheetBefore = [sheet copy];
    [self setSheetBeforeEditing:sheetBefore];
    [sheetBefore release];
}

- (void) setUpSheetView {
    SheetView* sheetView = [sheetScrollView sheetView];

    [sheetView setOpaque:YES];
    [sheetView setEditingDelegate:self];
	

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [sheetView setScale: MIN (1.25f, [sheetView fullContentScale])];
        [[sheetView sheetLayer] updateLayout];
		
    } else {
        [sheetView zoomToFullContent];
		
    }
    
    sheetScrollView.sheetLayer.cursor -> persistentParent = [[self view] layer];
	
}

- (void)initSheetScrollViewWithSheet:(Sheet *)newSheet
{
    SheetScrollView *newScrollView = [[SheetScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	newScrollView->needsCenteringOnLayout=YES;
    [newScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self setSheetScrollView:newScrollView];
    [[self view] addSubview:sheetScrollView];
	
    [newScrollView release];
    
    [sheetScrollView setOpaque:YES];
    [sheetScrollView setColorScheme: [self currentColorScheme]];
    
    // add the sheet to the view
    [sheetScrollView setSheet:[self sheet]];
	
	[self setUpSheetView];
    // [sheetScrollView centerContentAnimated: NO];
	
    // get the songs index for swipe limit enforcement
    int currentSongIndex = 0;
    
    NSArray *songArray;
    
    if ([sortKeyName isEqualToString:@"custom"]) {
        songArray = [[self playlist] getSongsSortedByAttribute:@"index" ascending:YES];
    }
    else {
        songArray = [[self playlist] getSongsSortedByAttribute:[self sortKeyName] ascending:YES];
    }
    
    for (Song *tempSong in songArray) {
        if ([tempSong artist] == [[self song] artist] && [tempSong title] == [[self song] title]) {
            break;
        }
        else {
            currentSongIndex++;
        }
    }

    //set the swipe limit
	
    [self sheetScrollView] -> canLeaveToLeft = !isEditingNewSong && currentSongIndex < ([songArray count] - 1);
	[self sheetScrollView] -> canLeaveToRight = !isEditingNewSong && currentSongIndex > 0;
	
}

#pragma mark - Rotation

- (void) viewWillTransitionToSize: (CGSize) size withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>) coordinator {
	UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	[sheetScrollView updateBackgroundForOrientation: (UIInterfaceOrientation) deviceOrientation];
	
	SheetView* sheetView = [sheetScrollView sheetView];
    
	if (sheetView.isEditing) {
		[sheetScrollView setKeyboardSpace: 0];
		[sheetView setEditingLayer: nil andCollapse: NO];
		
	}
	
	if (keyController) {
		[self closeKeyController];
		
	}
	
	[sheetView presentStaticLayer];
	// [sheetScrollView expandInset];
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[sheetScrollView updateContentSize];
		[sheetScrollView centerContentAnimated: NO];
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[sheetScrollView updateContentSize];
		[sheetScrollView centerContentAnimated: YES];
		
		[sheetScrollView.sheetView presentDynamicLayer];
		
	}];
	
	[super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
	
}

#pragma mark - Writing edited songs back to the DB

- (void)saveSongIfEdited
{
    // store bpm value away and temporarily restore value in order to keep it from influencing the edited check
    [self setBPMAfterEditing:[[self sheet] tempo]];
    [[self sheet] setTempo:[self BPMBeforeEditing]];
	
	Sheet* currentSheet = [sheetScrollView sheet];
    
    NSString *sheetBeforeEditingXML = [[self sheetBeforeEditing] toXMLString];
    NSString *sheetAfterEditingXML = [currentSheet toXMLString];
    
    BOOL wasEdited = ![sheetBeforeEditingXML isEqualToString:sheetAfterEditingXML];
    
    // set the bpm value back to the one selected by the user
    [[self sheet] setTempo:[self BPMAfterEditing]];
    
    if (wasEdited) {
        // save the song itself since it is a modified prototype
        if ([[self song] isCompositionPrototype]) {
            [self saveSelfComposedSong];
        }
        // save a new copy since this is an already existing song that was modified
        else {
            [self saveSongAsCopy];
        }
    }
    else {
        // if the song is a prototype that was not modified, we need to delete it
        if ([[self song] isCompositionPrototype]) {
            [[[self database] managedObjectContext] deleteObject:[self song]];
            [[self database] saveContext];
        }
    }
}

-(void) saveSelfComposedSong
{
    [[self song] setValue:[[self database] determineNonUniqueIndexForSong:[self song]] forKey:@"nonUniqueTitleIndex"];
    
    [[self song] setValue:[[self sheet] title] forKey:@"title"];
    [[self song] setValue:[[self sheet] artist] forKey:@"artist"];
    [[self song] setValue:[[self sheet] toXMLString] forKey:@"content"];
    [[self song] setValue:[[self sheetBeforeEditing] title] forKey:@"originalTitle"];
    [[self song] setValue:[[self sheetBeforeEditing] artist] forKey:@"originalArtist"];
    [[self song] setValue:[NSNumber numberWithBool:NO] forKey:@"cover"];
    [[self song] setValue:[NSNumber numberWithBool:YES] forKey:@"selfComposed"];
    
    // remove the prototype flag, since its becoming a selfcomposed song now
    [[self song] setCompositionPrototype:NO];
    
    [[self database] saveContext];
}

-(void) saveSongAsCopy
{
    NSManagedObjectContext *objectContext = [[self database] managedObjectContext];
        
    Song *newSong = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:objectContext];
    [newSong setValue:[[self sheet] title] forKey:@"title"];
    [newSong setValue:[[self sheet] artist] forKey:@"artist"];
    [newSong setValue:[[self sheet] toXMLString] forKey:@"content"];
    [newSong setValue:[[self sheetBeforeEditing] title] forKey:@"originalTitle"];
    [newSong setValue:[[self sheetBeforeEditing] artist] forKey:@"originalArtist"];
    [newSong setValue:[[self database] determineNonUniqueIndexForSong:newSong] forKey:@"nonUniqueTitleIndex"];
    [newSong setValue:[NSNumber numberWithBool:YES] forKey:@"cover"];
    [newSong setValue:[[self song] selfComposed] forKey:@"selfComposed"];
    
    SongIndex *librarySongIndex = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:objectContext];
    [librarySongIndex setValue:[NSNumber numberWithInt: (int) [[[[self database] library] songs] count]] forKey:@"index"];
    [librarySongIndex setSong:newSong];
    [librarySongIndex setPlaylist:[[self database] library]];
    [[[self database] library] addSongsObject:librarySongIndex];
    
    SongIndex *editedSongIndex = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:objectContext];
    [editedSongIndex setValue:[NSNumber numberWithInt: (int) [[[[self database] edited] songs] count]] forKey:@"index"];
    [editedSongIndex setSong:newSong];
    [editedSongIndex setPlaylist: [[self database] edited]];
    [[[self database] edited] addSongsObject:editedSongIndex];
    
    if ([[newSong selfComposed] boolValue]) {
        SongIndex *newSongIndex = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:objectContext];
        [newSongIndex setValue:[NSNumber numberWithInt: (int) [[[self playlist] songs] count]] forKey:@"index"];
        [newSongIndex setSong:newSong];
        [newSongIndex setPlaylist: [[self database] mySongs]];
        [[[self database] mySongs] addSongsObject:newSongIndex];
    }
    
    // if this sheetsetter was invoked from a custom playlist, we need to add the new copy to that playlist
    if (![[[self playlist] createdBySystem] boolValue]) {
        SongIndex *newSongIndex = [NSEntityDescription insertNewObjectForEntityForName:@"SongIndex" inManagedObjectContext:objectContext];
        [newSongIndex setValue:[NSNumber numberWithInt: (int) [[[self playlist] songs] count]] forKey:@"index"];
        [newSongIndex setSong:newSong];
        [newSongIndex setPlaylist: [self playlist]];
        [playlist addSongsObject:newSongIndex];
    }
    
    [[self database] saveContext];
}

#pragma mark - KeyViewController insertion and removal methods

- (void) openKeyControllerWithKeySet:(NSString *)keySetName element:(id)element sheetView:(SheetView *)sheetview
{
    // abort if the requested KeyViewController is already open
    if ([self keyController]) {
        if ([[[self keyController] keysetName] isEqualToString:keySetName]) {
            return;
        }
    }
    
    // close obsolete KeyViewController instance
    [self closeKeyController];
    
    // open the new KeyViewController
    
    KeyViewController *keyViewController = [[KeyViewController alloc] initWithKeyConfig:keySetName sheetSetterViewController:self];
    
    // move the KeyViewController to the bottom of the screen
    CGFloat x = 0;
    CGFloat y = (self.view.frame.size.height - keyViewController.view.frame.size.height);
    CGFloat width = keyViewController.view.frame.size.width;
    CGFloat height = keyViewController.view.frame.size.height;
    
    [[keyViewController view] setFrame:CGRectMake(x, y, width, height)];
    
    [[keyViewController view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    [[self view] addSubview:[keyViewController view]];
    [self setKeyController:keyViewController];
	[self updateScrollViewBoundsForOpenKeyController: keyViewController];
    [keyViewController release];
    
	/*
    int sheetContainerViewHeight = (self.view.frame.size.height - [[[self keyController] view] frame].size.height);
    [sheetScrollView setFrame:CGRectMake(0, 0, self.view.frame.size.width, sheetContainerViewHeight)];
	*/
	
}

- (void) closeKeyController
{
	if (!playBackController.transposeButton.enabled)
		playBackController.transposeButton.enabled = YES;
	
    if (keyController == nil)
        return;
    
    [keyController.view removeFromSuperview];
    self.keyController = nil;
    
	[self updateScrollViewBoundsForClosedKeyController];
	

}

- (void) updateScrollViewBoundsForOpenKeyController: (KeyViewController*) keyViewController {
	extern float bottomBarHeight;
	bottomBarHeight = (float) keyViewController.view.frame.size.height;
	
	[sheetScrollView setNeedsLayout];
	
}

- (void) updateScrollViewBoundsForClosedKeyController {
	extern float bottomBarHeight;
	bottomBarHeight = playBackController == nil ?
		0 : (float) playBackController.view.frame.size.height;;
	
	[sheetScrollView setNeedsLayout];
	
}

- (BOOL) isShowingKeys {
	return keyController != nil;
	
}

#pragma mark - PlayBackViewController insertion and removal methods

- (void) openPlaybackController
{
    // abort if the requested PlayBackViewController is already open
    if ([self playBackController]) {
        return;
    }
    
    PlayBackViewController *playController = [[PlayBackViewController alloc]initWithSheet:[self sheet] sheetView:[sheetScrollView sheetView]];
    
    CGFloat x = 0;
    CGFloat y = (self.view.frame.size.height - playController.view.frame.size.height);
    CGFloat playbackWidth = self.view.frame.size.width;
    CGFloat playbackHeight = playController.view.frame.size.height;
    
    playController.view.frame = CGRectMake(x, y, playbackWidth, playbackHeight);
    [[playController view] setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth)];
    
    [[self view] addSubview:[playController view]];
    [self setPlayBackController:playController];
    [playController release];
    
    [playController changeBPM:[[self sheet] tempo]];
	[playController updateSlider];
	
}

- (void) closePlaybackController
{
    if (![self playBackController]) {
        return;
    }
    
    [[[self playBackController] view] removeFromSuperview];
	
    [self setPlayBackController:nil];
    
}

#pragma mark - Button and Key dispatcher methods

- (IBAction)buttonTapped:(id)sender
{    
    SheetView *sheetView = [sheetScrollView sheetView];
	id currentElement = [sheetView currentElement];
	int buttonTag = (int) [(UIButton *) sender tag];
    
	switch (buttonTag) {
        case 0:
        {
            if ([[[self keyController] keysetName] isEqualToString:@"AttributedChordOptions"] || [[[self keyController] keysetName] isEqualToString:@"AttributedChordOptions.ipad"]) {
                SheetView* sheetView = [sheetScrollView sheetView];
                id currentElement = sheetView.currentElement;
                
                if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    [self openKeyControllerWithKeySet:@"AttributedChord.ipad" element:currentElement sheetView:sheetView];
                }
                else {
                    [self openKeyControllerWithKeySet:@"AttributedChord" element:currentElement sheetView:sheetView];
                }
                
                [[self keyController] syncKeysWithChord:currentElement];
            }
            else {
				[sheetView enterAnnotationEditingMode];
           }
			
        }   break;
            
        case 1:
        {
            if ([currentElement class] == [OpeningBarLine class] || [currentElement class] == [ClosingBarLine class]) {
                [self showInserBarActionSheet];
            }
            else {
                SheetView* sheetView = [sheetScrollView sheetView];
                id currentElement = sheetView.currentElement;
                
                if ([currentElement isKindOfClass: [Chord class]]) {
                    [[self keyController] syncElement:currentElement withButtonWithTag:buttonTag];
                    [sheetView commitChangeToCurrentElement];
                }
            }
        }   break;
            
        case 2:
        {            
            if ([sheetView isFirstElement:sheetView.currentElement]) return;
            [sheetView goBack];
        }   break;
            
        case 3:
        {            
            [sheetView goForward];
        }   break;
            
        default:
            break;
    }
}

- (IBAction)keyTapped:(id)sender
{ 
	// KeyViewController* keyController = [self keyController];
	NSString* keysetName = [keyController keysetName];
	
    SheetView* sheetView = [sheetScrollView sheetView];
	id currentElement = [sheetView currentElement];
	
	if (([keysetName isEqualToString:@"AttributedChord"] || [keysetName isEqualToString:@"AttributedChord.ipad"])&&
		[currentElement class] == [AttributedChord class]) {
        
        if ([(KeyButton *)sender tag] == 16) {
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [self openKeyControllerWithKeySet:@"AttributedChordOptions.ipad" element:currentElement sheetView:sheetView];
            }
            else {
                [self openKeyControllerWithKeySet:@"AttributedChordOptions" element:currentElement sheetView:sheetView];
            }
            
			[keyController syncKeysWithChordOptions: currentElement];
            return;
        }
        
		[keyController enforceChordRulesForKeyInput: (int) [(UIButton *) sender tag]];
		
		[keyController applyChordKeyPress: sender toChord: currentElement];
		
        [sheetView commitChangeToCurrentElement];
        [keyController syncKeysWithChord:currentElement];
		
		[sheetView playChord: currentElement];
		
	} else if (([keysetName isEqualToString: @"AttributedChordOptions"] || [keysetName isEqualToString: @"AttributedChordOptions.ipad"]) &&
		[currentElement class] == [AttributedChord class]) {
		[keyController enforceChordRulesForKeyInput: (int) [(UIButton *) sender tag]];
		[keyController applyChordOptionsKeyPress: sender toChord: currentElement];
		
        [sheetView commitChangeToCurrentElement];
        [keyController syncKeysWithChordOptions: currentElement];
		
		[sheetView playChord: currentElement];
		
	} else if ([keysetName isEqualToString:@"KeySignature"] || [keysetName isEqualToString:@"KeySignature.ipad"]) {
        if ([(KeyButton *)sender tag] == 10) {
            [self showTransposeConfirmation];
			
        } else {
            [keyController enforceKeySignatureRulesForKeyInput: (int) [(UIButton *) sender tag]];
			[keyController applyKeySignatureKeyPress: sender toKeySignature: keyController.keySignature];
			[keyController syncKeysWithKeySignature: [keyController keySignature]];
        }
		
    } else if (([keysetName isEqualToString:@"TimeSignature"] || [keysetName isEqualToString:@"TimeSignature.ipad"])&&
		[currentElement class] == [TimeSignature class]) {
        
        // remove the time signature if the time value was deselected and its not the first time signature of the sheet (which is mandatory)
        if ([sender isSelected] && ![sheetView isOnFirstBar]) {
            //NSLog(@"deactivation");
            
            [sheetView toggleCurrentTimeSignature: NO];
            [sheetView commitChangeToCurrentElement];
            [sheetView goForward];
            
            // update current element after the old one was deleted
            currentElement = sheetView.currentElement;
            
            NSString *newKeySetName = @"OpeningBarLine";
            
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                newKeySetName = @"OpeningBarLine.ipad";
            }
            
            // open keyView for opening bar line since this will be the current element after deletion
            [self openKeyControllerWithKeySet:newKeySetName element:currentElement sheetView:sheetView];
        }
        else {
            [keyController enforceTimeSignatureRulesForKeyInput: (int) [(UIButton *) sender tag]];
            [keyController applyTimeSignatureKeyPress:sender toTimeSignature:currentElement];
            [sheetView commitChangeToCurrentElement];
            [keyController syncKeysWithTimeSignature:currentElement];
        }
	} else if (([keysetName isEqualToString:@"OpeningBarLine"] || [keysetName isEqualToString:@"OpeningBarLine.ipad"]) &&
		[currentElement class] == [OpeningBarLine class]) {
        [keyController enforceOpeningBarLineRulesForKeyInput: (int) [(UIButton *) sender tag]];
        [keyController applyBarKeyPress: sender toOpeningBarLine: currentElement];
		
		if ([(UIButton*) sender tag] != 12) {
			[sheetView commitChangeToCurrentElement];
			[keyController syncKeysWithOpeningBarLine:currentElement];
		}
		
	} else if (([keysetName isEqualToString:@"ClosingBarLine"] || [keysetName isEqualToString:@"ClosingBarLine.ipad"]) &&
		[currentElement class] == [ClosingBarLine class]) {
        [keyController enforceClosingBarLineRulesForKeyInput: (int) [(UIButton *) sender tag]];
        [keyController applyBarKeyPress: sender toClosingBarLine: currentElement];
        [sheetView commitChangeToCurrentElement];
		
		// [sheetView.sheetLayer updateLayout];
		
        [keyController syncKeysWithClosingBarLine:currentElement];
		
	} else {
		NSLog (@"no meaningful action found. keyset name is %@, current element is %@", keysetName, currentElement);
	}
}

#pragma mark - Methods for transpose sheet

- (void) leaveTransposeDialog
{
	[self closeKeyController];
	[sheetScrollView centerContentAnimated: YES];
	
	extern float navigationBarHeight;
	extern float bottomBarHeight;
	sheetScrollView.scrollIndicatorInsets = UIEdgeInsetsMake (navigationBarHeight, 0, bottomBarHeight, 0);
	
}

- (IBAction)transposeSheet:(id)sender
{
    NSMutableString *keysignatureString = [NSMutableString stringWithString:@"KeySignature"];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [keysignatureString appendString:@".ipad"];
    }
    
	SheetView* sheetView = [sheetScrollView sheetView];
	if (sheetView.isEditing && [sheetView.currentElement isKindOfClass: [TextModel class]]) // don't mess in text input mode
		return;
	
	if ([[[self keyController] keysetName] isEqualToString: keysignatureString]) {
		[self leaveTransposeDialog];
		
	} else {
		[self openKeyControllerWithKeySet:keysignatureString element:nil sheetView:[sheetScrollView sheetView]];
		
		KeySignature* keySignature = [[sheetScrollView sheetView] firstKeySignature];
		keyController.keySignature = keySignature;
		keyController.keySignatureBeforeEditing = keySignature;
		
		[keyController syncKeysWithKeySignature: keyController.keySignature];
		
		[sheetView presentCursor: NO];
		
		extern float navigationBarHeight;
		extern float bottomBarHeight;
		
		CGRect bounds = sheetScrollView.bounds;
		CGSize contentSize = sheetScrollView -> originalContentSize;
		
		sheetScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(navigationBarHeight, 0, bottomBarHeight, 0);
		[sheetScrollView centerContentAnimated: YES clampToZero: contentSize.height > bounds.size.height - bottomBarHeight - navigationBarHeight];
		[sheetScrollView setNeedsLayout];
		
	}
}

- (void) showTransposeConfirmation
{
	NSString* originalKeySignatureString = keyController.keySignatureBeforeEditing.displayStringValue;
	NSString* targetKeySignatureString = keyController.keySignature.displayStringValue;
	
	if ([originalKeySignatureString isEqualToString: targetKeySignatureString]) {
		[self leaveTransposeDialog];
		
	} else {
		NSMutableString *questionString = [NSMutableString stringWithCapacity:20];
		
		[questionString appendString:@"Do you want to transpose this song from "];
		[questionString appendString:originalKeySignatureString];
		[questionString appendString:@" to "];
		[questionString appendString:targetKeySignatureString];
		[questionString appendString:@"?"];
		
		SheetView* sheetView = sheetScrollView.sheetView;
		
		UIAlertController* alert = [UIAlertController
			alertControllerWithTitle: questionString
			message: @""
			preferredStyle: UIAlertControllerStyleActionSheet
			
		];
		
		[alert addAction:
			[UIAlertAction
				actionWithTitle: @"Transpose"
				style: UIAlertActionStyleDefault
				handler: ^(UIAlertAction * _Nonnull action) {
					KeySignature *oldKeySignature = [keyController keySignatureBeforeEditing];
					KeySignature *newKeySignature = [keyController keySignature];
					
					[sheetView transposeFromBeginningUsingOriginalKeySignature: oldKeySignature targetKeySignature: newKeySignature];
					
					[playBackController.transposeButton setTitle: [newKeySignature displayStringValue]];
					[self leaveTransposeDialog];
					
				}
				
			]
			
		];
		[alert addAction:
			[UIAlertAction
				actionWithTitle: @"Change key signature"
				style: UIAlertActionStyleDefault
				handler: ^(UIAlertAction * _Nonnull action) {
					KeySignature *oldKeySignature = [keyController keySignatureBeforeEditing];
					KeySignature *newKeySignature = [keyController keySignature];
					
					[sheetView changeKeyFromBeginningUsingOriginalKeySignature: oldKeySignature targetKeySignature: newKeySignature];
					
					[playBackController.transposeButton setTitle: [newKeySignature displayStringValue]];
					[self leaveTransposeDialog];
					
				}
				
			]
			
		];
		[alert addAction:
			[UIAlertAction
				actionWithTitle: @"Cancel"
				style: UIAlertActionStyleCancel
				handler: ^(UIAlertAction * _Nonnull action) {
					
				}
				
			]
			
		];
		
		UIView* sourceView = keyController.view;
		alert.popoverPresentationController.sourceView = sourceView;
		alert.popoverPresentationController.sourceRect = CGRectMake (
			sourceView.bounds.size.width * (1 - .34375f),
			sourceView.bounds.size.height * .5f,
			sourceView.bounds.size.width * .34375f,
			sourceView.bounds.size.height * .5f
			
		);
		
		[self presentViewController: alert animated: YES completion: nil];
		
	}
	
}

#pragma mark - Bar insertion

- (void)showInserBarActionSheet
{
	SheetView* sheetView = sheetScrollView.sheetView;
	
	UIAlertController* alert = [UIAlertController
		alertControllerWithTitle: @"Insert / Delete Bar"
		message: @""
        preferredStyle: UIAlertControllerStyleActionSheet
		
	];
	
	[alert addAction:
		[UIAlertAction
			actionWithTitle: @"Insert Bar"
			style: UIAlertActionStyleDefault
			handler: ^(UIAlertAction * _Nonnull action) {
				[sheetView insertBarAtCurrentPosition];
				
			}
			
		]
		
	];
	[alert addAction:
		[UIAlertAction
			actionWithTitle: @"Delete Bar"
			style: UIAlertActionStyleDestructive
			handler: ^(UIAlertAction * _Nonnull action) {
				[sheetView removeBarAtCurrentPosition];
				
			}
			
		]
		
	];
	
	UIView* sourceView = keyController.view;
	alert.popoverPresentationController.sourceView = sourceView;
	alert.popoverPresentationController.sourceRect = CGRectMake (
		60,
		0,
		34,
		45
		
	);
	
	[self presentViewController: alert animated: YES completion: nil];
	
}

#pragma mark - SheetEditingDelegate implementations

- (void)beginEditing
{
    SheetView* sheetView = [sheetScrollView sheetView];
	id currentElement = sheetView.currentElement;
    
    NSMutableString *keySetName = nil;
	
	if ([currentElement isKindOfClass: [AttributedChord class]]) {
        keySetName = [NSMutableString stringWithString:@"AttributedChord"];
	} else if ([currentElement isKindOfClass: [KeySignature class]]) {
        keySetName = [NSMutableString stringWithString:@"KeySignature"];
	} else if ([currentElement isKindOfClass: [TimeSignature class]]) {
        keySetName = [NSMutableString stringWithString:@"TimeSignature"];
	} else if ([currentElement isKindOfClass: [OpeningBarLine class]]) {
        keySetName = [NSMutableString stringWithString:@"OpeningBarLine"];
	} else if ([currentElement isKindOfClass: [ClosingBarLine class]]) {
        keySetName = [NSMutableString stringWithString:@"ClosingBarLine"];
	}
	
	if (keySetName == nil)
		return;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [keySetName appendString:@".ipad"];
    }
    
    [self openKeyControllerWithKeySet:keySetName element:currentElement sheetView:sheetView];
    
    if ([currentElement isKindOfClass: [AttributedChord class]]) {
        [[self keyController] syncKeysWithChord:currentElement];
	} else if ([currentElement isKindOfClass: [TimeSignature class]]) {
        [[self keyController] syncKeysWithTimeSignature:currentElement];
	} else if ([currentElement isKindOfClass: [OpeningBarLine class]]) {
        [[self keyController] syncKeysWithOpeningBarLine:currentElement];
	} else if ([currentElement isKindOfClass: [ClosingBarLine class]]) {
        [[self keyController] syncKeysWithClosingBarLine:currentElement];
	}
	
	if (!currentElement || [currentElement isKindOfClass: [TextModel class]]) {
		if (playBackController.transposeButton.enabled)
			playBackController.transposeButton.enabled = NO;
	} else {
		if (!playBackController.transposeButton.enabled)
			playBackController.transposeButton.enabled = YES;
	}
}

- (void)endEditing
{
    [self closeKeyController];
	[sheetScrollView centerContentAnimated: YES];
}

- (void)didChangeSheetTitle
{
    self.navigationItem.title = [[sheetScrollView sheet] title];
}

- (void) beginPlayback
{
    [[[self playBackController] playButton] setImage:[UIImage imageNamed:@"pause.png"]];
    [[self playBackController] setPlaying:YES];
}

- (void)endPlayback
{
    [[[self playBackController] playButton] setImage:[UIImage imageNamed:@"play.png"]];
    [[self playBackController] setPlaying:NO];
}

- (void)swapSheet:(int)direction
{
	[self saveSongIfEdited];
	
	[self setSheet:nil];
	[playBackController setSheetView:nil];
	
	[sheetScrollView reset];
	[[sheetScrollView sheetView] setColorScheme:[self currentColorScheme]];
    
    NSArray *songArray;
    
    if ([sortKeyName isEqualToString:@"custom"]) {
        songArray = [[self playlist] getSongsSortedByAttribute:@"index" ascending:YES];
    }
    else {
        songArray = [[self playlist] getSongsSortedByAttribute:[self sortKeyName] ascending:YES];
    }
    
    int currentSongIndex = 0;
    int newSongIndex = 0;
            
    for (Song *tempSong in songArray) {
        if ([tempSong artist] == [[self song] artist] && [tempSong title] == [[self song] title]) {
            break;
        }
        else {
            currentSongIndex++;
        }
    }
    
    if (direction >= 0) {
        newSongIndex = currentSongIndex + 1;
    }
    else {
        newSongIndex = currentSongIndex - 1;
    }
    
    [self setSong:[songArray objectAtIndex:newSongIndex]];
    
    [self sheetScrollView]->canLeaveToLeft = !isEditingNewSong && newSongIndex < ([songArray count] - 1);
	[self sheetScrollView] -> canLeaveToRight = !isEditingNewSong && newSongIndex > 0;
	    
    [[self sheetScrollView] setSheet:[self sheet]];
    [[self playBackController] setSheetView:[sheetScrollView sheetView]];
    [[[self sheetScrollView] sheetView] setEditingDelegate:self];
	
	[self setUpSheetView];
	
    [[self navigationItem]setTitle:[sheet title]];
    
	playBackController.transposeButton.title = [[[sheetScrollView sheetView] firstKeySignature] displayStringValue];
	
    [[self playBackController] changeBPM:[[self sheet] tempo]];
    [[self playBackController] updateSliderAnimated: NO];
}

#pragma mark - PDF generation and printing

- (void) presentExportMenu: (id) sender {
	
	UIAlertController* alert = [UIAlertController
		alertControllerWithTitle: @"Export Sheet"
		message: @""
        preferredStyle: UIAlertControllerStyleActionSheet
		
	];
	
	[alert addAction:
		[UIAlertAction
			actionWithTitle: @"Print"
			style: UIAlertActionStyleDefault
			handler: ^(UIAlertAction * _Nonnull action) {
				[self exportToPrinter];
				
			}
			
		]
		
	];
	[alert addAction:
		[UIAlertAction
			actionWithTitle: @"Export as PDF"
			style: UIAlertActionStyleDefault
			handler: ^(UIAlertAction * _Nonnull action) {
				[self exportToPDF];
				
			}
			
		]
		
	];
	[alert addAction:
		[UIAlertAction
			actionWithTitle: @"Cancel"
			style: UIAlertActionStyleCancel
			handler: ^(UIAlertAction * _Nonnull action) {
				
			}
			
		]
		
	];
	
	UIView* sourceView = self.navigationController.navigationBar;
	alert.popoverPresentationController.sourceView = sourceView;
	alert.popoverPresentationController.sourceRect = CGRectMake (
		sourceView.bounds.size.width - 60,
		0,
		60,
		sourceView.bounds.size.height
		
	);
	
	[self presentViewController: alert animated: YES completion: nil];
	
}

extern NSString* SHEET_COLOR_SCHEME_PRINT;

- (NSData*) pdfDataForSize: (CGSize) size {
	// NSLog (@"generating pdf with size %f x %f", size.width, size.height);
	
	NSMutableData* pdfData = [NSMutableData data];
	UIGraphicsBeginPDFContextToData (
		pdfData, CGRectMake (0, 0, size.width, size.height), nil
		
	);
	
	// Mark the beginning of a new page.
	UIGraphicsBeginPDFPageWithInfo (
		CGRectMake (0, 0, size.width, size.height), nil
		
	);
	
	SheetLayer* sheetLayer = self.sheetScrollView.sheetLayer;
	CGContextRef currentContext = UIGraphicsGetCurrentContext ();
	
	CGContextTranslateCTM (currentContext, 94, 42);
	
	float lastScale = sheetLayer.scale;
	NSString* lastColourScheme = sheetLayer.colorScheme;
	
	[sheetLayer setColorScheme: SHEET_COLOR_SCHEME_PRINT];
	[sheetLayer setScale: 1.];
	[sheetLayer updateLayout];
	
	const CGFloat maxWidth = size.width - 94 - 42;
	const CGFloat maxHeight = size.height - 42 - 42;
	
	CGSize sheetSize = sheetLayer.bounds.size;
	// NSLog (@"content size is %f x %f", sheetSize.width, sheetSize.height);
	
	if (sheetSize.height > maxHeight) {
		CGFloat scale = maxHeight / sheetSize.height;
		CGContextScaleCTM (currentContext, scale, scale);
		
		sheetSize.width *= scale;
		sheetSize.height *= scale;
		
	}
	
	if (sheetSize.width < maxWidth) {
		sheetLayer -> printingLayoutWidth = (float) maxWidth - 36;
		[sheetLayer updateLayout];
		
		// NSLog(@"width is now %f", sheetLayer.bounds.size.width);
		
	} else if (sheetSize.width > maxWidth) {
		CGFloat scale = maxWidth / sheetSize.width;
		CGContextScaleCTM (currentContext, scale, scale);
		
	}
	
	[sheetLayer updateLayerVisibilityInRect: CGRectMake (
		0, 0,
		MAX (maxWidth, sheetLayer.bounds.size.width),
		sheetLayer.bounds.size.height
		
	)];
	[sheetLayer renderImmediatelyInContext: currentContext];
	
    UIGraphicsEndPDFContext();
	
	sheetLayer -> printingLayoutWidth = 0;
	
	[sheetLayer setColorScheme: lastColourScheme];
	[sheetLayer setScale: lastScale];
	[sheetLayer updateLayout];
	
	[self.sheetScrollView layoutSubviews];
	
	return pdfData;
	
}

- (void) exportToPrinter {
	// NSLog (@"to printer");
	
	NSData* pdfData =
		[self pdfDataForSize: CGSizeMake (595, 842)];
	
	UIPrintInteractionController* printController =
		[UIPrintInteractionController sharedPrintController];
	
	printController.printingItem = pdfData;
	
	UIPrintInteractionCompletionHandler completionHandler =
		^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
			// NSLog (@"completed: %i, error %@", completed, error);
			
		};
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGRect originatingBounds = self.sheetScrollView.sheetView.bounds;
		originatingBounds.origin.x -= self.sheetScrollView.contentOffset.x;
		originatingBounds.origin.y -= self.sheetScrollView.contentOffset.y;
		originatingBounds.size.height = 1;
		
extern float navigationBarHeight;

		originatingBounds.size.width = MIN (
			originatingBounds.size.width,
			self.sheetScrollView.bounds.size.width
			
		);
		originatingBounds.origin.y = MAX (
			originatingBounds.origin.y + 54 * self.sheetScrollView.sheetLayer.scale,
			navigationBarHeight
			
		);
		
		[printController presentFromRect: originatingBounds
			inView: self.view
			animated: YES
			completionHandler: completionHandler];
		
	} else {
		[printController presentAnimated: YES
			completionHandler: completionHandler];
		
	}
	
	
}

- (void) exportToPDF {
	// NSLog (@"to pdf");
	
	NSData* pdfData =
		[self pdfDataForSize: CGSizeMake (595, 842)];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex: 0];
	NSString *filePath = [documentsDirectory stringByAppendingPathComponent:
		[[NSString stringWithFormat: @"%@ — %@.pdf", sheet.artist, sheet.title] stringByReplacingOccurrencesOfString: @"/" withString: @"-"]
		
	];
	
	[pdfData writeToFile: filePath atomically: YES];
	
	UIDocumentInteractionController* interactionController =
		[UIDocumentInteractionController interactionControllerWithURL: [NSURL fileURLWithPath: filePath]];
	interactionController.name = @"Preview";
	interactionController.delegate = self;
	
	[interactionController presentPreviewAnimated: YES];
	
}

- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) interactionController {
	return self.navigationController;
	
}

- (void) documentInteractionControllerDidEndPreview: (UIDocumentInteractionController*) interactionController {
	NSError* error;
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath: interactionController.URL.path error: &error];
	
	if (!success)
		NSLog (@"%@", error);
	
}

@end
