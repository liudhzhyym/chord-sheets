//
//  PlayBackViewController.m
//  Chord Sheets
//
//  Created by Moritz Pipahl on 23.11.11.
//  copyright (c) 2011 wysywig* software design gmbh.
//	Released into the public domain in 2015. http://creativecommons.org/publicdomain/zero/1.0/
//

#import "PlayBackViewController.h"

#import "AppDelegate.h"

#import "ChordPlayer.h"
#import "Bar.h"
#import "SheetView.h"


@implementation PlayBackViewController

@synthesize playButton;
@synthesize bpmSlider;
@synthesize beatButton;
@synthesize player;
@synthesize sheet;
@synthesize sheetView;
@synthesize playing;

#define MIN_BPM 50
#define MAX_BPM 200

- (id) initWithSheet:(Sheet *)newSheet sheetView:(SheetView *)newSheetView
{
    self = [super initWithNibName:@"PlayBackView" bundle:nil];
    
    if (self) {
        [self setSheet:newSheet];
        [self setSheetView:newSheetView];
        [self setPlayer:[ChordPlayer sharedInstance]];
				
    }
    
    return self;
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

-(void) releaseReferences
{
    self.bpmSlider = nil;
	self.beatButton = nil;
	self.playButton = nil;
	
	self.player = nil;
	
	self.sheet = nil;
	self.sheetView = nil;
}

- (void)dealloc
{
	[self releaseReferences];
	[_transposeButton release];
	[_toolbar release];
	
	self.lastBeatTimes = nil;
	self.rings = nil;
	
	[super dealloc];
	
}

- (void) viewWillDisappear:(BOOL)animated
{
	if ([self sheetView].isPlayingBack)
		[self setPlaying:NO];
	
	[super viewWillDisappear:animated];
	
}

- (IBAction)playButtonPressed:(id)sender
{
    [self setPlaying:![self isPlaying]];
}

- (IBAction)bpmSliderMoved:(id)sender
{
    float newBPM = (([(UISlider *)sender value] * (MAX_BPM - MIN_BPM)) + MIN_BPM);
	
	[UIView setAnimationsEnabled:NO];
    [self changeBPM:newBPM];
	[UIView setAnimationsEnabled:YES];
	
}

- (void) updateSlider {
	[self updateSliderAnimated: NO];
	
}

- (void) updateSliderAnimated: (BOOL) animated {
	[bpmSlider setValue:(([[self sheet] tempo] - MIN_BPM) / (MAX_BPM - MIN_BPM)) animated: animated];
	
}

- (IBAction) bpmButtonPressed: (UIButton*) sender {
	if (self -> _lastBeatTimes == nil)
		self -> _lastBeatTimes = [[NSMutableArray alloc] init];
	
	NSDate* beatTime = [[NSDate alloc] init];
	
	NSMutableArray* lastBeatTimes = self.lastBeatTimes;
	[lastBeatTimes addObject: beatTime];
	
	[beatTime release];
	
	double currentBPM = 0;
	int numLastBeatTimes = (int) [lastBeatTimes count];
	if (numLastBeatTimes > 1) {
		NSDate* lastBeat = [lastBeatTimes objectAtIndex: numLastBeatTimes - 2];
		NSTimeInterval delta = [beatTime timeIntervalSinceDate: lastBeat];

		double beatsPerMinute = 60 / delta;
		if (beatsPerMinute > 30)
			currentBPM = log (beatsPerMinute);
		
	}
	
	// [beatTime release];
	
	NSMutableArray* bpms = [[NSMutableArray alloc] init];
	
	for (uint i = 1; i < numLastBeatTimes; i++) {
		
		NSDate* lastBeat = [lastBeatTimes objectAtIndex: i - 1];
		NSDate* beat = [lastBeatTimes objectAtIndex: i];
		
		NSTimeInterval delta = [beat timeIntervalSinceDate: lastBeat];
		double beatsPerMinute = 60 / delta;
		if (beatsPerMinute < 30 || beatsPerMinute > 300) {
			[bpms removeAllObjects];
			continue;
			
		}
		beatsPerMinute = MAX (50, MIN (200, beatsPerMinute));
		
		double logBeatsPerMinute = log (beatsPerMinute);
		
		if (ABS (currentBPM - logBeatsPerMinute) > .2) {
			// NSLog(@"tempo mismatch. skip a beat.");
			continue;
			
		}
		
		[bpms addObject: [NSNumber numberWithDouble: logBeatsPerMinute]];
		
	}
	
	// NSLog (@"bum. %@ bpm.", bpms);
	
	double bpmSum = 0;
	for (int i = (int) [bpms count]; i-- > 0;) {
		bpmSum += [[bpms objectAtIndex: i] doubleValue];
		
	}
	bpmSum /= [bpms count];
	
	// [bpms release];
	
	double beatsPerMinute = exp (bpmSum);
	if (beatsPerMinute > 0) {
		[self changeBPM: (int) round (beatsPerMinute)];
		[self updateSliderAnimated: YES];
		
	}
	
	while ([lastBeatTimes count] > 8)
		[lastBeatTimes removeObjectAtIndex: 0];
	
	[bpms release];
	
	// ring animation
	
	static const float downscale = .25f;
	static const float upscale = 2.f;
	
	CGRect buttonFrame = beatButton.frame;
	CGPoint offset = CGPointMake (
		buttonFrame.origin.x + buttonFrame.size.width / 2,
		buttonFrame.origin.y + buttonFrame.size.height / 2
		
	);
	
	
	AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	BOOL isLightsOut = appDelegate.lightsOutModeEnabled;
	
	UIImage* ringImage = [UIImage imageNamed:
		isLightsOut ? @"BeatCounter_Ring_negative.png" : @"BeatCounter_Ring.png"];
	
	CGSize ringSize = ringImage.size;
	CGImageRef ringImageRef = [ringImage CGImage];
	
	if (self -> _rings == nil)
		self -> _rings = [[NSMutableArray alloc] init];
	
	NSMutableArray* rings = self.rings;
	CALayer* ring;
	
	if ([rings count] > ringIndex) {
		ring = [rings objectAtIndex: ringIndex];
		
	} else {
		ring = [CALayer layer];
		[rings addObject: ring];
		
	}
	
	if (ring.contents != (id) ringImageRef)
		ring.contents = (id) ringImageRef;
	
	ringIndex = (ringIndex + 1) % 4;
	
	ring.bounds = CGRectMake (
		offset.x - ringSize.width / 2 * downscale * 0,
		offset.y - ringSize.height / 2 * downscale * 0,
		ringSize.width * downscale,
		ringSize.height * downscale
		
	);
	ring.position = CGPointMake (
		offset.x - ringSize.width / 2 * downscale * 0,
		offset.y - ringSize.height / 2 * downscale * 0
		
	);
	ring.opacity = 0;
	
	[self.view.layer addSublayer: ring];
	
	
	static const float animationDuration = .5f;
	
	CABasicAnimation* fadeAnimation = [CABasicAnimation animationWithKeyPath: @"opacity"];
	fadeAnimation.fromValue = [NSNumber numberWithFloat: 1.0];
	fadeAnimation.toValue = [NSNumber numberWithFloat: 0.0];
	fadeAnimation.duration = animationDuration;

	CABasicAnimation* scaleAnimationX = [CABasicAnimation animationWithKeyPath: @"position.x"];
	scaleAnimationX.fromValue = [NSNumber numberWithDouble: ring.bounds.origin.x];
	scaleAnimationX.toValue = [NSNumber numberWithDouble: offset.x - ringSize.width / 2 * upscale * 0];
	scaleAnimationX.duration = animationDuration;

	CABasicAnimation* scaleAnimationY = [CABasicAnimation animationWithKeyPath: @"position.y"];
	scaleAnimationY.fromValue = [NSNumber numberWithDouble: ring.bounds.origin.y];
	scaleAnimationY.toValue = [NSNumber numberWithDouble: offset.y - ringSize.height / 2 * upscale * 0];
	scaleAnimationY.duration = animationDuration;

	CABasicAnimation* scaleAnimationWidth = [CABasicAnimation animationWithKeyPath: @"bounds.size.width"];
	scaleAnimationWidth.fromValue = [NSNumber numberWithDouble: ring.bounds.size.width];
	scaleAnimationWidth.toValue = [NSNumber numberWithDouble: ringSize.width * upscale];
	scaleAnimationWidth.duration = animationDuration;

	CABasicAnimation* scaleAnimationHeight = [CABasicAnimation animationWithKeyPath: @"bounds.size.height"];
	scaleAnimationHeight.fromValue = [NSNumber numberWithDouble: ring.bounds.size.height];
	scaleAnimationHeight.toValue = [NSNumber numberWithDouble: ringSize.height * upscale];
	scaleAnimationHeight.duration = animationDuration;
	
	CAAnimationGroup* animationGroup = [CAAnimationGroup animation];
	animationGroup.animations = [NSArray arrayWithObjects: fadeAnimation, scaleAnimationX, scaleAnimationY, scaleAnimationWidth, scaleAnimationHeight, nil];
	animationGroup.duration = animationDuration;
	animationGroup.delegate = self;
	animationGroup.removedOnCompletion = NO;
	
	[ring addAnimation: animationGroup forKey: @"pulse-tap"];
	
}

- (void) animationDidStop:(CAAnimation*) animation finished: (BOOL) finished {
	for (CALayer* ring in self.rings) {
		// NSLog (@"searching %@", [ring animationForKey: @"pulse-tap"]);
		if (animation == [ring animationForKey: @"pulse-tap"]) {
			// NSLog (@"found %@", ring);
			[ring removeAllAnimations];
			[ring removeFromSuperlayer];
			
		}
		
	}
	
}

- (void) changeBPM:(float)newBPM
{
    if (newBPM < MIN_BPM) {
        newBPM = MIN_BPM;
    }
    else if (newBPM > MAX_BPM) {
        newBPM = MAX_BPM;
    }
    
	
    [beatButton setTitle:[NSString stringWithFormat:@"%.0f BPM", newBPM] forState: UIControlStateNormal];
    [[self sheet] setTempo:newBPM];
}

- (void) setPlaying:(BOOL)newPlaying
{
    if (newPlaying && ![self isPlaying]) {
        playing = YES;
        [[self playButton] setImage:[UIImage imageNamed:@"pause.png"]];
        [[self sheetView] startPlaybackFromCurrentElement];
    }
    else if(!newPlaying && [self isPlaying]) {
        playing = NO;
        [[self playButton] setImage:[UIImage imageNamed:@"play.png"]];
        [[self sheetView] stopPlayback];
    }
	
	if (self -> _lastBeatTimes != nil)
		 [self -> _lastBeatTimes release], _lastBeatTimes = nil;
	if (self -> _rings != nil)
		[self -> _rings release], _rings = nil;
	
}

@end
