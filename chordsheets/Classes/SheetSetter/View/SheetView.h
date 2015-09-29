//
//  SheetView.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 03.11.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

#import <UIKit/UIKit.h>

#import "SheetLayer.h"

#import "SheetEditingDelegate.h"

@class SheetSetterViewController;

#define TOUCH_EXTENT 9


@class Chord;
@class AttributedChord;
@class ChordPlayer;

@class TimeSignature;

@class LayerIterator;
@class PlaybackSequence;


@interface SheetView : UIView <UITextFieldDelegate> {
	
	@public
	
	SheetLayer* sheetLayer;
	
	CGFloat scale;
	
	unsigned int spiralBuffer [TOUCH_EXTENT * TOUCH_EXTENT];
	unsigned int spiralBufferLength;
	
	
	@protected
	
	NSString* colorScheme;
	
	id <SheetEditingDelegate> editingDelegate;
	
	BOOL didEdit;
	BOOL willBeginEditing;
	BOOL isEditing;
	BOOL isEditingAnnotation;
	
	ScalableLayer* editingLayer;
	UITextField* inputField;
	
	UIView* testFrame;
	
	BOOL didChange;
	
	LayerIterator* editingIterator;
	LayerIterator* playbackIterator;
	
	NSTimer* playbackTimer;
	NSDate* lastScheduledPlaybackDate;
	ChordPlayer* chordPlayer;
	
	PlaybackSequence* playbackSequence;
	
	@private
	
	BOOL setUpControlsImmediately;
	CGRect zoomingRect;
	
	ScalableLayer* layerBeforeEnteringAnnotationEditingMode;
	TimeSignature* timeSignatureBeforeEditing;
	
	ScalableLayer* currentLayerOverCursor;
	
}

+ (UIColor*) backgroundColorForScheme: (NSString*) colorScheme;

@property (readwrite, retain) NSString* colorScheme;

@property (readwrite) float scale;

@property (readonly) CGRect scaledViewBounds;

- (void) zoomToFullContent;

- (SheetLayer*) sheetLayer;

@property (readwrite, retain, nonatomic) ScalableLayer* editingLayer;
- (void) setEditingLayer: (ScalableLayer*) _editingView andCollapse: (BOOL) shouldCollapse;

@property (readwrite) BOOL willBeginEditing;
@property (readonly) BOOL isEditing;

- (void) enterEditMode;
- (void) leaveEditMode;
- (void) leaveEditModeAndCollapse: (BOOL) shouldCollapse;

- (void) zoomToSelected;
- (void) setUpControls;

- (void) presentStaticLayer;
- (void) presentDynamicLayer;

- (void) presentCursor: (BOOL) state;

- (float) fullContentScale;

@end


@interface SheetView (Interactive)

- (void) handleTap: (UITapGestureRecognizer*) gestureRecognizer;
- (void) handleDoubleTap: (UITapGestureRecognizer*) gestureRecognizer;

@end


@class KeySignature;

@interface SheetView (Editing)

@property (readwrite, assign) id <SheetEditingDelegate> editingDelegate;
@property (readonly) UITextField* inputField;

@property (readonly) id currentElement;

- (TimeSignature*) currentTimeSignature;

- (void) goForward;
- (void) enterAnnotationEditingMode;
- (void) leaveAnnotationEditingMode;
- (void) goBack;

- (BOOL) isFirstElement: (id) element;
- (BOOL) isOnFirstBar;

- (void) commitChangeToCurrentElement;
- (void) commitTextEdit;

@property (readwrite) BOOL didChange;

- (void) toggleCurrentTimeSignature: (BOOL) jumpBackIfSet;

- (void) insertBarAtCurrentPosition;
- (void) removeBarAtCurrentPosition;

- (KeySignature*) firstKeySignature;
- (void) transposeFromBeginningUsingOriginalKeySignature: (KeySignature*) originalKeySignature targetKeySignature: (KeySignature*) targetKeySignature;
- (BOOL) keySignatureDoesChangeAfterCurrentPosition;
- (void) transposeFromCurrentPositionUsing: (KeySignature*) targetKeySignature originalKeySignature: (KeySignature*) originalKeySignature transposeToEnd: (BOOL) transposeToEnd;
- (void) transposeWithIterator: (LayerIterator*) iterator fromKeySignature: (KeySignature*) originalKeySignature toKeySignature: (KeySignature*) targetKeySignature transposeToEnd: (BOOL) transposeToEnd;

- (void) changeKeyFromBeginningUsingOriginalKeySignature: (KeySignature*) originalKeySignature targetKeySignature: (KeySignature*) targetKeySignature;
- (void) changeKeyWithIterator: (LayerIterator*) iterator fromKeySignature: (KeySignature*) originalKeySignature toKeySignature: (KeySignature*) targetKeySignature changeKeyToEnd: (BOOL) changeKeyToEnd;

- (void) adjustCursorPosition;

@end


@interface SheetView (AudioPlayback)

- (void) playChord: (Chord*) chord;

@property (readwrite) float tempo;

- (void) startPlaybackFromCurrentElement;
@property (readonly) BOOL isPlayingBack;
- (void) stopPlayback;
- (void) stopPlaybackAndCenterContent: (BOOL) doCenter;

@end
