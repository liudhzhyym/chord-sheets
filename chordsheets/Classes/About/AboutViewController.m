//
//  AboutViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 03.01.12.
//  copyright (c) 2012 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "AboutViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@implementation AboutViewController

@synthesize scrollView;
@synthesize delegate;
@synthesize header;
@synthesize footer;
@synthesize backButtonTop;
@synthesize versionLabelTop;
@synthesize leftTextLabel;
@synthesize rightTextLabel;

- (id)init
{
    self = [super initWithNibName:@"AboutView" bundle:nil];
    
    if (self) {
        
    }
    
    return self;
}

- (void)dealloc
{
    [delegate release];
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
	
	self.view.autoresizesSubviews = YES;
	
	scrollView.contentInset = UIEdgeInsetsMake (21, 0, 0, 0);
    scrollView.contentSize = scrollView.frame.size;
	scrollView.scrollIndicatorInsets = UIEdgeInsetsMake (21, 0, 0, 0);
	
	[self.view insertSubview: scrollView atIndex: 0];
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [rightTextLabel sizeToFit];
        [leftTextLabel sizeToFit];
    }

	scrollView.frame = self.view.frame;
	
	[self setNeedsStatusBarAppearanceUpdate];
	
}

-(UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
	
}

#pragma mark - View rotation

- (void) viewWillTransitionToSize: (CGSize) size withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>) coordinator {
	// UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[rightTextLabel sizeToFit];
		[leftTextLabel sizeToFit];
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		
	}];
	
	[super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
	
}

-(IBAction)backButtonPressed:(id)sender
{
    [[self delegate] removeAboutController:self];
}

-(IBAction)openAppDeveloperPage:(id)sender
{
	[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"https://github.com/wysiwyg-software-design/chord-sheets"]];
}

@end
