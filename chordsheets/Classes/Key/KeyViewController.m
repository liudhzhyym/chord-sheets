//
//  KeyViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 04.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "KeyViewController.h"
#import <math.h>
#import <QuartzCore/QuartzCore.h>
#import "KeyButton.h"
#import "SheetSetterViewController.h"
#import "SheetScrollView.h"

#import "BarLayer.h"
#import "OpeningBarLineLayer.h"
#import "ClosingBarLineLayer.h"

@implementation KeyViewController

@synthesize sheetSetterViewController;
@synthesize keysetName;
@synthesize toolBar;
@synthesize keyDictionary;
@synthesize keySignature;
@synthesize keySignatureBeforeEditing;

- (id)initWithKeyConfig:(NSString *)newKeysetName sheetSetterViewController:(SheetSetterViewController *)newSheetSetterViewController
{
    self = [super init];
    
    if (self) {
        [self setSheetSetterViewController:newSheetSetterViewController];
        [self setKeysetName:newKeysetName];
        [self setKeyDictionary:[NSMutableDictionary dictionaryWithCapacity:10]];
        [[self view] setOpaque:YES];
        
        // load the plist config file
        
        NSDictionary *root = [self readKeyConfigWithName:newKeysetName];
        
        // set view dimensions
        
        CGFloat width = [[[self sheetSetterViewController] view] frame].size.width;
        CGFloat height = [[[root objectForKey:@"View"] objectForKey:@"h"] floatValue];
        self.view.frame = CGRectMake(0, 0, width, height);
        
        // set up the toolbar
        
        UIToolbar *toolbar = [self createToolbarWithWidth: (float)width Height:44];
        
        float toolbar_y = [[[[root objectForKey:@"Header"] objectForKey:@"Position"] objectForKey:@"y"] floatValue];
        
        CGRect toolbarFrame = toolbar.frame;
        toolbarFrame.origin.y = toolbar_y;
        toolbar.frame = toolbarFrame;
        
        [self setToolBar:toolbar];
        [[self view] addSubview:[self toolBar]];
        
        // get the config info for the buttons on the toolbar
        
        NSDictionary *toolbarButtonDict = [[root objectForKey:@"Header"] objectForKey:@"Buttons"];
        NSString *headerTitle = [[[[root objectForKey:@"Header"] objectForKey:@"Title"] objectForKey:@"Label"] objectForKey:@"Text"];
        
        // create the BarButtonItems and add them to toolbar
        [[self toolBar] setItems:[self createToolbarItemsWithTitle:headerTitle properties:toolbarButtonDict] animated:NO];
        
        // get the config data for the panel
        
        NSDictionary *panel_dict = [root objectForKey:@"Panel"];
        
        // set up the key panel background
        
        UIView *panel = [self createPanelBackgroundWithProperties:panel_dict];
        
        double panelWidth = [[[self sheetSetterViewController] view] frame].size.width;
        int numRows = [[[root objectForKey:@"Panel"] objectForKey:@"Rows"] intValue];
        double cellHeight = ceil (panel.frame.size.height / numRows);
        
        [[self view] addSubview:panel];
		
        // set up the keys
        
        // used to accumulate button width (defined as fraction of the whole screen width)
        float keyCounter = 0;
        
        // used to keep track the of the next buttons position (to avoid rounding flips)
        int positionCounter = 0;
        
        NSArray *panel_button_dict = [[root objectForKey:@"Panel"] objectForKey:@"Buttons"];
        
        for (NSMutableDictionary *buttonName in panel_button_dict) {
            KeyButton *button = [self createPanelButtonWithProperties:buttonName];
            
            CGRect buttonFrame = button.frame;
            buttonFrame.origin.x = (CGFloat) round (fmod (positionCounter, panelWidth));
            buttonFrame.origin.y = (CGFloat) (floorf (keyCounter) * cellHeight +
				floor ([[self toolBar] frame].size.height));
            buttonFrame.size.width = (CGFloat) ([button numCells] * panelWidth);
            buttonFrame.size.height = (CGFloat) cellHeight + .25f;                       // + 1 is used to reduce border thickness by making buttons overlap 1 px
            button.frame = buttonFrame;
            
            [[self view] addSubview:button];
            [[self keyDictionary] setObject:button forKey:[NSNumber numberWithInt:(unsigned int)[button tag]]];
            
            keyCounter += [button numCells];
            positionCounter += buttonFrame.size.width;
            
            // reset position counter if we reach the end of a row (we dont know the next buttons width, so we use this buttons width as an estimate)
            if((positionCounter + buttonFrame.size.width) > panelWidth) {
                positionCounter = 0;
            }
        }
        
        // cover the border frame around the keys with 1px black stripes.. ugly, but does the job.
        
        // width of the buttons border property
        float borderWidth = 1.0f;
                
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            borderWidth = 1.1f;
        }
        
        CGFloat screenWidth = [[[self sheetSetterViewController] view] frame].size.width;
        CGFloat toolBarHeight = [[self toolBar] frame].size.height;
        CGFloat panelHeight = [panel frame].size.height;
        
        UIView *leftStripe = [[UIView alloc] initWithFrame:CGRectMake(0, toolBarHeight, borderWidth, panelHeight)];
        [leftStripe setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
        [[self view] addSubview:leftStripe];
        [leftStripe release];
        
        UIView *rightStripe = [[UIView alloc] initWithFrame:CGRectMake(screenWidth - borderWidth, toolBarHeight, borderWidth, panelHeight)];
        [rightStripe setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
        [[self view] addSubview:rightStripe];
        [rightStripe release];
        
        UIView *upperStripe = [[UIView alloc] initWithFrame:CGRectMake(0, toolBarHeight, screenWidth, borderWidth)];
        [upperStripe setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
        [[self view] addSubview:upperStripe];
        [upperStripe release];
        
        UIView *lowerStripe = [[UIView alloc] initWithFrame:CGRectMake(0, panelHeight + toolBarHeight - borderWidth, screenWidth, borderWidth)];
        [lowerStripe setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
        [[self view] addSubview:lowerStripe];
        [lowerStripe release];
    }
    
    return self;
}

- (void) releaseReferences {
	self.sheetSetterViewController = nil;
	
	self.keysetName = nil;
	self.toolBar = nil;
	self.keyDictionary = nil;
	
	self.keySignature = nil;
	self.keySignatureBeforeEditing = nil;
}

- (void)dealloc
{
	[self releaseReferences];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Plist config data loading method

- (NSDictionary *)readKeyConfigWithName:(NSString *)name
{
    // create the string describing the name of the config file
    NSMutableString *completePath = [[name stringByReplacingOccurrencesOfString:@" " withString:@""] mutableCopy];
    [completePath appendString:@".plist"];
    
    NSError *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    plistPath = [rootPath stringByAppendingPathComponent:completePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
    }
    
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *root = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListWithData:plistXML
                                          options:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          error:&errorDesc];
    
    if (!root) {
        NSLog(@"Error reading plist: %@, format: %u", errorDesc, (unsigned) format);
    }
    
    [completePath release];
    
    return root;
}


#pragma mark - KeyView setup methods

- (UIToolbar *)createToolbarWithWidth:(float)new_width Height:(float)new_height
{
    int x = 0;
    int y = 0;
    float width = new_width;
    float height = new_height;
    CGRect toolBarFrame = CGRectMake(x, y, width, height);
    
    UIToolbar *toolbar = [[[UIToolbar alloc] initWithFrame:toolBarFrame] autorelease];
    [toolbar setBarStyle:UIBarStyleBlackOpaque];
    
    return toolbar;
}

- (NSArray *)createToolbarItemsWithTitle:(NSString *)newTitle properties:(NSDictionary *)properties
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
    
    // set up the buttons left of the toolbar title
    
    UIBarButtonItem *item1 = [self createToolbarButtonAtIndex:0 withProperties:properties];
    UIBarButtonItem *item2 = [self createToolbarButtonAtIndex:1 withProperties:properties];
    UIBarButtonItem *item3 = [self createToolbarButtonAtIndex:2 withProperties:properties];
    UIBarButtonItem *item4 = [self createToolbarButtonAtIndex:3 withProperties:properties];
    
    if (item1 != nil) {
        [items addObject:item1];
    }
    
    if (item2 != nil) {
        [items addObject:item2];
    }
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexibleSpace];
    
    // set up the title of the toolbar
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width / 2.5f), 21.0f)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor colorWithWhite:1 alpha:1]];
    [titleLabel setText:newTitle];
	
	#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
		[titleLabel setTextAlignment: (NSTextAlignment) UITextAlignmentCenter];
	#else
		[titleLabel setTextAlignment:NSTextAlignmentCenter];
	#endif
	
	
    [items addObject:[[[UIBarButtonItem alloc] initWithCustomView:titleLabel] autorelease]];
    [titleLabel release];
    
    [items addObject:flexibleSpace];
    
    // set up the buttons right of the toolbar title
    
    if (item3 != nil) {
        [items addObject:item3];
    }
    
    if (item4 != nil) {
        [items addObject:item4];
    }
    
    [flexibleSpace release];
    
    return items;
}

