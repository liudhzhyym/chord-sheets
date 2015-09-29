//
//  KeyViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 04.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import "KeyButton.h"
#import "SheetView.h"
#import "TimeSignature.h"
#import "OpeningBarLine.h"
#import "ClosingBarLine.h"
#import "Chord.h"


@class SheetSetterViewController;

@interface KeyViewController : UIViewController

@property (nonatomic, retain) SheetSetterViewController *sheetSetterViewController;
@property (nonatomic, retain) NSString *keysetName;
@property (nonatomic, retain) UIToolbar *toolBar;
@property (nonatomic, retain) NSMutableDictionary *keyDictionary;
@property (nonatomic, copy) KeySignature *keySignature;
@property (nonatomic, copy) KeySignature *keySignatureBeforeEditing;

- (id)initWithKeyConfig:(NSString *)newKeysetName sheetSetterViewController:(SheetSetterViewController *)newSheetSetterViewController;

- (NSDictionary *)readKeyConfigWithName:(NSString *)name;
- (UIToolbar *)createToolbarWithWidth:(float)new_width Height:(float)new_height;
- (NSArray *)createToolbarItemsWithTitle:(NSString *)newTitle properties:(NSDictionary *)properties;
- (UIBarButtonItem *)createToolbarButtonAtIndex:(int)index withProperties:(NSDictionary *)properties;
- (UIView *)createPanelBackgroundWithProperties:(NSDictionary *)properties;
- (KeyButton *)createPanelButtonWithProperties:(NSMutableDictionary *)properties;
- (UIColor *)parseColor:(NSDictionary *)properties;


- (void)syncKeysWithChord:(AttributedChord *)chord;
- (void)syncKeysWithChordOptions: (AttributedChord *) chord;
- (void)syncKeysWithTimeSignature:(TimeSignature *)signature;
- (void)syncKeysWithKeySignature:(KeySignature *)signature;
- (void)syncKeysWithOpeningBarLine:(OpeningBarLine *)line;
- (void)syncKeysWithClosingBarLine:(ClosingBarLine *)line;

- (void)enforceChordRulesForKeyInput:(int)newButtonTag;
- (void)enforceTimeSignatureRulesForKeyInput:(int)newButtonTag;
- (void)enforceKeySignatureRulesForKeyInput:(int)newButtonTag;
- (void)enforceOpeningBarLineRulesForKeyInput:(int)newButtonTag;
- (void)enforceClosingBarLineRulesForKeyInput:(int)newButtonTag;

- (void)syncElement:(id)element withButtonWithTag:(int)newButtonTag;

- (void)applyChordKeyPress: (KeyButton*) pressedKey toChord: (Chord*) chord;
- (void)applyChordOptionsKeyPress: (KeyButton*) pressedKey toChord: (Chord*) chord;

- (void)applyTimeSignatureKeyPress: (KeyButton*) pressedKey toTimeSignature: (TimeSignature *)newSignature;
- (void)applyKeySignatureKeyPress: (KeyButton*) pressedKey toKeySignature: (KeySignature *) keySignature;

- (void)applyBarKeyPress: (KeyButton*) pressedKey toOpeningBarLine: (OpeningBarLine*) line;
- (void) applyBarKeyPress: (KeyButton*) pressedKey toClosingBarLine: (ClosingBarLine*) line;

- (NSString *)selectedKeysString;

@end
