//
//  SheetEditingDelegate.h
//  SheetSetter
//
//  Created by Pattrick Kreutzer on 06.12.10.
//  Copyright 2010 wysiwyg* software design gmbh.
//

@protocol SheetEditingDelegate

- (void) beginEditing;
- (void) endEditing;

- (BOOL) isShowingKeys;

- (void) didChangeSheetTitle;

- (void) beginPlayback;
- (void) endPlayback;

- (void) swapSheet: (int) direction;

@end