- (UIBarButtonItem *)createToolbarButtonAtIndex:(int)index withProperties:(NSDictionary *)properties
{
    NSDictionary *buttonProps = [properties objectForKey:[NSString stringWithFormat:@"Button %d", index + 1]];
    
    if (buttonProps) {        
        NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
        NSString *imagePath = [thisBundle pathForResource:[buttonProps objectForKey:@"Icon"] ofType:@"png"];
        UIImage *buttonImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
        
        UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithImage:buttonImage style:UIBarButtonItemStylePlain
                                                                 target:[self sheetSetterViewController] action:@selector(buttonTapped:)] autorelease];
		
		item.tintColor = [UIColor colorWithWhite: 1.f alpha: 1.f];
		
        [item setTag:[[buttonProps objectForKey:@"Keycode"] intValue]];
        
        [item setWidth: 32];
        
        [buttonImage release];
        
        return item;
    }
    
    return nil;
}

- (UIView *)createPanelBackgroundWithProperties:(NSDictionary *)properties
{
    float h = [[[properties objectForKey:@"Position"] objectForKey:@"h"] floatValue];
        
    UIView *background = [[[UIView alloc] initWithFrame:CGRectMake(0, 44, [[[self sheetSetterViewController] view] frame].size.width, h)] autorelease];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = background.bounds;
    gradient.colors = [NSArray arrayWithObjects:
		(id) [[UIColor colorWithRed: (CGFloat) (50/255.) green: (CGFloat) (50/255.) blue: (CGFloat) (50/255.) alpha:1] CGColor],
		(id) [[UIColor blackColor] CGColor],
		nil
		
	];
    [background.layer insertSublayer:gradient atIndex:0];
    
    return background;
}

