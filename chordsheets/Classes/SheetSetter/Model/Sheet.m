//
//  Sheet.m
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "Sheet.h"

#import "Bar.h"

#import "NSString_XMLEscaping.h"
#import "NSMutableString_XMLComposing.h"


@implementation Sheet

// construction

- (id) init {
	if ((self = [super init])) {
		bars = [[NSMutableArray alloc] init];
		
	}
	return self;
	
}

- (id) initWithCoder: (NSCoder*) coder {
	if ((self = [super init])) {
		title = [[coder decodeObjectForKey: @"title"] retain];
		artist = [[coder decodeObjectForKey: @"artist"] retain];
		composer = [[coder decodeObjectForKey: @"composer"] retain];
		copyright = [[coder decodeObjectForKey: @"copyright"] retain];
		
		tempo = [coder decodeFloatForKey: @"tempo"];
		
		if (bars)
			[bars release];
		bars = [[coder decodeObjectForKey: @"bars"] mutableCopy];
		
	}
	return self;
	
}

- (id) copyWithZone: (NSZone*) zone {
	Sheet* instance = [[[self class] allocWithZone: zone] init];
	
	instance -> title = [self.title copyWithZone: zone];
	instance -> artist = [self.artist copyWithZone: zone];
	instance -> composer = [self.composer copyWithZone: zone];
	instance -> copyright = [self.copyright copyWithZone: zone];
	
	instance -> tempo = self.tempo;
	
	//instance -> bars = [self.bars mutableCopyWithZone: zone];
	if (instance -> bars)
		[instance -> bars release];
    instance -> bars = [[NSMutableArray alloc] initWithArray:[self bars] copyItems:YES];
	
	return instance;
	
}

#pragma mark -
#pragma mark XML parsing

- (void) registerWithParserContext: (ParserContext*) parserContext {
	
	[parserContext registerElement: @"description"
		withTarget: self selector: @selector (enterDescription:)];
	
	[parserContext registerElement: @"notation"
		withTarget: self selector: @selector (processNotation:)];
	
}

- (void) enterDescription: (ParserContext*) parserContext {
	//NSLog (@"description");
	
	[parserContext registerElement: @"*"
		withTarget: self selector: @selector (processDescriptionNode:)];
	[parserContext registerElement: @"tempo"
		withTarget: self selector: @selector (processTempoNode:)];
	[parserContext registerElement: @"__FINISH__"
		withTarget: self selector: @selector (finishSheetProperties:)];
	
}

- (void) processDescriptionNode: (ParserContext*) parserContext {
	[parserContext registerElement: @"__TEXT__"
		withTarget: self selector: @selector (processDescriptionText:)];
	
}

- (void) processDescriptionText: (ParserContext*) parserContext {
	
	NSString* elementName = [parserContext currentElementName];
	NSString* text = [parserContext currentText];
	
	//NSLog (@"%@: %@", elementName, text);
	
	if ([elementName isEqualToString: @"title"])
		self.title = text;
		
	else if ([elementName isEqualToString: @"artist"])
		self.artist = text;
	
	else if ([elementName isEqualToString: @"composer"])
		self.composer = text;
	
	else if ([elementName isEqualToString: @"copyright"])
		self.copyright = text;
	
}

- (void) processTempoNode: (ParserContext*) parserContext {

	//NSString* elementName = [parserContext currentElementName];
	NSDictionary* attributes = [parserContext currentElementAttributes];
	
	//NSLog (@"%@: %@", elementName, [attributes valueForKey: @"bpm"]);
			
	float nodeTempo = [[attributes objectForKey: @"bpm"] floatValue];
	if (nodeTempo <= 0)
		nodeTempo = 100;
	
	self.tempo = nodeTempo;
	
}

- (void) finishSheetProperties: (ParserContext*) parserContext {
	
	
}

- (void) processNotation: (ParserContext*) parserContext {
	//NSLog (@"notation");
	
	[parserContext registerElement: @"bar"
		withTarget: self selector: @selector (processBar:)];
	[parserContext registerElement: @"break"
		withTarget: self selector: @selector (processBreak:)];
	
}

