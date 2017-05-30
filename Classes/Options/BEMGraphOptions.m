//
//  BEMGraphOptions.m
//  SimpleLineChart
//
//  Created by twidle on 5/25/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "BEMGraphOptions.h"

#define DEFAULT_FONT_NAME @"HelveticaNeue-Light"

@implementation BEMGraphOptions

- (instancetype)init {
  if (self = [super init]) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  // Do any initialization that's common to both -initWithFrame: and
  // -initWithCoder: in this method

  // Set the X Axis label font
  _labelFont = [UIFont fontWithName:DEFAULT_FONT_NAME size:13];

  // Set Animation Values
  _animationGraphEntranceTime = 1.5;

  // Set Color Values
  _colorXaxisLabel = [UIColor blackColor];
  _colorYaxisLabel = [UIColor blackColor];
  _colorTop =
      [UIColor colorWithRed:0 green:122.0 / 255.0 blue:255 / 255 alpha:1];
  _colorLine = [UIColor colorWithRed:255.0 / 255.0
                               green:255.0 / 255.0
                                blue:255.0 / 255.0
                               alpha:1];
  _colorBottom =
      [UIColor colorWithRed:0 green:122.0 / 255.0 blue:255 / 255 alpha:1];
  _colorPoint = [UIColor colorWithWhite:1.0 alpha:0.7];
  _colorTouchInputLine = [UIColor grayColor];
  _colorBackgroundPopUplabel = [UIColor whiteColor];
  _alphaTouchInputLine = 0.2;
  _widthTouchInputLine = 1.0;
  _colorBackgroundXaxis = nil;
  _alphaBackgroundXaxis = 1.0;
  _colorBackgroundYaxis = nil;
  _alphaBackgroundYaxis = 1.0;
  _displayDotsWhileAnimating = YES;

  // Set Alpha Values
  _alphaTop = 1.0;
  _alphaBottom = 1.0;
  _alphaLine = 1.0;

  // Set Size Values
  _widthLine = 1.0;
  _widthReferenceLines = 1.0;
  _sizePoint = 10.0;

  // Set Default Feature Values
  _enableTouchReport = NO;
  _touchReportFingersRequired = 1;
  _enablePopUpReport = NO;
  _enableBezierCurve = NO;
  _enableXAxisLabel = YES;
  _enableYAxisLabel = NO;
  _autoScaleYAxis = YES;
  _alwaysDisplayDots = NO;
  _alwaysDisplayPopUpLabels = NO;
  _enableLeftReferenceAxisFrameLine = YES;
  _enableBottomReferenceAxisFrameLine = YES;
  _formatStringForValues = @"%.0f";
  _interpolateNullValues = YES;
  _displayDotsOnly = NO;

  // Initialize BEM Objects
  _averageLine = [[BEMAverageLine alloc] init];
}

@end
