//
//  AboutViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 03.01.12.
//  copyright (c) 2012 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class AboutViewController;

@protocol AboutViewControllerDelegate <NSObject>

@required

- (void)removeAboutController:(AboutViewController *)aboutViewController;

@end

@interface AboutViewController : UIViewController


@property (nonatomic, retain) id <AboutViewControllerDelegate> delegate;

@property (nonatomic, assign) IBOutlet UIScrollView *scrollView;
@property (nonatomic, assign) IBOutlet UIImageView *header;
@property (nonatomic, assign) IBOutlet UIImageView *footer;
@property (nonatomic, assign) IBOutlet UIButton *backButtonTop;
@property (nonatomic, assign) IBOutlet UILabel *versionLabelTop;

@property (nonatomic, assign) IBOutlet UILabel *leftTextLabel;
@property (nonatomic, assign) IBOutlet UILabel *rightTextLabel;

-(IBAction)backButtonPressed:(id)sender;
-(IBAction)openAppDeveloperPage:(id)sender;

@end
