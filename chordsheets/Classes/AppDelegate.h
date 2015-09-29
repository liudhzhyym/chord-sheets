//
//  AppDelegate.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 14.10.11.
//  copyright (c) 2011 wysiwyg* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Database.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
	BOOL lightsOutModeEnabled;
	
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain, readonly) Database *database;

@property (nonatomic, assign, getter = isLightsOutModeEnabled) BOOL lightsOutModeEnabled;
@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, retain) UIColor* barTintColor;


-(void)setDefaultSettings;
-(NSURL *)applicationDocumentsDirectory;


@end
