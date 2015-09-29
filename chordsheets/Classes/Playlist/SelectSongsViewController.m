//
//  SelectSongsViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 16.01.12.
//  copyright (c) 2012 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "SelectSongsViewController.h"
#import "AppDelegate.h"
#import "SongIndex.h"

@implementation SelectSongsViewController

@synthesize table;
@synthesize letters;
@synthesize playlist;
@synthesize lettersPresent;

- (id)initWithNibName:(NSString *)newNibName playlist:(Playlist *)newPlaylist
{
    self = [super initWithNibName:newNibName bundle:nil];
    
    if (self) {
        [self setPlaylist:newPlaylist];
        self.navigationItem.title = @"Add to Playlist";
        [self setLetters:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) releaseReferences {
	self.playlist = nil;
	self.table = nil;
	self.toolbar = nil;
	self.statusBarBackground = nil;
	
    [letters release];
	[lettersPresent release];
	
}

- (void) dealloc {
	[self releaseReferences];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	table.contentInset = UIEdgeInsetsMake (21, 0, self.toolbar.bounds.size.height, 0);
	table.scrollIndicatorInsets = UIEdgeInsetsMake (21, 0, self.toolbar.bounds.size.height, 0);
	
    [self setAllSongsSelected:NO];
	
}

- (void) viewWillAppear: (BOOL) animated {
	[super viewWillAppear:animated];
	
	[self reactToLightsOutModeChange];
	
}

- (void)reactToLightsOutModeChange
{
	
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
	UITableView* _table = self.table;
    if (isLightsOut) {
        _table.backgroundColor = [UIColor colorWithWhite: .05f alpha: 1];
        _table.separatorColor = [UIColor colorWithWhite: .5 alpha: 1];
		
		_table.sectionIndexColor = appDelegate.tintColor;
		_table.sectionIndexBackgroundColor = _table.backgroundColor;
		_table.sectionIndexTrackingBackgroundColor = appDelegate.barTintColor;
		
		_table.indicatorStyle = UIScrollViewIndicatorStyleWhite;
		
		self.statusBarBackground.backgroundColor = appDelegate.barTintColor;
		
	} else {
        _table.backgroundColor = [UIColor colorWithWhite: 1 alpha: 1];
        _table.separatorColor = [UIColor colorWithWhite: .5 alpha: .5];
		
		_table.sectionIndexColor = [UIColor colorWithWhite: .5f alpha: 1];
		_table.sectionIndexBackgroundColor = nil;
		_table.sectionIndexTrackingBackgroundColor = nil;
		
		_table.indicatorStyle = UIScrollViewIndicatorStyleBlack;
		
		self.statusBarBackground.backgroundColor = [UIColor colorWithWhite: (CGFloat) .975 alpha: (CGFloat) .95];
		
    }
	
	UIToolbar* toolbar = self.toolbar;
	toolbar.barTintColor = appDelegate.barTintColor;
	toolbar.tintColor = appDelegate.tintColor;
	
}

-(UIStatusBarStyle) preferredStatusBarStyle {
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
	return isLightsOut ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
	
}

- (void) selectAll: (id) sender {
	[self setAllSongsSelected: YES];
	
}

- (void) deselectAll: (id) sender {
	[self setAllSongsSelected: NO];
	
}

- (void) setAllSongsSelected:(BOOL)newSelected {
    for (SongIndex *tempIndex in [[self playlist] songs]) {
        [[tempIndex song] setSelected:newSelected];
    }
    
    [table reloadData];
}

- (void) setSongAtIndexPath:(NSIndexPath *)indexPath selected:(BOOL) newSelected {
    UITableViewCell *cell = [table cellForRowAtIndexPath:indexPath];
    
    if (newSelected) {
        [[cell imageView] setImage:[UIImage imageNamed:@"IsSelected.png"]];
    }
    else {
        [[cell imageView] setImage:[UIImage imageNamed:@"NotSelected.png"]];
    }
    
    NSString *character = [[self lettersPresent] objectAtIndex:[indexPath section]];
    
    NSUInteger numEntries = 0;
    
    for (Song *song in [[self playlist] getSongsSortedByAttribute:@"title" ascending:YES]) {                
        if (![character isEqualToString:@"#"]) {
            if ([[[song title] substringToIndex:1] isEqualToString:character]) {
                if (numEntries == [indexPath row]) {
                    [song setSelected:newSelected];
                    break;
                }
                
                numEntries++;
            }
        }
        else {
            NSString *firstLetterOfSortKey = [[song title] substringWithRange:NSMakeRange(0, 1)];
            NSRange range = [letters rangeOfString : firstLetterOfSortKey];
            
            BOOL isNotALetter = (range.location == NSNotFound);
            
            if ([[song title] characterAtIndex:0] == '#' || isNotALetter) {
                if (numEntries == [indexPath row]) {
                    [song setSelected:newSelected];
                    break;
                }
                
                numEntries++;
            }
        }
    }
}

#pragma mark - Methods for creating the table

- (void)determineSongIndexLettersPresent
{
    NSMutableDictionary *tempLettersPresent = [NSMutableDictionary dictionaryWithCapacity:5];
    
    for (SongIndex *tempIndex in [[self playlist] songs]) {
        NSString *firstTitleLetter = [[[tempIndex song] title] substringToIndex:1];
        
        if ([[self letters] rangeOfString:firstTitleLetter].location != NSNotFound) {
            [tempLettersPresent setValue:[NSNumber numberWithBool:YES] forKey:firstTitleLetter];
        }
        else {
            [tempLettersPresent setValue:[NSNumber numberWithBool:YES] forKey:@"#"];
        }
    }
    
    [self setLettersPresent:[[tempLettersPresent allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    [self determineSongIndexLettersPresent];
    return [[self lettersPresent] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    [self determineSongIndexLettersPresent];
    return [self lettersPresent];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![self playlist]) {
        return 0;
    }
    
    NSUInteger numEntries = 0;
    
    NSString *character = [lettersPresent objectAtIndex:section];
    
    NSString *sortKey;
    
    for (SongIndex *tempIndex in [[self playlist] songs]) {
        sortKey = [[tempIndex song] title];
        
        if (![character isEqualToString:@"#"]) {
            if ([[sortKey substringToIndex:1] isEqualToString:character]) {
                numEntries++;
            }
        }
        else {
            NSString *firstLetterOfSortKey = [sortKey substringToIndex:1];
            NSRange range = [letters rangeOfString : firstLetterOfSortKey];
            
            BOOL isNotALetter = (range.location == NSNotFound);
            
            if ([sortKey characterAtIndex:0] == '#' || isNotALetter) {
                numEntries++;
            }
        }
    }
    
    return numEntries;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self lettersPresent] objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
		cell.backgroundColor = [UIColor clearColor];
		
		UIView* selectionBackgroundView = [[[UIView alloc] init] autorelease];
		selectionBackgroundView.backgroundColor = [UIColor colorWithWhite: .5 alpha: .25];
		cell.selectedBackgroundView = selectionBackgroundView;
		
    }
    
    NSUInteger numEntries = 0;
    
    NSString *indexCharacter = [[self lettersPresent] objectAtIndex:[indexPath section]];
    
    for (Song *song in [[self playlist] getSongsSortedByAttribute:@"title" ascending:YES]) {                
        BOOL isNotALetter = ([letters rangeOfString:[[song title] substringToIndex:1]].location == NSNotFound);
        
        if ([[[song title] substringToIndex:1] isEqualToString:indexCharacter] || ([indexCharacter isEqualToString:@"#"] && isNotALetter)) {
            if (numEntries == [indexPath row]) {
                // append the index to the title if this songs title is not unique
                NSString *songTitle  = [song title];
				NSRange stringRange = {0, MIN([songTitle length], 15)};
				NSMutableString* completeSongTitle;
				
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && stringRange.length == 15) {
					completeSongTitle = [[songTitle substringWithRange:stringRange] mutableCopy];
					[completeSongTitle appendString:@"…"];
				}
				else {
					completeSongTitle = [songTitle mutableCopy];
				}
				
                if ([[song nonUniqueTitleIndex] intValue] > 0) {
                    [completeSongTitle appendString:[NSString stringWithFormat:@" (%d)", [[song nonUniqueTitleIndex] intValue]]];
                }
                
				// get the songs key signature
				
				NSString *keySignatureXmlOpenTag = @"<keysignature>";
				NSString *keySignatureXmlCloseTag = @"</keysignature>";
				
				NSRange openTagRange = [[song content] rangeOfString:keySignatureXmlOpenTag];
				NSRange closeTagRange = [[song content] rangeOfString:keySignatureXmlCloseTag];
				
				unsigned long start = openTagRange.location + openTagRange.length;
				unsigned long finish = closeTagRange.location;
				long length = finish - start;
				
				NSRange keySignatureRange = NSMakeRange(start, length);
				
				NSString *keySignatureString = [[song content] substringWithRange:keySignatureRange];
				
				//NSLog(@"%@", keySignatureString);
				
				keySignatureString = [keySignatureString stringByReplacingOccurrencesOfString:@"-" withString:@"m"];
				
				[completeSongTitle appendString:[NSString stringWithFormat:@" · %@", keySignatureString]];

                // set text and detailtext of this cell depending on sorting mode
                if ([[song selfComposed] boolValue]) {
                    if ([[song cover] boolValue]) {
                        [cell.textLabel setText:[NSString stringWithFormat:@"★✎ %@", completeSongTitle]];
                    }
                    else {
                        [cell.textLabel setText:[NSString stringWithFormat:@"★ %@", completeSongTitle]];
                    }
                }
                else if ([[song cover] boolValue]) {
                    [cell.textLabel setText:[NSString stringWithFormat:@"✎ %@", completeSongTitle]];
                }
                else {
                    [cell.textLabel setText:completeSongTitle];
                }
                
                [cell.detailTextLabel setText:[song artist]];
				
                if (![song isSelected]) {
                    [[cell imageView] setImage:[UIImage imageNamed:@"NotSelected.png"]];
                }
                else {
                    [[cell imageView] setImage:[UIImage imageNamed:@"IsSelected.png"]];
                }
				
                [completeSongTitle release];
                
                break;
            }
            
            numEntries++;
        }
    }
    
    BOOL lightsOut = [(AppDelegate *)[[UIApplication sharedApplication] delegate] isLightsOutModeEnabled];
    
    if (!lightsOut) {
        [cell.textLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
        [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1]];
    }
    else {
        [cell.textLabel setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [[cell detailTextLabel] setTextColor:[UIColor colorWithRed:.4f green:.4f blue:.4f alpha:1]];
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cellIdentifier release];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setSongAtIndexPath:indexPath selected:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setSongAtIndexPath:indexPath selected:NO];
}

#pragma mark - IBAction methods

- (IBAction)clickSelectAll:(id)sender
{
    [self setAllSongsSelected:YES];
}

- (IBAction)clickDeselectAll:(id)sender
{
    [self setAllSongsSelected:NO];
}

@end
