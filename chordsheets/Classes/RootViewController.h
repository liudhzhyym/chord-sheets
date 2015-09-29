//
//  RootViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 17.10.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController

@property (nonatomic, retain) UINavigationController *navController;

- (void) switchToLibraryPlaylistAndRefresh;

@end
