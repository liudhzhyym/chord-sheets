//
//  Importer.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 25.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Playlist.h"
#import "Song.h"

@interface Importer : NSObject <NSXMLParserDelegate>

@property (nonatomic, retain) NSManagedObjectContext *objectContext;
@property (nonatomic, retain) NSString *currentNodeName;
@property (nonatomic, retain) NSMutableString *title;
@property (nonatomic, retain) NSMutableString *artist;

- (id) initWithObjectContext:(NSManagedObjectContext *)newContext;
- (void) importAllSheets;
- (Song *)readSongWithName:(NSString *)filename;
- (Song *)readSongWithData:(NSData *)data;
- (void) saveContext;

@end
