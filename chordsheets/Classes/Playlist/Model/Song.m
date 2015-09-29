//
//  Song.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 08.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "Song.h"
#import "SongIndex.h"


@implementation Song

@dynamic artist;
@dynamic author;
@dynamic content;
@dynamic cover;
@dynamic originalArtist;
@dynamic originalTitle;
@dynamic selfComposed;
@dynamic title;
@dynamic nonUniqueTitleIndex;
@dynamic indices;

@synthesize compositionPrototype;
@synthesize selected;

- (NSString *)createExportFileName
{
    NSMutableString *name = [[[NSMutableString alloc] initWithCapacity:10] autorelease];
    
    [name appendString:[self title]];
    [name appendString:@" - "];
    [name appendString:[self artist]];
     [name appendString:@".ibs"];
    
    return name;
}

@end
