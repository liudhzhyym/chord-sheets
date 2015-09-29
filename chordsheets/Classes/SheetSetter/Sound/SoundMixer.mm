#import "SoundMixer.h"

#import "AUComponentDescription.h"

#import "CAStreamBasicDescription.h"
#import "CADebugMacros.h"
#import "CAXException.h"

#import "LoaderSystem.h"
#import "SoundLoaderJob.h"



//void DebugStr (const unsigned char* debuggerMsg) {printf ("%s", debuggerMsg);}

const Float64 kGraphSampleRate = 44100.0;


#pragma mark- RenderProc

#define PI 3.141592653589793

typedef SInt16 SampleType;

// audio render procedure, don't allocate memory, don't take any locks, don't waste time
static OSStatus renderInput (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
	SoundMixer* self = (SoundMixer*) inRefCon;
	
	SampleType *outA = (SampleType*) ioData -> mBuffers [0].mData;
	// SampleType *outB = (SampleType*) ioData -> mBuffers [1].mData;
	
	if (!self -> outBufferIsClear) {
		self -> outBufferIsClear = true;
		bzero (outA, inNumberFrames * sizeof (SampleType));
		// bzero (outB, inNumberFrames * sizeof (SampleType));
		
	}
    SoundBuffer** soundBuffers = self -> soundBuffers;
	
	for (int j = NUM_AUDIO_BUFFERS; j--;) {
		
		SoundBuffer* soundBuffer = soundBuffers [j];
		if (!soundBuffer -> playing)
			continue;
		
		self -> outBufferIsClear = false;
		
		UInt32 numSamples = soundBuffer -> numFrames;
		// double currentScale = 1 - GLOB_DAMP;
		
		SampleType *in = (SampleType*) (soundBuffer -> data);
		if (!in)
			continue;
		
		double scale = soundBuffer -> scale;
		float amp = soundBuffer -> amp;
		
		UInt32 sample = soundBuffer -> sampleNum;
		for (UInt32 i = 0; i < inNumberFrames; i++) {
			
			long int address = sample + (UInt32) ((float) i * scale); //((long int) (sample + i * currentScale) /* % bufSamples */) + GLOB_OFF + GLOB_DRIFT;
			//if (address < 0)
			//	address += bufSamples;
			
			outA [i] += address < numSamples ?
				(SampleType) in [address] * amp * 1 : 0;
			
			//	GLOB_DRIFT /= 1.0001;
			//	GLOB_OFF += GLOB_DRIFT;
			
		}
		
		sample = (UInt32) (sample + (double) inNumberFrames * scale); // * currentScale) /* % bufSamples */;
		soundBuffer -> sampleNum = sample;
		
		if (sample >= numSamples)
			soundBuffer -> playing = false;
		
	}
	// printf ("bus %d sample %d\n", inBusNumber, sample);
	return noErr;
	
}

#pragma mark- SoundMixer

@interface SoundMixer (Private)

- (void) initializeAUGraph;

- (void) enableInput: (UInt32) inputNum isOn: (AudioUnitParameterValue) isONValue;
- (void) setInputVolume: (UInt32) inputNum value: (AudioUnitParameterValue) value;
- (void) setOutputVolume: (AudioUnitParameterValue) value;
 
@end



@implementation SoundMixer


+ (SoundMixer*) sharedInstance {
	
	if (!ENABLE_SOUND)
		return nil;
	
	static SoundMixer* instance;
	if (!instance) {
		AVAudioSession* audioSession = [AVAudioSession sharedInstance];
		
		NSError* error = nil;
		
		[audioSession setCategory: AVAudioSessionCategoryAmbient error: &error];
		[audioSession setPreferredSampleRate: 44100.0 error: &error];
		[audioSession setPreferredIOBufferDuration: .005 error: &error];
		
		instance = [[SoundMixer alloc] init];
		
	}
	return instance;
	
}

- (id) init {
	if ((self = [super init])) {
		// printf ("init\n");
		
		isPlaying = false;
		outBufferIsClear = false;
		
		memset (&soundBuffers, 0, sizeof soundBuffers);
		
		for (int i = NUM_AUDIO_BUFFERS; i--;) {
			SoundBuffer* soundBuffer = (SoundBuffer*) malloc (sizeof (SoundBuffer));
			bzero (soundBuffer, sizeof (SoundBuffer));
			soundBuffers [i] = soundBuffer;
			
		}
		
		[self initializeAUGraph];
		[self enableInput:0 isOn: YES];
		[self setOutputVolume: 1];
		[self setInputVolume: 0 value: 1]; // * NUM_AUDIO_BUFFERS
		
	}
	return self;
	
}

// analyzer is disabled for the next three methods, since [job retain] and [job release] trigger warnings
#ifndef __clang_analyzer__

