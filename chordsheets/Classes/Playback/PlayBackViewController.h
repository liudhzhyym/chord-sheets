//
//  PlayBackViewController.h
//  Chord Sheets
//
//  Created by Moritz Pipahl on 23.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import <UIKit/UIKit.h>
#import "Sheet.h"
#import "SheetView.h"
#import "ChordPlayer.h"

@interface PlayBackViewController : UIViewController {
	int ringIndex;
	
}

@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *playButton;
@property (nonatomic, retain) IBOutlet UISlider *bpmSlider;
@property (nonatomic, retain) IBOutlet UIButton *beatButton;

@property (retain, nonatomic) IBOutlet UIBarButtonItem *transposeButton;

@property (nonatomic, retain) ChordPlayer *player;
@property (nonatomic, retain) Sheet *sheet;
@property (nonatomic, retain) SheetView *sheetView;
@property (nonatomic, assign, getter = isPlaying) BOOL playing;

@property (strong, nonatomic) NSMutableArray* lastBeatTimes;
@property (strong, nonatomic) NSMutableArray* rings;

- (IBAction)playButtonPressed:(id)sender;
- (IBAction)bpmButtonPressed:(id)sender;
- (IBAction)bpmSliderMoved:(id)sender;

- (id)initWithSheet:(Sheet *)sheet sheetView:(SheetView *)sheetView;
- (void)changeBPM:(float)newBPM;

- (void) updateSlider;
- (void) updateSliderAnimated: (BOOL) animated;

@end
