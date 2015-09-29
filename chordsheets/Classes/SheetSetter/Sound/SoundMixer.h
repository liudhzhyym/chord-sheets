#import "Dispatcher.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#import "SoundMixerSettings.h"


typedef struct {
    AudioStreamBasicDescription asbd;
	
	UInt32 numFrames;
    SInt16 *data;
	
	Boolean playing;
	UInt32 sampleNum;
	
	double scale;
	float amp;
	
	// Boolean flagLoop;
	
} SoundBuffer;


@interface SoundMixer : Dispatcher {

@public
    SoundBuffer* soundBuffers [NUM_AUDIO_BUFFERS];
	
	Boolean isPlaying;
	Boolean outBufferIsClear;
	
@protected
	AUGraph   mGraph;
	AudioUnit mMixer;
	
}

+ (SoundMixer*) sharedInstance;


- (void) startAUGraph;
- (void) stopAUGraph;

- (void) loadSound: (NSString*) path;
- (void) unloadSound: (NSString*) path;

- (void) playSound: (NSString*) name;
- (void) playSound: (NSString*) name volume: (float) volume;
- (void) playSound: (NSString*) name volume: (float) volume rate: (double) rate;
- (void) playSound: (NSString*) name volume: (float) volume rate: (double) rate loop: (BOOL) doLoop;


@end