- (void) loadSound: (NSString*) path {
	
	LoaderJob* job = nil; // = [soundSet objectForKey: path];
	
	if (!job) {
		LoaderSystem* loader = [LoaderSystem sharedInstance];
		job = [loader loaderForPath: path ofClass: [SoundLoaderJob class]];
		
		if (!job -> state) {
			[job addListener: self selector: @selector (soundLoadComplete:) forEvent: @"complete"];
			[loader enqueueJob: job];
		}
	}
    
	[job retain];
}

- (void) soundLoadComplete: (SoundLoaderJob*) job {
	// NSLog (@"created sound %@", job -> path);
	[job removeListener: self selector: @selector (soundLoadComplete:) forEvent: @"complete"];
	
}

- (void) unloadSound: (NSString*) path {	
	LoaderSystem* loader = [LoaderSystem sharedInstance];
	LoaderJob* job = [loader loaderForPath: path ofClass: [SoundLoaderJob class]];
		
	[job release];
}

#endif

- (void) playSound: (NSString*) name {
	[self playSound: name volume: 1 rate: 1 loop: NO];
	
}

- (void) playSound: (NSString*) name volume: (float) volume {
	[self playSound: name volume: volume rate: 1 loop: NO];

}

- (void) playSound: (NSString*) name volume: (float) volume rate: (double) rate {
	[self playSound: name volume: volume rate: rate loop: NO];

}

static unsigned int roundRobin = 0; // okay for now

- (void) playSound: (NSString*) name volume: (float) volume rate: (double) rate loop: (BOOL) doLoop {
	static unsigned int polyToggle = 0;
	
	volume = fminf (1., fmaxf (0., volume));
	if (volume == 0)
		return;
	
	unsigned int i = roundRobin;
	
//	for (unsigned int i = NUM_AUDIO_BUFFERS; i--;) {
		SoundBuffer* soundBuffer = soundBuffers [(i + polyToggle) % NUM_AUDIO_BUFFERS];
		
//		if (soundBuffer -> playing)
//			continue; // must cancel playback
		
		SoundLoaderJob* job = [LoaderSystem.sharedInstance loaderForPath: name ofClass: [SoundLoaderJob class]];
		if (!job)
			@throw [NSError errorWithDomain: @"user fault, no such sound" code: -1 userInfo: nil];
		
		SoundBuffer* sourceBuffer = (SoundBuffer*) job -> data;
		if (!sourceBuffer)
			return;
		
		soundBuffer -> sampleNum = 0;
		soundBuffer -> numFrames = 1; // okay for now, use spinlock later
		soundBuffer -> data = sourceBuffer -> data;
		soundBuffer -> numFrames = sourceBuffer -> numFrames;
		soundBuffer -> amp = volume;
		soundBuffer -> scale = rate;
		soundBuffer -> playing = true;
		
//		break;
		
//	}
	
	roundRobin = (roundRobin + 1) % NUM_AUDIO_BUFFERS;
	
}

- (void) dealloc {    
	// printf ("SoundMixer dealloc\n");
    
    DisposeAUGraph (mGraph);
	
	[super dealloc];
	
}

