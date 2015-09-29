//
//  ParserContext.m
//  ParserContext
//
//  Created by Pattrick Kreutzer on 09.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import "ParserContext.h"

#import "Invocation.h"



@implementation ParserContext

- (id) initWithDocumentURL: (NSURL*) documentURL {
	NSData* data = [NSData dataWithContentsOfURL: documentURL];
	if (data)
		self = [self initWithData: data];
	return self;
	
}

- (id) initWithDocumentPath: (NSString*) documentPath {
	NSData* data = [NSData dataWithContentsOfFile: documentPath];
	if (data)
		self = [self initWithData: data];
	return self;
	
}

- (id) initWithString: (NSString*) documentMarkup {
	self = [self initWithData: [documentMarkup dataUsingEncoding: NSUTF8StringEncoding]];
	return self;
	
}

- (id) initWithData: (NSData*) data {
	if ((self = [super init])) {
		parser = [[NSXMLParser alloc] initWithData: data];
		parser.delegate = self;
		
		contextStack = [[NSMutableArray alloc] init];
		[self pushContext];
		
	}
	return self;
	
}

- (void) pushContext {
	NSMutableDictionary* context = [NSMutableDictionary dictionary];
	[contextStack addObject: context];
	
	currentText = [NSMutableString string];
	[context setObject: currentText forKey: @"__CURRENT_TEXT__"];
	
	// NSLog (@"> pushed. stack length is %i", [contextStack count]);
	
}

- (void) registerElement: (NSString*) elementName withTarget: (id) target selector: (SEL) selector {
	NSDictionary* context = [contextStack lastObject];
	
	Invocation* invocation = [[Invocation alloc] initWithTarget: target selector: selector context: self];
	[context setValue: invocation forKey: elementName];
	[invocation release];
	
}

- (void) popContext {
	[contextStack removeLastObject];
	
	NSDictionary* context = [contextStack lastObject];
	currentText = [context objectForKey: @"__CURRENT_TEXT__"];
	
	// NSLog (@"< popped. stack length is %i", [contextStack count]);
	
}

- (void) popContext: (ParserContext*) _self {
	[self popContext];
	
}

- (NSString*) currentElementName {
	return currentElementName;
	
}

- (void) setCurrentElementName: (NSString*) elementName {
	if (currentElementName)
		[currentElementName autorelease];
	
	currentElementName = [elementName copy];
	
}

- (NSDictionary*) currentElementAttributes {
	return currentElementAttributes;
	
}

- (void) setCurrentElementAttributes: (NSDictionary*) attributes {
	if (currentElementAttributes)
		[currentElementAttributes autorelease];
	
	currentElementAttributes = [attributes copy];
	
}

- (void) appendToCurrentText: (NSString*) string {
	[currentText appendString: string];
	
}

- (NSString*) currentText {
	return [currentText stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
}

- (void) flushCurrentText {
	[currentText setString: @""];
	
}

- (void) parser: (NSXMLParser*) parser didStartElement: (NSString*) elementName namespaceURI: (NSString*) namespaceURI qualifiedName: (NSString*) qualifiedName attributes: (NSDictionary*) attributeDict {
	NSDictionary* context = [contextStack lastObject];
	
	// NSLog (@"found %@", elementName);
	
	Invocation* invocation = [context valueForKey: elementName];
	if (!invocation)
		invocation = [context valueForKey: @"*"];
	
	if (invocation) {
		// NSLog (@"found handler for %@.", elementName);
		
		[self pushContext];
		[self registerElement: [NSString stringWithFormat: @"__/%@__", elementName]
			withTarget: self selector: @selector (popContext:)];
		[self setCurrentElementName: elementName];
		[self setCurrentElementAttributes: attributeDict];
		
		[invocation invoke];
		
	}
	
}

- (void) parser: (NSXMLParser*) parser foundCharacters: (NSString*) string {
	// NSLog (@"found characters %@.", string);
	[self appendToCurrentText: string];
	
}

- (void) parser: (NSXMLParser*) parser didEndElement: (NSString*) elementName namespaceURI: (NSString*) namespaceURI qualifiedName: (NSString*) qName {
	NSDictionary* context = [contextStack lastObject];
	
	Invocation* invocation;
	
	NSString* elementKey = [NSString stringWithFormat: @"/%@", elementName];
	invocation = [context valueForKey: elementKey];
//	if (!invocation)
//		invocation = [context valueForKey: @"/*"];
	
	if (invocation) {
		// NSLog (@"found handler for %@.", elementKey);
		[invocation invoke];
		
	}

	invocation = [context valueForKey: @"__TEXT__"];
	if (invocation && [[self currentText] length]) {
		// NSLog (@"found handler for text %@.", [self currentText]);
		[invocation invoke];
		
	} else if ([[self currentText] length]) {
		// NSLog (@"discarding text %@.", [self currentText]);
		
	}
	
	invocation = [context valueForKey: @"__FINISH__"];
	if (invocation)
		[invocation invoke];
	
	elementKey = [NSString stringWithFormat: @"__/%@__", elementName];
	invocation = [context valueForKey: elementKey];
	if (invocation) {
		// NSLog (@"found handler for %@.", elementKey);
		[invocation invoke];
		
	}
	
	elementKey = [NSString stringWithFormat: @"//%@", elementName];
	invocation = [context valueForKey: elementKey];
	if (invocation) {
		// NSLog (@"found handler for %@.", elementKey);
		[invocation invoke];
		
	}
		
}

- (void) parse {
	[parser parse];
	
}

- (void) dealloc {
	if (currentElementName)
		[currentElementName release];
	if (currentElementAttributes)
		[currentElementAttributes release];
	
	[contextStack release];
	[parser release];
	[super dealloc];
	
}

@end
