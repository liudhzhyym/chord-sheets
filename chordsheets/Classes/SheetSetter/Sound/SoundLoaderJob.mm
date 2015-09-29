//
//  SoundLoaderJob.m
//  GameBase
//
//  Created by blinkenlichten on 14.10.09.
//  Copyright 2009 wysiwyg* software design gmbh.
//

#import "SoundLoaderJob.h"

#import "SoundMixer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

#import "CAStreamBasicDescription.h"
#import "CADebugMacros.h"
#import "CAXException.h"


@implementation SoundLoaderJob


- (void) load {
	[super load];
	[self performSelectorInBackground: @selector (backgroundLoad) withObject: nil];
	
}

- (void) backgroundLoad {

	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	NSString* source = [[NSBundle mainBundle]
		pathForResource: [path stringByDeletingPathExtension] ofType: [path pathExtension]];
	CFURLRef sourceURL = CFURLCreateWithFileSystemPath (
		kCFAllocatorDefault, (CFStringRef) source, kCFURLPOSIXPathStyle, false );
	
	ExtAudioFileRef xafref = 0;
	
	// open one of the two source files
	OSStatus result = ExtAudioFileOpenURL (sourceURL, &xafref);
    
	if (result || !xafref) {
		printf ("ExtAudioFileOpenURL result %d %08X %4.4s\n",(int) result, (int) result, (char*) &result);
        [pool release];
        CFRelease(sourceURL);
		return;
	}
	
	// get the file data format, this represents the file's actual data format
	CAStreamBasicDescription clientFormat;
	UInt32 propSize = sizeof clientFormat;
	
	result = ExtAudioFileGetProperty (
		xafref,
		kExtAudioFileProperty_FileDataFormat,
		&propSize, &clientFormat
		
	);
	if (result) {
		printf ("ExtAudioFileGetProperty kExtAudioFileProperty_FileDataFormat result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
        [pool release];
        CFRelease(sourceURL);
		return;
	}

	const Float64 kGraphSampleRate = 44100.0;
	
	// set the client format to be what we want back
	double rateRatio = kGraphSampleRate / clientFormat.mSampleRate;
	clientFormat.mSampleRate = kGraphSampleRate;
	clientFormat.SetAUCanonical (1, true);
	
	
	clientFormat.mFormatID = 'lpcm';

	clientFormat.mFormatFlags =
		kLinearPCMFormatFlagIsSignedInteger |
		kAudioFormatFlagIsNonInterleaved;
	
	clientFormat.mBytesPerPacket = 2;
	clientFormat.mFramesPerPacket = 1;
	
	clientFormat.mBytesPerFrame = 2;
	clientFormat.mChannelsPerFrame = 1;

	clientFormat.mBitsPerChannel = 16;

	clientFormat.NormalizeLinearPCMFormat (clientFormat);
	// clientFormat.Print ();

	
	propSize = sizeof clientFormat;
	result = ExtAudioFileSetProperty (
		xafref,
		kExtAudioFileProperty_ClientDataFormat,
		propSize, &clientFormat
		
	);
    
	if (result) {
		printf ("ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
        [pool release];
        CFRelease(sourceURL);
		return;
	}
	
	// get the file's length in sample frames
	UInt64 numFrames = 0;
	propSize = sizeof numFrames;
	result = ExtAudioFileGetProperty (
		xafref,
		kExtAudioFileProperty_FileLengthFrames,
		&propSize, &numFrames
		
	);
    
	if (result) {
		printf ("ExtAudioFileGetProperty kExtAudioFileProperty_FileLengthFrames result %d %08X %4.4s\n",
			(int) result, (int) result, (char*) &result);
        [pool release];
        CFRelease(sourceURL);
		return;
	}
	
	numFrames = (UInt32) (numFrames * rateRatio); // account for any sample rate conversion
	
	SoundBuffer* soundBuffer = (SoundBuffer*) malloc (sizeof (SoundBuffer));
	data = soundBuffer;
	
	// set up our buffer
	
	soundBuffer -> numFrames = (UInt32) numFrames;
	soundBuffer -> asbd = clientFormat;
	
	UInt32 samples = (UInt32) numFrames * soundBuffer -> asbd.mChannelsPerFrame;
	soundBuffer -> data = (SInt16 *) calloc (samples, sizeof (SInt16));
	soundBuffer -> sampleNum = 0;
	
	// set up a AudioBufferList to read data into
	AudioBufferList bufList;
	bufList.mNumberBuffers = 1;
	bufList.mBuffers [0].mNumberChannels = 1;
	bufList.mBuffers [0].mData = soundBuffer -> data;
	bufList.mBuffers [0].mDataByteSize = samples * sizeof (SInt16);
	
	// perform a synchronous sequential read of the audio data out of the file into our allocated data buffer
	UInt32 numPackets = (UInt32) numFrames;
	result = ExtAudioFileRead (xafref, &numPackets, &bufList);
    
	if (result) {
		printf ("ExtAudioFileRead result %d %08X %4.4s\n",
		(int) result, (int) result, (char*) &result); 
		free (soundBuffer -> data);
		soundBuffer -> data = 0;
        [pool release];
        CFRelease(sourceURL);
		return;
	}
	
	// close the file and dispose the ExtAudioFileRef
	ExtAudioFileDispose (xafref);
	
	CFRelease (sourceURL);
	
	[self performSelectorOnMainThread: @selector (backgroundReturn) withObject: nil
		waitUntilDone: NO];
	
	[pool release];
	
}

- (void) backgroundReturn {
	state = STATE_DONE;
	[self dispatchEvent: @"complete"];
	
}

- (void) dealloc {
	
	NSLog (@"destroyed sound %@", path);

	free (((SoundBuffer*) data) -> data);
	free (data);
	
	[super dealloc];

}


@end