- (KeyButton *)createPanelButtonWithProperties:(NSDictionary *)properties
{    
    NSString *title = [[[properties objectForKey:@"Title"] objectForKey:@"Label"] objectForKey:@"Text"];
    
    int font_size = [[[[properties objectForKey:@"Title"] objectForKey:@"Label"] objectForKey:@"Font Size"] intValue];
    
    NSMutableString *fontName = [[[properties objectForKey:@"Title"] objectForKey:@"Label"] objectForKey:@"Font"];
    
    if ([[[[properties objectForKey:@"Title"] objectForKey:@"Label"] objectForKey:@"Bold"] boolValue]) {
        [fontName appendString:@"-Bold"];
    }
    
    KeyButton *button = [KeyButton buttonWithType:UIButtonTypeCustom];
	[button setNumCells:[[properties objectForKey:@"Cells"] floatValue]];
    [button addTarget:[self sheetSetterViewController] action:@selector(keyTapped:) forControlEvents:UIControlEventTouchDown];
	
	#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
		[[button titleLabel] setLineBreakMode:(NSLineBreakMode) UILineBreakModeWordWrap];
		[[button titleLabel] setTextAlignment:(NSTextAlignment) UITextAlignmentCenter];
	#else
		[[button titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
		[[button titleLabel] setTextAlignment:NSTextAlignmentCenter];
	#endif
	
    [[button titleLabel] setFont:[UIFont fontWithName:fontName size:font_size]];
    [button setTitle:title forState:UIControlStateNormal];
    
    //move text 10 pixels down and right
    [button setTitleEdgeInsets:UIEdgeInsetsMake(5.0f, 0.0f, 0.0f, 0.0f)];
    
    NSDictionary *titleColorNormal = [[[[properties objectForKey:@"Title"] objectForKey:@"Label"] objectForKey:@"Color"] objectForKey:@"Normal"];
    NSDictionary *titleColorSelected = [[[[properties objectForKey:@"Title"] objectForKey:@"Label"] objectForKey:@"Color"] objectForKey:@"Highlighted"];
    
    [button setTitleColor:[self parseColor:titleColorNormal] forState:UIControlStateNormal];
    [button setTitleColor:[self parseColor:titleColorSelected] forState:UIControlStateSelected];
    
    NSDictionary *bgColorNormal = [[[properties objectForKey:@"Background"] objectForKey:@"Color"] objectForKey:@"Normal"];
    NSDictionary *bgColorSelected = [[[properties objectForKey:@"Background"] objectForKey:@"Color"] objectForKey:@"Highlighted"];
    
    [button setBackgroundColor:[self parseColor:bgColorNormal] forState:UIControlStateNormal];
    [button setBackgroundColor:[self parseColor:bgColorSelected] forState:UIControlStateSelected];
    
    button.layer.borderColor = [UIColor grayColor].CGColor;
    
    float borderWidth = 0.3f;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        borderWidth = 0.6f;
    }
    
    button.layer.borderWidth = borderWidth;
    
    button.frame = CGRectMake(0, 0, 0, 0);
    [button setTag:[[properties objectForKey:@"Keycode"] intValue]];
    
    return button;
}

- (UIColor *)parseColor:(NSDictionary *)properties
{
    float red_value = [[properties objectForKey:@"R"] floatValue] / 255;
    float green_value = [[properties objectForKey:@"G"] floatValue] / 255;
    float blue_value = [[properties objectForKey:@"B"] floatValue] / 255;
    float alpha_value = [[properties objectForKey:@"A"] floatValue];
    
    return [UIColor colorWithRed:red_value green:green_value blue:blue_value alpha:alpha_value];
}

#pragma mark - Methods for reading in chords and activating the corresponding keys

- (void)syncKeysWithChord:(AttributedChord *)chord
{
	[[[[self toolBar] items]objectAtIndex:0] setEnabled:YES];
	
	UIBarButtonItem* syncopeButton = [toolBar.items objectAtIndex: 1];
	
    // reset all keys to inactive state
    for (NSNumber *key in keyDictionary) {
        [[keyDictionary objectForKey:key] setSelected:NO];
    }
    
    if ([[[chord key] stringValue] length] == 0) {
		[syncopeButton setEnabled: NO];
		return;
		
	}
	
    // activate the main letter of the chord (CDEFGAB)
    for (NSNumber *key in keyDictionary) {
        KeyButton *button = [keyDictionary objectForKey:key];
        
        if ([[[button titleLabel] text] isEqualToString:[[[chord key] stringValue] substringToIndex:1]]) {
            [button setSelected:YES];
            break;
        }
    }
    
    // activate keys for chord quality or chord options
    
	NSString* chordQuality = [chord chordQuality];
	NSSet* chordOptions = [chord chordOptions];
	
    if ([[[chord key] stringValue] length] > 1 && [[[chord key] stringValue] characterAtIndex:1] == '#') {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:7]] setSelected:YES];
    }
    
    if ([[[chord key] stringValue] length] > 1 && [[[chord key] stringValue] characterAtIndex:1] == 'b') {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:8]] setSelected:YES];
    }
    
    if ([chordQuality isEqualToString: CHORD_QUALITY_MINOR]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:9]] setSelected:YES];
    }
    
    if ([chordOptions containsObject: CHORD_OPTION_VALUE_7]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:10]] setSelected:YES];
    }
    
    if ([chordOptions containsObject: CHORD_OPTION_VALUE_MAJOR_7]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:11]] setSelected:YES];
    }
    
    if ([chordQuality isEqualToString: CHORD_QUALITY_DIMINISHED]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:12]] setSelected:YES];
    }
    
    if ([chordQuality isEqualToString: CHORD_QUALITY_MAJOR] &&
		[chordOptions containsObject: CHORD_OPTION_VALUE_7] &&
		[chordOptions containsObject: CHORD_OPTION_VALUE_9] &&
		[chordOptions containsObject: CHORD_OPTION_VALUE_11]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:14]] setSelected:YES];
    }
    
	if ([chordQuality isEqualToString: CHORD_QUALITY_AUGMENTED]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:15]] setSelected:YES];
    }
	
    // activate keys for bass key in chord
    if ([chord bassKey]) {
        for (NSNumber *key in keyDictionary) {
            KeyButton *button = [keyDictionary objectForKey:key];
            
            // ignore all normal buttons (upper two rows)
            if ([button tag] < 17) {
                continue;
            }
            
            // activate the key for the base letter (case insensitive, since these are small letters due to special font in button labels
            if ([[[[button titleLabel] text] substringFromIndex:1] compare:[[[chord bassKey] stringValue] substringToIndex:1] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                [button setSelected:YES];
            }
        }
        
        // activate b or # if neccessary
        if ([[[chord bassKey] stringValue] length] > 1 && [[[chord bassKey] stringValue] characterAtIndex:1] == '#') {
            [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:24]] setSelected:YES];
        }
        
        if ([[[chord bassKey] stringValue] length] > 1 && [[[chord bassKey] stringValue] characterAtIndex:1] == 'b') {
            [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:25]] setSelected:YES];
        }
    }
	
	// special case: minor 7 b5 is shown as a crossed "o"
	
	if ([chordQuality isEqualToString: CHORD_QUALITY_MINOR] &&
		// [chordOptions count] == 2 &&
		[chordOptions containsObject: CHORD_OPTION_VALUE_7] &&
		[chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_5])
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt: 13]] setSelected: YES];
	
	// special case: any special chord option is selected
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_2] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_4] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_5] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_5] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_5] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_6] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_9] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_9] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_9] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_11] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_11] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_13] ||
		[chordOptions containsObject: CHORD_OPTION_VALUE_13]) {
		
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt: 16]] setSelected: YES];
	}
	
	[syncopeButton setEnabled: [[[chord key] stringValue] length] != 0];
    
}

