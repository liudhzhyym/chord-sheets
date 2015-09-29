//
//  NSMutableString_XMLComposing.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>


@interface NSMutableString (XMLComposing)

- (void) appendXMLNodeWithName: (NSString*) name;
- (void) appendXMLNodeWithName: (NSString*) name textContent: (NSString*) textContent;
- (void) appendXMLNodeWithName: (NSString*) name attributes: (NSDictionary*) attributes;

@end
