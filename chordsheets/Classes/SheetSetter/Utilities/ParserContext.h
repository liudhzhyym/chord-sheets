//
//  ParserContext.h
//  ParserContext
//
//  Created by Pattrick Kreutzer on 09.06.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>


@interface ParserContext : NSObject <NSXMLParserDelegate> {
	
	@private
	
	NSXMLParser* parser;
	
	NSMutableArray* contextStack;
	
	NSString* currentElementName;
	NSDictionary* currentElementAttributes;
	NSMutableString* currentText;
	
	@public
	
	BOOL parsingModeOld;
	
}

@property (readonly) NSString* currentElementName;
@property (readonly) NSDictionary* currentElementAttributes;
@property (readonly) NSString* currentText;

- (void) flushCurrentText;

- (id) initWithDocumentURL: (NSURL*) documentURL;
- (id) initWithDocumentPath: (NSString*) documentPath;
- (id) initWithString: (NSString*) documentMarkup;
- (id) initWithData: (NSData*) data;


- (void) registerElement: (NSString*) elementName withTarget: (id) target selector: (SEL) selector;

- (void) pushContext;

- (void) popContext;

- (void) parse;

@end