- (void) syncKeysWithChordOptions: (AttributedChord *) chord {
	
	UIBarButtonItem* syncopeButton = [toolBar.items objectAtIndex: 1];
	[syncopeButton setEnabled: YES];
	
    for (NSNumber *key in keyDictionary) {
        [[keyDictionary objectForKey:key] setSelected:NO];
    }
    
    if ([[[chord key] stringValue] length] == 0) { return; }
	
	NSSet* chordOptions = chord.chordOptions;
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_2]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:0]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_4]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:1]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_5]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:2]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_5]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:3]] setSelected:YES];
	}
	
	// missing CHORD_OPTION_VALUE_SHARP_5
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_6]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:4]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_9]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:5]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_9]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:6]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_9]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:7]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_11]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:8]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_SHARP_11]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:9]] setSelected:YES];
	}
	
	// next two items are reversed
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_FLAT_13]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:11]] setSelected:YES];
	}
	
	if ([chordOptions containsObject: CHORD_OPTION_VALUE_13]) {
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt:10]] setSelected:YES];
	}
}

- (void)syncKeysWithTimeSignature:(TimeSignature *)newSignature
{
	UIBarButtonItem* syncopeButton = [toolBar.items objectAtIndex: 1];
	[syncopeButton setEnabled: NO];
	
    [[[[self toolBar] items]objectAtIndex:0] setEnabled:YES];
    
    // reset all keys to inactive state
    for (NSNumber *key in keyDictionary) {        
        [[keyDictionary objectForKey:key] setSelected:NO];
    }
    
    // reset all keys to inactive state
    for (NSNumber *key in keyDictionary) {
        KeyButton *button = [keyDictionary objectForKey:key];
        
        int buttonFirst = (int) ([[[button titleLabel] text] characterAtIndex:0] - '0');
        
        // button label 12 / 8 is misinterpreted by only reading the first char, fix this (12 / 8 is the only two digit label)
        if (buttonFirst == 1) {
            buttonFirst = 12;
        }
        
        int buttonSecond = (int) ([[[button titleLabel] text] characterAtIndex:([[[button titleLabel] text] length] - 1)] - '0');
        
        if (buttonFirst == [newSignature numerator] && buttonSecond == [newSignature denominator]) {
            [button setSelected:YES];
            break;
        }
    }
}

