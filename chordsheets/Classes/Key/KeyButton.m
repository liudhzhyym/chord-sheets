//
//  KeyButton.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 08.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "KeyButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation KeyButton

@synthesize numCells;
@synthesize actives;
@synthesize deactives;
@synthesize dependsOn;
@synthesize excludedBy;
@synthesize backgroundStates;

- (void) dealloc {
    [backgroundStates release];
    [super dealloc];
}

- (void) setBackgroundColor:(UIColor *) _backgroundColor forState:(UIControlState) _state {
    if (backgroundStates == nil) 
        backgroundStates = [[NSMutableDictionary alloc] init];
    
    [backgroundStates setObject:_backgroundColor forKey:[NSNumber numberWithInt:_state]];
    
    if (self.backgroundColor == nil)
        [self setBackgroundColor:_backgroundColor];
}

- (UIColor*) backgroundColorForState:(UIControlState) _state {
    return [backgroundStates objectForKey:[NSNumber numberWithInt:_state]];
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected) {
        UIColor *selectedColor = [backgroundStates objectForKey:[NSNumber numberWithInt:UIControlStateSelected]];
        
        if (selectedColor) {
            [self setBackgroundColor:selectedColor];
            [[self titleLabel] setTextColor: [self titleColorForState:UIControlStateSelected]];
        }
    }
    else {
        UIColor *normalColor = [backgroundStates objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
        
        if (normalColor) {
            [self setBackgroundColor:normalColor];
            [[self titleLabel] setTextColor: [self titleColorForState:UIControlStateNormal]];
        }
    }
}

@end
