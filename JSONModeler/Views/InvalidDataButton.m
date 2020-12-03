//
// Copyright 2016 The Nerdery, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "InvalidDataButton.h"

@interface InvalidDataButton ()

@end

@implementation InvalidDataButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    
    if (self) {
        self.textField = [[NSTextField alloc] initWithFrame:NSMakeRect(32, -7, frameRect.size.width, frameRect.size.height)];
        (self.textField).alignment = NSLeftTextAlignment;
        [_textField setBezeled:NO];
        [_textField setDrawsBackground:NO];
        [_textField setEditable:NO];
        [_textField setSelectable:NO];
        _textField.cell.backgroundStyle = NSBackgroundStyleRaised;
        [self addSubview:self.textField];
        [_textField setStringValue:NSLocalizedString(@"Invalid Data Structure", @"This is a message stating that the JSON that is in the application is not of valid form")];
        (self.textField).textColor = [NSColor blackColor];

        NSImage *alertImage = [NSImage imageNamed:@"alert"];
        NSImageView *alertImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(8, 9, alertImage.size.width, alertImage.size.height)];
        alertImageView.image = alertImage;
        [self addSubview:alertImageView];
        
        
        // Setup the images
        NSImage *leftCapImage = [NSImage imageNamed:@"alertLeftCap"];
        NSImage *middleCapImage = [NSImage imageNamed:@"alertBackground"];
        NSImage *rightCapImage = [NSImage imageNamed:@"alertRightCap"];
        
        self.capLeft.image = leftCapImage;
        self.capLeft.frame = NSMakeRect(0, 0, leftCapImage.size.width, leftCapImage.size.height);
        
        self.capMiddle.imageScaling = NSImageScaleAxesIndependently;
        self.capMiddle.image = middleCapImage;
        self.capMiddle.frame = NSMakeRect(leftCapImage.size.width, 0, frameRect.size.width - leftCapImage.size.width - rightCapImage.size.width, middleCapImage.size.height);
        
        self.capRight.image = rightCapImage;
        self.capRight.frame = NSMakeRect(frameRect.size.width - rightCapImage.size.width, 0, rightCapImage.size.width, rightCapImage.size.height);
        
        self.capLeft.hidden = YES;
        self.capMiddle.hidden = YES;
        self.capRight.hidden = YES;

    }
    
    return self;
}

- (void)mouseEntered:(NSEvent *)theEvent  {
    self.capLeft.hidden = NO;
    self.capMiddle.hidden = NO;
    self.capRight.hidden = NO;
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.capLeft.hidden = YES;
    self.capMiddle.hidden = YES;
    self.capRight.hidden = YES;
}

- (void)setEnabled:(BOOL)enabled {
    super.enabled = enabled;
}

@end