- (void)syncKeysWithKeySignature:(KeySignature *)newSignature
{
	UIBarButtonItem* syncopeButton = [toolBar.items objectAtIndex: 1];
	[syncopeButton setEnabled: NO];
	
    [[[[self toolBar] items]objectAtIndex:0] setEnabled:YES];
    
    // reset all keys to inactive state
    for (NSNumber *key in keyDictionary) {
        [[keyDictionary objectForKey:key] setSelected:NO];
    }
    
	NSString* signatureStringValue = [[newSignature key] stringValue];
	
    for (NSNumber *key in keyDictionary) {
        KeyButton *button = [keyDictionary objectForKey:key];
        
        if ([[[button titleLabel] text] isEqualToString:[signatureStringValue substringToIndex:1]]) {
            [button setSelected:YES];
        }
        
        if ([[[newSignature key] stringValue] length] > 1) {
            if ([button tag] == 7 && [signatureStringValue characterAtIndex:1] == 'b') {
                [button setSelected:YES];
            }
            else if ([button tag] == 8 && [signatureStringValue characterAtIndex:1] == '#') {
                [button setSelected:YES];
            }
        }
		if ([button tag] == 9 && [newSignature isMinor]) {
			[button setSelected:YES];
		}
    }
}

- (void)syncKeysWithOpeningBarLine:(OpeningBarLine *)line
{
    [[[[self toolBar] items]objectAtIndex:0] setEnabled:YES];
    
    for (NSNumber *key in keyDictionary) {
        [[keyDictionary objectForKey:key] setSelected:NO];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_SINGLE] && [line repeatCount] == 0) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:0]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_SINGLE] && [line repeatCount] > 0) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:1]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] == 0) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:2]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] > 0) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:3]] setSelected:YES];
    }
    
    if ([[line rehearsalMarks] containsObject: BAR_LINE_REHEARSAL_MARK_SEGNO]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:4]] setSelected:YES];
    }
    
    if ([[line rehearsalMarks] containsObject: BAR_LINE_REHEARSAL_MARK_CODA]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:5]] setSelected:YES];
    }
    
    if ([line voltaCount] == 1) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:6]] setSelected:YES];
    }
    
    if ([line voltaCount] == 2) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:7]] setSelected:YES];
    }
    
    if ([line voltaCount] == 3) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:8]] setSelected:YES];
    }
    
    if ([[line barMark] isEqualToString: BAR_LINE_BAR_MARK_WHOLE_REST]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:9]] setSelected:YES];
    }
    
    if ([[line barMark] isEqualToString: BAR_LINE_BAR_MARK_SIMILE]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:10]] setSelected:YES];
    }
    
    if ([[line barMark] isEqualToString: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:11]] setSelected:YES];
    }
}

- (void)syncKeysWithClosingBarLine:(ClosingBarLine *)line
{
    [[[[self toolBar] items]objectAtIndex:0] setEnabled:YES];
    
    for (NSNumber *key in keyDictionary) {
        [[keyDictionary objectForKey:key] setSelected:NO];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_SINGLE]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:0]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] == 0) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:1]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] == 1) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:2]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] == 2) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:3]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] == 3) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:4]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] == 4) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:5]] setSelected:YES];
    }
    
    if ([[line type] isEqualToString: BAR_LINE_TYPE_DOUBLE] && [line repeatCount] == 5) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:6]] setSelected:YES];
    }
    
    if ([[line rehearsalMarks] containsObject: BAR_LINE_REHEARSAL_MARK_CODA]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:7]] setSelected:YES];
    }
    
    if ([[line rehearsalMarks] containsObject: BAR_LINE_REHEARSAL_MARK_DA_CAPO]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:8]] setSelected:YES];
    }
    
    if ([[line rehearsalMarks] containsObject: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:9]] setSelected:YES];
    }
    
    if ([[line rehearsalMarks] containsObject: BAR_LINE_REHEARSAL_MARK_FINE]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:10]] setSelected:YES];
    }
	
    if ([[line rehearsalMarks] containsObject: BAR_LINE_REHEARSAL_LINE_WRAP]) {
        [[[self keyDictionary] objectForKey:[NSNumber numberWithInt:11]] setSelected:YES];
    }
}

#pragma mark - Methods enforcing chord modification rules

- (void)enforceChordRulesForKeyInput:(int)newButtonTag
{
	KeyButton* keyButton = [[self keyDictionary] objectForKey: [NSNumber numberWithInt: newButtonTag]];
	keyButton.selected = !keyButton.selected;
}

- (void)enforceTimeSignatureRulesForKeyInput:(int)newButtonTag
{
	KeyButton* keyButton = [[self keyDictionary] objectForKey: [NSNumber numberWithInt: newButtonTag]];
	keyButton.selected = !keyButton.selected;
}

- (void)enforceKeySignatureRulesForKeyInput:(int)newButtonTag
{
	KeyButton* keyButton = [[self keyDictionary] objectForKey: [NSNumber numberWithInt: newButtonTag]];
	keyButton.selected = !keyButton.selected;
}

