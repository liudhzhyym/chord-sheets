//
//  Song.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 08.12.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SongIndex;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString *artist;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSNumber *cover;
@property (nonatomic, retain) NSString *originalArtist;
@property (nonatomic, retain) NSString *originalTitle;
@property (nonatomic, retain) NSNumber *selfComposed;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSNumber *nonUniqueTitleIndex;
@property (nonatomic, retain) NSSet *indices;

@property (nonatomic, assign, getter = isCompositionPrototype) BOOL compositionPrototype;
@property (nonatomic, assign, getter = isSelected) BOOL selected;

- (NSString *)createExportFileName;

@end

@interface Song (CoreDataGeneratedAccessors)

- (void)addIndicesObject:(SongIndex *)value;
- (void)removeIndicesObject:(SongIndex *)value;
- (void)addIndices:(NSSet *)values;
- (void)removeIndices:(NSSet *)values;

@end
