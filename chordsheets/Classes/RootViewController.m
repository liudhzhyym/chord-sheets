//
//  RootViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 17.10.11.
//  Copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "RootViewController.h"
#import "AppDelegate.h"
#import "SplashViewController.h"
#import "PlaylistAdministrationViewController.h"
#import "Database.h"
#import "SheetSetterViewController.h"

@implementation RootViewController

@synthesize navController;

- (id)init
{
    self = [super init];
    
    if (self) {
		UINavigationController *nav = nil;
		
        // check if we want to only show the sheetsetter for debugging purposes
        NSDictionary *sheetsetterOnlyDict = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Sheetsetter only mode"];
        BOOL sheetsetterOnlyEnabled = [[sheetsetterOnlyDict objectForKey:@"Enabled"] boolValue];
        
        if (sheetsetterOnlyEnabled) {
			// search the specified song and show it in the SheetSetter
            NSString *songArtist = [sheetsetterOnlyDict objectForKey:@"Song artist"];
            NSString *songTitle = [sheetsetterOnlyDict objectForKey:@"Song title"];
            
            Database *dataBase = [(AppDelegate *)[[UIApplication sharedApplication] delegate] database];
            Playlist *library = [dataBase library];
            Song *song = nil;
            
            for (SongIndex *tempSongIndex in [library songs]) {
                bool artistMatches = ([[[tempSongIndex song] artist] caseInsensitiveCompare:songArtist] == NSOrderedSame);
                bool titleMatches = ([[[tempSongIndex song] title] caseInsensitiveCompare:songTitle] == NSOrderedSame);
                
                if (artistMatches && titleMatches) {
                    song = [tempSongIndex song];
                }
            }
            
            SheetSetterViewController *sheetSetterController = [[SheetSetterViewController alloc] initWithDataSource:dataBase playlist:library sortKey:@"title" song:song];
			nav = [[UINavigationController alloc] initWithRootViewController:sheetSetterController];
            [sheetSetterController release];
			
        } else {
            SplashViewController *splashController = [[SplashViewController alloc] initWithRootViewController:self];
			
			nav = [[UINavigationController alloc] initWithRootViewController:splashController];
			[nav setNavigationBarHidden: YES animated: NO];
			
            [splashController release];
			
        }
		[self setNavController:nav];
		[nav release];
		
		[[navController view] setFrame:[[self view] bounds]];
		[[self view] addSubview:[navController view]];
		
		[self addChildViewController: nav];
		
		
    }
    
    return self;
    
}

- (UIViewController * _Nullable) childViewControllerForStatusBarStyle {
    return [navController visibleViewController];
    
}

- (UIViewController * _Nullable) childViewControllerForStatusBarHidden {
    return [navController visibleViewController];
    
}



- (void) releaseReferences {
	self.navController = nil;
}

- (void) dealloc
{
	[self releaseReferences];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    [[self navigationController] didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    //[[[self navController] navigationBar] setBarStyle:UIBarStyleBlack];
}

- (void) switchToLibraryPlaylistAndRefresh
{    
    if ([[[self navController] viewControllers] count] == 1) {
        [(SplashViewController *)[[[self navController] viewControllers] objectAtIndex:0] showPlaylistAdministrationView];
    }
    else if([[[self navController] viewControllers] count] > 2) {
        [[self navController] popToViewController:[[[self navController] viewControllers] objectAtIndex:1] animated:YES];
    }
    
    [[(PlaylistAdministrationViewController *)[[self navController] topViewController] table] reloadData];
}

@end