- (void)enforceOpeningBarLineRulesForKeyInput:(int)newButtonTag
{
	KeyButton* keyButton = [[self keyDictionary] objectForKey: [NSNumber numberWithInt: newButtonTag]];
	keyButton.selected = !keyButton.selected;
}

- (void)enforceClosingBarLineRulesForKeyInput:(int)newButtonTag
{
	KeyButton* keyButton = [[self keyDictionary] objectForKey: [NSNumber numberWithInt: newButtonTag]];
	keyButton.selected = !keyButton.selected;
}

#pragma mark - Methods for writing out the activated keys to the chord objects

- (void)syncElement:(id)element withButtonWithTag:(int)newButtonTag {
    if (newButtonTag == 1) {
        AttributedChord* chord = element;
        [chord setIsSyncopic:![chord isSyncopic]];
    }
}

#pragma mark - Methods for writing out the activated keys to the chord objects

- (Key*) keyForButtonRowAt:(unsigned int)index pressedKeyIndex: (int)pressedKeyIndex
{
	NSArray* keyMap = [@"C D E F G A B" componentsSeparatedByString: @" "];
	NSString* keyTranspose =
		[[[self keyDictionary] objectForKey:[NSNumber numberWithInt: 7 + index]] isSelected] ? @"#" :
			[[[self keyDictionary] objectForKey:[NSNumber numberWithInt: 8 + index]] isSelected] ? @"b" :
				@"";
	NSString* keyString = [NSString stringWithFormat: @"%@%@",
		[keyMap objectAtIndex: pressedKeyIndex - index],
		keyTranspose
	];
	
	return [Key keyWithString: keyString];
}

- (Key*) keyForTransposeButtonsAt:(unsigned int)index pressedKeyIndex:(int)pressedKeyIndex originalKey:(Key*)originalKey
{
	NSString* keyLetter = [originalKey.stringValue substringToIndex: 1];
    
	if ([keyLetter length]) {
		NSString* keyTranspose = pressedKeyIndex == index ? @"#" : @"b";
		return [Key keyWithString: [keyLetter stringByAppendingString: keyTranspose]];
	} else {
		return nil;
	}
}

- (void) applyChordKeyPress:(KeyButton*)pressedKey toChord:(Chord*)chord
{
	int pressedKeyIndex = (int) [pressedKey tag];
	BOOL pressedKeyState = [pressedKey isSelected];
	
	// NSLog (@"pressed key %i is selected %i", pressedKeyIndex, pressedKeyState);
	
	if (pressedKeyIndex >= 0 && pressedKeyIndex <= 6) {
		if (pressedKeyState) {
			[chord setKey: [self keyForButtonRowAt: 0 pressedKeyIndex: pressedKeyIndex]];
		} else {
			[chord setKey: nil];
		}
	}
	
	if (pressedKeyIndex >= 7 && pressedKeyIndex <= 8) {
		if (pressedKeyState) {
			[chord setKey: [self keyForTransposeButtonsAt: 7
				pressedKeyIndex: pressedKeyIndex
				originalKey: chord.key]];
		} else {
			[chord setKey: [Key keyWithString: [chord.key.stringValue substringToIndex: 1]]];
		}
	}
	
	if (pressedKeyIndex == 9) {
		if (pressedKeyState) {
			[chord setChordQuality: CHORD_QUALITY_MINOR];
        } else {
			[chord setChordQuality: nil];
		}
	}
	
	if (pressedKeyIndex == 10) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_7];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_7];
		}
	}

	if (pressedKeyIndex == 11) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_MAJOR_7];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_MAJOR_7];
		}
	}
	
	if (pressedKeyIndex == 12) {
		if (pressedKeyState) {
			[chord setChordQuality: CHORD_QUALITY_DIMINISHED];
		} else {
			[chord setChordQuality: nil];
		}
	}
	
	if (pressedKeyIndex == 13) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_HALF_DIMINISHED];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_HALF_DIMINISHED];
		}
	}
	
	if (pressedKeyIndex == 14) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_SUSPENDED];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_SUSPENDED];
		}
	}
	
	if (pressedKeyIndex == 15) {
		if (pressedKeyState) {
			[chord setChordQuality: CHORD_QUALITY_AUGMENTED];
		} else {
			[chord setChordQuality: nil];
		}
	}
	
	if (pressedKeyIndex >= 17 && pressedKeyIndex <= 23) {
		if (pressedKeyState) {
			[chord setBassKey: [self keyForButtonRowAt: 17 pressedKeyIndex: pressedKeyIndex]];
		} else {
			[chord setBassKey: nil];
		}
	}
	
	if (pressedKeyIndex >= 24 && pressedKeyIndex <= 25) {
		if (pressedKeyState) {
			[chord setBassKey: [self keyForTransposeButtonsAt: 24
				pressedKeyIndex: pressedKeyIndex
				originalKey: chord.bassKey]];
		} else {
			[chord setBassKey: [Key keyWithString: [chord.bassKey.stringValue substringToIndex: 1]]];
		}
	}
	
	// NSLog (@"##### NEW CHORD %@", chord);
}

