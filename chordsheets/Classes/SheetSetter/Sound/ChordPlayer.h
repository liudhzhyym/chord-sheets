//
//  ChordPlayer.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 15.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>


@class SoundMixer;
@class Chord;


@interface ChordPlayer : NSObject {
	
	@protected
	
	SoundMixer* soundMixer;
	
}

+ (ChordPlayer*) sharedInstance;

- (void) playChord: (Chord*) chord;
- (void) playNote: (float) note;

@end
