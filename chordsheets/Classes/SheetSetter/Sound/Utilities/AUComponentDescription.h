/*
 *  AUComponentDescription.h
 *  GameBase
 *
 *  Created by blinkenlichten on 14.10.09.
 *  Copyright 2009 wysiwyg* software design gmbh.
 *
 */

// a simple wrapper for AudioComponentDescription
class AUComponentDescription : public AudioComponentDescription {

public:
	AUComponentDescription () {
		componentType = 0;
		componentSubType = 0;
		componentManufacturer = 0;
		componentFlags = 0;
		componentFlagsMask = 0;
	
	};
	
			
	AUComponentDescription (OSType inType,
							OSType inSubType,
							OSType inManufacturer = 0,
							unsigned long inFlags = 0,
							unsigned long inFlagsMask = 0) {
		componentType = inType;
		componentSubType = inSubType;
		componentManufacturer = inManufacturer;
		componentFlags = (unsigned int) inFlags;
		componentFlagsMask = (unsigned int) inFlagsMask;
			
	};

	AUComponentDescription (const AudioComponentDescription &inDescription) {
		*(AudioComponentDescription*) this = inDescription;
		
	};
	
};
