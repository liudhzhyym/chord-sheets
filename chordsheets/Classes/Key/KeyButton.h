//
//  KeyButton.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 08.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>

@interface KeyButton : UIButton

@property (nonatomic, assign) float numCells;
@property (nonatomic, retain) NSMutableArray *actives;
@property (nonatomic, retain) NSMutableArray *deactives;
@property (nonatomic, retain) NSMutableArray *dependsOn;
@property (nonatomic, retain) NSMutableArray *excludedBy;
@property (nonatomic, retain) NSMutableDictionary *backgroundStates;

- (void) setBackgroundColor:(UIColor *) _backgroundColor forState:(UIControlState) _state;
- (UIColor*) backgroundColorForState:(UIControlState) _state;

@end
