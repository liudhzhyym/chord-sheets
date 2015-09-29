//
//  ChordPlayer.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 15.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "ChordPlayer.h"

#import "LoaderSystem.h"
#import "SoundMixer.h"

#import "Key.h"
#import "Chord.h"


#define HALF_STEPS_PER_SAMPLE 4


@implementation ChordPlayer

NSArray* soundFileNames;

+ (void) initialize {
	if (!soundFileNames) {
		soundFileNames = [[NSArray alloc] initWithObjects:
			@"Piano_C2.aif",
			@"Piano_E2.aif",
			@"Piano_G#2.aif",
			@"Piano_C3.aif",
			@"Piano_E3.aif",
			@"Piano_G#3.aif",
			@"Piano_C4.aif",
			@"Piano_E4.aif",
			@"Piano_G#4.aif",
			nil];
		
	}
	
}

+ (ChordPlayer*) sharedInstance {
	
	if (!ENABLE_SOUND)
		return nil;
	
	static ChordPlayer* instance;
	if (!instance)
		instance = [[[self class] alloc] init];
	
	return instance;
	
}

- (id) init {
	if ((self = [super init])) {
		soundMixer = [SoundMixer sharedInstance];
		[soundMixer startAUGraph];
		
		for (NSString* soundFileName in soundFileNames)
			[soundMixer loadSound: soundFileName];
		
	}
    
	return self;
}

- (void) playChord: (Chord*) chord {
	
	NSArray* keys = [chord.keys allObjects];
	
	// NSLog (@"--- play keys ---");
	
	for (int i = MIN ((int) [keys count], NUM_AUDIO_BUFFERS); i--;) {
		NSNumber* key = [keys objectAtIndex: i];
		int keyValue = key.intValue;
		// NSLog (@"  %@ (%i)", [Key keyWithInt: keyValue], keyValue);
		
		[self playNote: keyValue];
		
	}
	
}

- (void) playNote: (float) note {
	
	NSString* soundFileName = nil;
	
	note = note - 12 * 0;
	for (int i = 0; i < [soundFileNames count]; i++) {
		if (note < HALF_STEPS_PER_SAMPLE / 2 ||
			i == [soundFileNames count] - 1) {
			soundFileName = [soundFileNames objectAtIndex: i];
			break;
			
		}
		note -= HALF_STEPS_PER_SAMPLE;
		
	}
	
	float freq = powf (2, note / 12);
	// NSLog (@"note %f; freq %f; file %@", note, freq, soundFileName);
	
	[soundMixer playSound: soundFileName volume: 1.f / 4 rate: freq];
	
}

- (void) dealloc {
	if (soundMixer) {
		for (NSString* soundFileName in soundFileNames)
			[soundMixer unloadSound: soundFileName];
		[soundMixer release];
		
	}
	[super dealloc];
	
}

@end
