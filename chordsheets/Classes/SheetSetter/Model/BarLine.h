//
//  BarLine.h
//  ChordPlayer
//
//  Created by Pattrick Kreutzer on 26.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <Foundation/Foundation.h>


extern NSString *BAR_LINE_TYPE_SINGLE;
extern NSString *BAR_LINE_TYPE_DOUBLE;

extern NSString *BAR_LINE_REHEARSAL_MARK_SEGNO;
extern NSString *BAR_LINE_REHEARSAL_MARK_CODA;
extern NSString *BAR_LINE_REHEARSAL_MARK_DA_CAPO;
extern NSString *BAR_LINE_REHEARSAL_MARK_DAL_SEGNO;
extern NSString *BAR_LINE_REHEARSAL_MARK_FINE;

extern NSString *BAR_LINE_REHEARSAL_LINE_WRAP;


@interface BarLine : NSObject <NSCoding, NSCopying> {
	
	@protected
	
	NSString* type;
	int repeatCount;
	
	@public
	
	NSMutableSet* rehearsalMarks;
	
}

@property (nonatomic, readwrite, retain) NSString* type;
@property (nonatomic, readwrite) int repeatCount;

- (void) addRehearsalMark: (NSString*) rehearsalMark;
- (void) removeRehearsalMark: (NSString*) rehearsalMark;
- (void) removeAllRehearsalMarks;
@property (nonatomic, readonly) NSSet* rehearsalMarks;
- (NSArray*) orderedRehearsalMarks;

- (BOOL) isDefault;
- (NSString*) toXMLString;
- (NSString*) innerXMLString;

@end