- (void) processBar: (ParserContext*) parserContext {
	// NSLog (@"bar");
	
	Bar* bar = [[Bar alloc] init];
	currentProcessingBar = bar;
	
	[bars addObject: bar];
	[bar registerWithParserContext: parserContext];
	
	[bar release];
	
	[parserContext registerElement: @"//bar"
		withTarget: self selector: @selector (cleanUpBar:)];
	
}

- (void) cleanUpBar: (ParserContext*) parserContext {
	Bar* bar = currentProcessingBar;
	if (bar.openingBarLine.timeSignature)
		currentTimeSignature = bar.openingBarLine.timeSignature;
	
	[bar adaptForTimeSignature: currentTimeSignature];
	//NSLog(@"bar %@", [bar toXMLString]);
	
}

- (void) processBreak: (ParserContext*) parserContext {
	currentProcessingBar.closingBarLine.wrapsAfterBar = YES;
	
}

#pragma mark -
#pragma mark Properties

- (NSString*) title {
	return title;
	
}

- (void) setTitle: (NSString*) _title {
	if (title == _title)
		return;
	
	[title release];
	title = [_title retain];
	
}

- (NSString*) artist {
	return artist;
	
}

- (void) setArtist: (NSString*) _artist {
	if (artist == _artist)
		return;
	
	[artist release];
	artist = [_artist retain];
	
}

- (NSString*) composer {
	return composer;
	
}

- (void) setComposer: (NSString*) _composer {
	if (composer == _composer)
		return;
	
	[composer release];
	composer = [_composer retain];
	
}

- (NSString*) copyright {
	return copyright;
	
}

- (void) setCopyright: (NSString*) _copyright {
	if (copyright == _copyright)
		return;
	
	[copyright release];
	copyright = 
		[[_copyright stringByReplacingOccurrencesOfString: @"edited by " withString: @""] retain];
	
}

- (float) tempo {
	return tempo;
	
}

- (void) setTempo: (float) _tempo {
	tempo = _tempo;
	
}

- (NSArray*) bars {
	return bars;
	
}

- (void) setBars: (NSArray*) _bars {
	if (bars == _bars)
		return;
	
	[bars release];
	bars = [_bars mutableCopy];
	
}

// serialization

- (void) encodeWithCoder: (NSCoder*) coder {
	[coder encodeObject: title forKey: @"title"];
	[coder encodeObject: artist forKey: @"artist"];
	[coder encodeObject: composer forKey: @"composer"];
	[coder encodeObject: copyright forKey: @"copyright"];
	
	[coder encodeFloat: tempo forKey: @"tempo"];
	
	[coder encodeObject: bars forKey: @"bars"];
	
}

- (NSString*) toXMLString {
	NSMutableString* buffer = [NSMutableString string];
	
	[buffer appendString: @"<sheet>"];
	[buffer appendString: @"<description>"];
	[buffer appendXMLNodeWithName: @"title" textContent: title];
	[buffer appendXMLNodeWithName: @"artist" textContent: artist];
	[buffer appendXMLNodeWithName: @"composer" textContent: composer];
	[buffer appendXMLNodeWithName: @"copyright" textContent: copyright];
	[buffer appendString: [NSString stringWithFormat: @"<tempo bpm=\"%f\"/>", tempo]];
	[buffer appendString: @"</description>"];
	
	[buffer appendString: @"<notation>"];
	for (Bar* bar in bars)
		[buffer appendString: [bar toXMLString]];
	
	[buffer appendString: @"</notation>"];
	
	[buffer appendString: @"</sheet>"];
	
	return buffer;

}

// deallocation

- (void) dealloc {
	
	if (title)
		[title release];
	if (artist)
		[artist release];
	if (composer)
		[composer release];
	if (copyright)
		[copyright release];
	
	if (bars)
		[bars release];
	
	[super dealloc];
	
}

@end


@implementation Sheet (Editing)

/*
- (BOOL) didChange {
	return YES;
	
}
*/

@end
