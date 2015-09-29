//
//  Importer.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 25.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "Importer.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Song.h"
#import "SongIndex.h"
#import "Playlist.h"

@implementation Importer

@synthesize objectContext;
@synthesize currentNodeName;
@synthesize title;
@synthesize artist;

- (id) initWithObjectContext:(NSManagedObjectContext *)newContext {
    self = [super init];
    
    if (self) {
        [self setObjectContext:newContext];
    }
    
    return self;
}

- (void)dealloc
{
	self.objectContext = nil;
	self.currentNodeName = nil;
	
	self.title = nil;
	self.artist = nil;
	
    [super dealloc];
	
}

- (void) importAllSheets
{
    NSMutableArray *dirContents = [[[NSBundle mainBundle] pathsForResourcesOfType:@".xml" inDirectory:nil] mutableCopy];
        
    for (NSString *fileName in dirContents) {
        if ([fileName rangeOfString:@"New Song - Unknown Artist"].location != NSNotFound) {
            continue;
        }
        
        [self readSongWithName:fileName];
    }
    
    [dirContents release];
}

- (Song *)readSongWithName:(NSString *)filename
{
    return [self readSongWithData:[NSData dataWithContentsOfFile:filename]];
}

- (Song *)readSongWithData:(NSData *)data
{
    [self setTitle:[NSMutableString stringWithCapacity:5]];
    [self setArtist:[NSMutableString stringWithCapacity:5]];
    
    NSXMLParser *newParser = [[NSXMLParser alloc] initWithData:data];
        
    [newParser setDelegate:self];
    [newParser setShouldProcessNamespaces:NO];
    [newParser setShouldReportNamespacePrefixes:NO];
    [newParser setShouldResolveExternalEntities:NO];
        
    [newParser parse];
    
    Song *newSong = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:[self objectContext]];
    [newSong setValue:[self title] forKey:@"title"];
    [newSong setValue:[self artist] forKey:@"artist"];
    
    NSString *sheet_content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [newSong setValue:sheet_content forKey:@"content"];
    [sheet_content release];
    
    [newSong setValue:[NSNumber numberWithInt:0] forKey:@"nonUniqueTitleIndex"];
    
    [newParser release];
    [self saveContext];
    
    return newSong;
}

- (void) saveContext
{
    [[self objectContext] save:nil];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqualToString:@"title"] || [elementName isEqualToString:@"artist"]) {
        [self setCurrentNodeName:elementName];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [self setCurrentNodeName:@""];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if([currentNodeName isEqualToString:@"title"]) {
        [[self title] appendString:string];
    }
    
    if([currentNodeName isEqualToString:@"artist"]) {
        [[self artist] appendString:string];
    }
}

@end
