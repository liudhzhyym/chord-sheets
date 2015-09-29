//
//  SplashViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 16.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import "AboutViewController.h"
#import "RootViewController.h"

@interface SplashViewController : UIViewController <AboutViewControllerDelegate>

@property (nonatomic, retain) IBOutlet UIButton *aboutButton;
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UIImageView *background;
@property (nonatomic, retain) RootViewController *rootController;

- (IBAction) aboutButtonPressed:(id)sender;

- (id)initWithRootViewController:(RootViewController *)rootViewController;
- (void)showPlaylistAdministrationView;
- (void)removeAboutController:(AboutViewController *)aboutViewController;

-(void)adaptToOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
-(void)adaptToIphone5;

@end
