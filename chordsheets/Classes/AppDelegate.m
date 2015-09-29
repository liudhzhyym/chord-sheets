//
//  AppDelegate.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 14.10.11.
//  copyright (c) 2011 wysiwyg* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import "Database.h"

@implementation AppDelegate

@synthesize window;
@synthesize database;


- (BOOL) isLightsOutModeEnabled {
	return lightsOutModeEnabled;
	
}
- (void) setLightsOutModeEnabled: (BOOL) doSet {
	lightsOutModeEnabled = doSet;
	
	RootViewController *viewController = (RootViewController*) self.window.rootViewController;
	viewController.navController.view.backgroundColor = doSet ?
		[UIColor colorWithRed: 13 / 255.f green: 13 / 255.f blue: 13 / 255.f alpha: 255.f] : [UIColor whiteColor];
	
    
    
}

- (void)dealloc
{
    //[[self window] release];
    [database release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setDefaultSettings];
    
    [self setWindow:[[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease]];
	
    [UIApplication sharedApplication].keyWindow.frame=CGRectMake(0, 20, [[self window] frame].size.width, [[self window] frame].size.height - 20); //move down 20px.
    
    if(database == nil) {
        database = [[Database alloc] initWithDocumentsDirectoryURL:[self applicationDocumentsDirectory]];
    }
        
    RootViewController *viewController = [[RootViewController alloc] init];
    [[self window] setRootViewController:viewController];
    [viewController release];
	
	self.lightsOutModeEnabled = NO;
	
    [[self window] makeKeyAndVisible];
    
    return YES;
}

- (BOOL)prefersStatusBarHidden {
	return NO;
	
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application
{    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    if ([defaults boolForKey:@"databaseReset"]) {
        [[self database] restoreDefaultSongs];
        [defaults setValue:@"NO" forKey:@"databaseReset"];
    }
    
    if ([defaults boolForKey:@"disableScreenDimming"]) {
        [application setIdleTimerDisabled:YES];
    }
    else {
        [application setIdleTimerDisabled:NO];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString *, id> * _Nonnull)options
{    
    if (url != nil && [url isFileURL]) {
        
        if(database == nil) {
            database = [[Database alloc] initWithDocumentsDirectoryURL:[self applicationDocumentsDirectory]];
        }
        
        NSData *fileContent = [[NSData alloc] initWithContentsOfURL:url];
        [[database importer] readSongWithData:fileContent];
        [database syncSongsWithSystemPlaylists];
        
        [fileContent release];
        
        [(RootViewController *)[[self window] rootViewController] switchToLibraryPlaylistAndRefresh];
        return YES;
    }
    
    return NO;
}

-(void) setDefaultSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults stringForKey:@"selfcomposedArtist"] != nil) {
        return;
    }
    
    NSMutableDictionary *appDefaults = [[NSMutableDictionary alloc] init];
    [appDefaults setValue:@"NO" forKey:@"disableScreenDimming"];
    [appDefaults setValue:@"NO" forKey:@"databaseReset"];
    [appDefaults setValue:@"Unknown Artist" forKey:@"selfcomposedArtist"];
    [appDefaults setValue:@"Unknown" forKey:@"selfcomposedAuthor"];
    
    [defaults registerDefaults:appDefaults];
    [defaults synchronize];
    [appDefaults release];
}

#pragma mark - Application's Documents directory

/**
 * Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