- (void) applyChordOptionsKeyPress: (KeyButton*) pressedKey toChord: (Chord*) chord {
	int pressedKeyIndex = (int) [pressedKey tag];
	BOOL pressedKeyState = [pressedKey isSelected];
	
	// NSLog (@"pressed key %i is selected %i", pressedKeyIndex, pressedKeyState);
	
	if (pressedKeyIndex == 0) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_2];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_2];
		}
	}
	
	if (pressedKeyIndex == 1) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_4];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_4];
		}
	}
	
	if (pressedKeyIndex == 2) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_FLAT_5];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_FLAT_5];
		}
	}
	
	if (pressedKeyIndex == 3) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_5];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_5];
		}
	}
	
	// missing CHORD_OPTION_VALUE_SHARP_5
	
	if (pressedKeyIndex == 4) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_6];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_6];
		}
	}
	
	if (pressedKeyIndex == 5) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_FLAT_9];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_FLAT_9];
		}
	}
	
	if (pressedKeyIndex == 6) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_9];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_9];
		}
	}
	
	if (pressedKeyIndex == 7) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_SHARP_9];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_SHARP_9];
		}
	}
	
	if (pressedKeyIndex == 8) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_11];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_11];
		}
	}
	
	if (pressedKeyIndex == 9) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_SHARP_11];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_SHARP_11];
		}
	}
	
	// reversed next two keys :((
	
	if (pressedKeyIndex == 11) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_FLAT_13];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_FLAT_13];
		}
	}
	
	if (pressedKeyIndex == 10) {
		if (pressedKeyState) {
			[chord setChordOption: CHORD_OPTION_VALUE_13];
		} else {
			[chord removeChordOption: CHORD_OPTION_VALUE_13];
		}
	}
	
	// NSLog (@"##### NEW CHORD %@", chord);
}

- (void)applyTimeSignatureKeyPress: (KeyButton*) pressedKey toTimeSignature: (TimeSignature *)newSignature
{	
	// int pressedKeyIndex = [pressedKey tag];
	// BOOL pressedKeyState = [pressedKey isSelected];
	
	NSString* pressedKeyLabel = [[pressedKey titleLabel] text];
	int buttonFirst = (int) ([pressedKeyLabel characterAtIndex:0] - '0');
	
	// button label 12 / 8 is misinterpreted by only reading the first char, fix this (12 / 8 is the only two digit label)
	if (buttonFirst == 1)
		buttonFirst = 12;
	
	int buttonSecond = (int) ([pressedKeyLabel characterAtIndex:([pressedKeyLabel length] - 1)] - '0');
	
	[newSignature setNumerator:buttonFirst];
	[newSignature setDenominator:buttonSecond];
}

- (void) applyKeySignatureKeyPress: (KeyButton*) pressedKey toKeySignature: (KeySignature *) newKeySignature {
	int pressedKeyIndex = (int) [pressedKey tag];
	BOOL pressedKeyState = [pressedKey isSelected];
	
	if (pressedKeyIndex >= 0 && pressedKeyIndex <= 6) {
		if (pressedKeyState) {
			((KeyButton*) [[self keyDictionary] objectForKey: [NSNumber numberWithInt: 7]]).selected = NO;
			((KeyButton*) [[self keyDictionary] objectForKey: [NSNumber numberWithInt: 8]]).selected = NO;
			
			[newKeySignature setKey: [self keyForButtonRowAt: 0 pressedKeyIndex: pressedKeyIndex]];
		} else {
			[newKeySignature setKey: self.keySignatureBeforeEditing.key];
		}
	}
	
	if (pressedKeyIndex >= 7 && pressedKeyIndex <= 8) {
		if (pressedKeyState) {
			[newKeySignature setKey: [self keyForTransposeButtonsAt: 8 // sharp/flat keys are reversed here
				pressedKeyIndex: pressedKeyIndex
				originalKey: newKeySignature.key]];
		} else {
			[newKeySignature setKey: [Key keyWithString: [newKeySignature.key.stringValue substringToIndex: 1]]];
			
		}
	}
	
	if (pressedKeyIndex == 9)
		newKeySignature.isMinor = pressedKeyState;
	
	 //NSLog(@"key signature before editing: %@", keySignatureBeforeEditing);
	 //NSLog(@"current key signature: %@", newKeySignature);
}