- (void) initializeAUGraph {
    // printf ("initialize\n");
    
    AUNode outputNode;
	AUNode mixerNode;
    CAStreamBasicDescription desc;
	
	OSStatus result = noErr;
    
    // create a new AUGraph
	result = NewAUGraph (&mGraph);
    if (result) {
		printf ("NewAUGraph result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
		
	}
	
    // create two AudioComponentDescriptions for the AUs we want in the graph
    
    // output unit
	AUComponentDescription output_desc (
		kAudioUnitType_Output, kAudioUnitSubType_RemoteIO,
		kAudioUnitManufacturer_Apple
	
	);
    
    // multichannel mixer unit
	AUComponentDescription mixer_desc (
		kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer,
		kAudioUnitManufacturer_Apple
	
	);

    // printf ("new nodes\n");

    // create a node in the graph that is an AudioUnit, using the supplied AudioComponentDescription to find and open that unit
	result = AUGraphAddNode (mGraph, &output_desc, &outputNode);
	if (result) {
		printf ("AUGraphNewNode 1 result %d %4.4s\n", (int)result, (char*) &result);
		return;
	
	}

	result = AUGraphAddNode (mGraph, &mixer_desc, &mixerNode );
	if (result) {
		printf ("AUGraphNewNode 2 result %d %4.4s\n", (int)result, (char*) &result);
		return;
	
	}

    // connect a node's output to a node's input
	result = AUGraphConnectNodeInput (mGraph, mixerNode, 0, outputNode, 0);
	if (result) {
		printf ("AUGraphConnectNodeInput result %d %4.4s\n", (int)result, (char*) &result);
		return;
	
	}
	
    // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
	result = AUGraphOpen (mGraph);
	if (result) {
		printf ("AUGraphOpen result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}
	
	result = AUGraphNodeInfo (mGraph, mixerNode, NULL, &mMixer);
    if (result) {
		printf ("AUGraphNodeInfo result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}

    // set bus count
	UInt32 numbusses = 1; // NUM_AUDIO_BUFFERS;
	UInt32 size = sizeof numbusses;
	
    // printf ("set input bus count %lu\n", numbuses);
	
    result = AudioUnitSetProperty (
		mMixer,
		kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0,
		&numbusses, sizeof numbusses
		
	);
    if (result) {
		printf ("AudioUnitSetProperty result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}
	
	for (int i = numbusses; i--;) {
		
		// setup render callback struct
		AURenderCallbackStruct renderCallback;
		renderCallback.inputProc = &renderInput;
		renderCallback.inputProcRefCon = self;
        
        // printf ("set kAudioUnitProperty_SetRenderCallback\n");
        
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback (mGraph, mixerNode, i, &renderCallback);
		// equivalent to AudioUnitSetProperty(mMixer, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, i, &rcbs, sizeof(rcbs));
        if (result) {
			printf ("AUGraphSetNodeInputCallback result %d %08X %4.4s\n",
				(int) result, (int) result, (char*) &result);
			return;
		
		}

        // set input stream format to what we want
        // printf ("get kAudioUnitProperty_StreamFormat\n");
		
        size = sizeof desc;
		result = AudioUnitGetProperty (mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, &desc, &size);
        if (result) {
			printf ("AudioUnitGetProperty result %d %08X %4.4s\n",
				(int) result, (int) result, (char*) &result);
			return;
		
		}

		
		desc.mBitsPerChannel = 16;
		desc.mFormatFlags =	kLinearPCMFormatFlagIsSignedInteger;
		desc.ChangeNumberChannels (1, false);
		desc.mBytesPerFrame = 2;
		desc.mBytesPerPacket = 2;

		desc.ChangeNumberChannels (1, false);

//		desc.ChangeNumberChannels (2, false);
//		desc.mSampleRate = kGraphSampleRate;
		
		// printf ("set kAudioUnitProperty_StreamFormat\n");
		// desc.Print();
        
		result = AudioUnitSetProperty (
			mMixer,
			kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i,
			&desc, sizeof desc
			
		);
        if (result) {
			printf ("AudioUnitSetProperty result %d %08X %4.4s\n",
				(int) result, (int) result, (char*) &result);
			return;
		
		}
		
	}
	
	// set output stream format to what we want
    // printf ("get kAudioUnitProperty_StreamFormat\n");
	
    result = AudioUnitGetProperty (
		mMixer,
		kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0,
		&desc, &size
	
	);
    if (result) {
		printf ("AudioUnitGetProperty result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}
	
	//
	
	desc.ChangeNumberChannels (1, false);						
	desc.mSampleRate = kGraphSampleRate;
	
	//  printf ("set kAudioUnitProperty_StreamFormat\n");
	// desc.Print();
	
	result = AudioUnitSetProperty (
		mMixer,
		kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0,
		&desc, sizeof desc
		
	);
    if (result) {
		printf ("AudioUnitSetProperty result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}
		
    // printf ("AUGraphInitialize\n");
								
    // now that we've set everything up we can initialize the graph, this will also validate the connections
	result = AUGraphInitialize (mGraph);
    if (result) {
		printf ("AUGraphInitialize result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}
	
}

#pragma mark-

// enable or disables a specific bus
- (void) enableInput: (UInt32) inputNum isOn: (AudioUnitParameterValue) isONValue {
    // printf ("BUS %d isON %f\n", (int) inputNum, isONValue);
	
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, inputNum, isONValue, 0);
    if (result) {
		printf ("AudioUnitSetParameter kMultiChannelMixerParam_Enable result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}

}

// sets the input volume for a specific bus
- (void) setInputVolume: (UInt32) inputNum value: (AudioUnitParameterValue) value {
	OSStatus result = AudioUnitSetParameter (
		mMixer,
		kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum,
		fminf (1., fmaxf (0., value)), 0
		
	);
    if (result) {
		printf ("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}
	
}

// sets the overall mixer output volume
- (void) setOutputVolume: (AudioUnitParameterValue) value {
	OSStatus result = AudioUnitSetParameter (
		mMixer,
		kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0,
		fminf (1., fmaxf (0., value)), 0
		
	);
    if (result) {
		printf ("AudioUnitSetParameter kMultiChannelMixerParam_Volume Output result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
		return;
	
	}
	
}

// starts render

- (void) startAUGraph {
	
    // printf ("PLAY\n");
    
	OSStatus result = AUGraphStart (mGraph);
    if (result) {
		printf ("AUGraphStart result %d %08X %4.4s\n",
		(int) result, (int) result, (char*) &result);
		return;
		
	}
	isPlaying = true;
	
}

// stops render

- (void) stopAUGraph {

	// printf ("STOP\n");

    Boolean isRunning = false;
    
    OSStatus result = AUGraphIsRunning (mGraph, &isRunning);
    if (result) {
		printf ("AUGraphIsRunning result %d %08X %4.4s\n",
		(int) result, (int) result, (char*) &result);
		return;
	
	}
    
    if (isRunning) {
        result = AUGraphStop (mGraph);
        if (result) {
			printf ("AUGraphStop result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
			return;
		
		}
        isPlaying = false;
		
    }
	
}

@end
