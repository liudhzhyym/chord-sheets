//
//  SplashViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 16.12.11.
//  Copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "SplashViewController.h"
#import "PlaylistAdministrationViewController.h"
#import "AboutViewController.h"

@implementation SplashViewController

@synthesize aboutButton;
@synthesize versionLabel;
@synthesize background;
@synthesize rootController;


- (id)initWithRootViewController:(RootViewController *)rootViewController
{
    self = [super initWithNibName:@"SplashView" bundle:nil];
    
    if (self) {
        [self setRootController:rootViewController];
    }
    
    return self;
}

- (void)releaseReferences
{
	self.aboutButton = nil;
	self.background = nil;
}

- (void)dealloc
{
	[self releaseReferences];
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
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    if (animated)
	    [[self navigationController] setNavigationBarHidden:YES animated:YES];
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self adaptToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    }
    else if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self adaptToIphone5];
    }
	
}

-(UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
	
}

- (void) viewDidAppear:(BOOL)animated{
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
	
	[super viewDidAppear:animated];
	
	
}

#pragma mark - View rotation

- (void) viewWillTransitionToSize: (CGSize) size withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>) coordinator {
	UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	
	[self adaptToOrientation: (UIInterfaceOrientation) deviceOrientation];
	
	[super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
	
}

-(void)adaptToIphone5
{
    if (([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale) >=1136)
    {
        [[self background] setImage:[UIImage imageNamed:@"Splash-568h@2x.png"]];
    }
}

-(void)adaptToOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [[self background] setImage:[UIImage imageNamed:@"Splash-portrait.png"]];
    }
    else {
        [[self background] setImage:[UIImage imageNamed:@"Splash-landscape.png"]];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [self showPlaylistAdministrationView];
}

- (IBAction)aboutButtonPressed:(id)sender
{
    AboutViewController *aboutController = [[AboutViewController alloc] init];
    [aboutController setDelegate:self];
    [[self rootController] presentViewController:aboutController animated:YES completion:nil];
            
    [aboutController release];
}

- (void)showPlaylistAdministrationView
{
    PlaylistAdministrationViewController *newController =
    [[PlaylistAdministrationViewController alloc] initWithNibName:@"PlaylistAdministrationView" bundle:nil];
    [[self navigationController] pushViewController:newController animated:YES];
    [newController release];
}

- (void)removeAboutController:(AboutViewController *)aboutViewController
{
    [[self rootController] dismissViewControllerAnimated:YES completion:nil];
}

@end