- (void) applyBarKeyPress: (KeyButton*) pressedKey toOpeningBarLine: (OpeningBarLine*) line {
	int pressedKeyIndex = (int) [pressedKey tag];
	BOOL pressedKeyState = [pressedKey isSelected];
	
	if (pressedKeyIndex == 0 ||
		(!pressedKeyState &&
		pressedKeyIndex >= 1 && pressedKeyIndex <= 3)) {
        [line setType: BAR_LINE_TYPE_SINGLE];
        [line setRepeatCount:0];
		
	} else {
		if (pressedKeyIndex == 1) {
			[line setType: BAR_LINE_TYPE_SINGLE];
			[line setRepeatCount: 1];
		}
		
		if (pressedKeyIndex == 2) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 0];
		}
		
		if (pressedKeyIndex == 3) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 1];
		}
	}
	
	if (pressedKeyIndex == 4) {
		if (pressedKeyState)
			[line addRehearsalMark: BAR_LINE_REHEARSAL_MARK_SEGNO];
		else
			[line removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_SEGNO];
	}
	
	if (pressedKeyIndex == 5) {
		if (pressedKeyState)
			[line addRehearsalMark: BAR_LINE_REHEARSAL_MARK_CODA];
		else
			[line removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_CODA];
	}
	
	if (pressedKeyIndex == 6) {
		if (pressedKeyState)
			[line setVoltaCount: 1];
		else
			[line setVoltaCount: 0];
	}
	
	if (pressedKeyIndex == 7) {
		if (pressedKeyState)
			[line setVoltaCount: 2];
		else
			[line setVoltaCount: 0];
	}
	
	if (pressedKeyIndex == 8) {
		if (pressedKeyState)
			[line setVoltaCount: 3];
		else
			[line setVoltaCount: 0];
	}
	
	if (pressedKeyIndex == 9) {
		if (pressedKeyState)
			[line setBarMark: BAR_LINE_BAR_MARK_WHOLE_REST];
		else
			[line setBarMark: nil];
	}
	
	if (pressedKeyIndex == 10) {
		if (pressedKeyState)
			[line setBarMark: BAR_LINE_BAR_MARK_SIMILE];
		else
			[line setBarMark: nil];
	}
	
	if (pressedKeyIndex == 11) {
		if (pressedKeyState)
			[line setBarMark: BAR_LINE_BAR_MARK_TWO_BAR_SIMILE];
		else
			[line setBarMark: nil];
	}
	
	if (pressedKeyIndex == 12) {
		SheetView* sheetView = sheetSetterViewController.sheetScrollView.sheetView;
		[sheetView toggleCurrentTimeSignature:YES];
		pressedKey.selected = NO;
		
	}
	
	if (pressedKeyIndex == 13) {
		SheetView* sheetView = sheetSetterViewController.sheetScrollView.sheetView;
		[sheetView insertBarAtCurrentPosition];
		pressedKey.selected = NO;
		
	}
	
	if (pressedKeyIndex == 14) {
		SheetView* sheetView = sheetSetterViewController.sheetScrollView.sheetView;
		[sheetView removeBarAtCurrentPosition];
		pressedKey.selected = NO;
		
	}
	
	
}

- (void) applyBarKeyPress: (KeyButton*) pressedKey toClosingBarLine: (ClosingBarLine*) line {
	int pressedKeyIndex = (int) [pressedKey tag];
	BOOL pressedKeyState = [pressedKey isSelected];
	
	if (pressedKeyIndex == 0 ||
		(!pressedKeyState &&
		pressedKeyIndex >= 1 && pressedKeyIndex <= 6)) {
        [line setType: BAR_LINE_TYPE_SINGLE];
        [line setRepeatCount:0];
	} else {
		if (pressedKeyIndex == 1) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 0];
		}
		
		if (pressedKeyIndex == 2) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 1];
		}
		
		if (pressedKeyIndex == 3) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 2];
		}
		
		if (pressedKeyIndex == 4) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 3];
		}
		
		if (pressedKeyIndex == 5) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 4];
		}
		
		if (pressedKeyIndex == 6) {
			[line setType: BAR_LINE_TYPE_DOUBLE];
			[line setRepeatCount: 5];
		}
		
	}
	
	if (pressedKeyIndex == 7) {
		if (pressedKeyState)
			[line addRehearsalMark: BAR_LINE_REHEARSAL_MARK_CODA];
		else
			[line removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_CODA];
	}
	
	if (pressedKeyIndex == 8) {
		if (pressedKeyState)
			[line addRehearsalMark: BAR_LINE_REHEARSAL_MARK_DA_CAPO];
		else
			[line removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_DA_CAPO];
	}
	
	if (pressedKeyIndex == 9) {
		if (pressedKeyState)
			[line addRehearsalMark: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO];
		else
			[line removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_DAL_SEGNO];
	}
	
	if (pressedKeyIndex == 10) {
		if (pressedKeyState)
			[line addRehearsalMark: BAR_LINE_REHEARSAL_MARK_FINE];
		else
			[line removeRehearsalMark: BAR_LINE_REHEARSAL_MARK_FINE];
	}
	
	if (pressedKeyIndex == 11) {
		if (pressedKeyState)
			[line addRehearsalMark: BAR_LINE_REHEARSAL_LINE_WRAP];
		else
			[line removeRehearsalMark: BAR_LINE_REHEARSAL_LINE_WRAP];
	}
	
}

- (NSString *)selectedKeysString
{
    NSMutableString *resultString = [[[NSMutableString alloc] initWithCapacity:5] autorelease];
    
    NSArray *orderedKeys = [[[self keyDictionary] allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
    for (NSNumber *tempIndex in orderedKeys) {
        KeyButton *tempButton = [[self keyDictionary] objectForKey:tempIndex];
        
        if ([tempButton isSelected]) {
            if ([[[tempButton titleLabel] text] isEqualToString:@"q"]) {
                [resultString appendString:@"b"];
            }
            else {
                [resultString appendString:[[tempButton titleLabel] text]];
            }
        }
    }
    
    return resultString;
}

@end
