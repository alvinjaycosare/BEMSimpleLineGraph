//
//  BEMMultiLineGraphView.m
//  SimpleLineChart
//
//  Created by twidle on 5/25/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "BEMMultiLineGraphView.h"

#import "BEMGraphDataSet.h"
#import "BEMGraphOptions.h"

#import "BEMSimpleLineGraphView.h"

typedef NS_ENUM(NSInteger, BEMInternalTags) {
  DotFirstTag100 = 100,
  DotLastTag1000 = 1000,
  LabelYAxisTag2000 = 2000,
  BackgroundYAxisTag2100 = 2100,
  BackgroundXAxisTag2200 = 2200,
  PermanentPopUpViewTag3100 = 3100,
};

@interface BEMMultiLineGraphView ()

@property(strong, nonatomic) NSArray<BEMGraphDataSet *> *dataSets;

@property(nonatomic) NSUInteger numberOfPoints;
@property(nonatomic) NSUInteger maxNumberOfPoints;

@property(nonatomic) CGFloat maxValue;
@property(nonatomic) CGFloat minValue;

@property(nonatomic) CGFloat xAxisHorizontalFringeNegationValue;

@property(weak, nonatomic) UILabel *noDataLabel;

@property(nonatomic) CGFloat YAxisLabelXOffset;
@property(nonatomic) CGFloat XAxisLabelXOffset;

@property(nonatomic) CGFloat YAxisLabelYOffset;
@property(nonatomic) CGFloat XAxisLabelYOffset;

@property(nonatomic) NSMutableArray *xAxisLabels;
@property(nonatomic) NSMutableArray *xAxisValues;

@property (nonatomic) CGFloat xCenterLabel;
@property (nonatomic) CGFloat yCenterLabel;

@property(nonatomic) NSMutableArray *yAxisLabels;
@property(nonatomic) NSMutableArray *yAxisValues;

@property(nonatomic) NSMutableArray *xAxisLabelPoints;
@property(nonatomic) NSMutableArray *yAxisLabelPoints;

@property(nonatomic) CGRect drawableGraphArea;

@property(weak, nonatomic) UIView *backgroundXAxis;

/// The vertical line which appears when the user drags across the graph
@property(strong, nonatomic) UIView *touchInputLine;

/// View for picking up pan gesture
@property(strong, nonatomic, readwrite) UIView *panView;

/// The gesture recognizer picking up the pan in the graph view
@property(strong, nonatomic) UIPanGestureRecognizer *panGesture;

/// This gesture recognizer picks up the initial touch on the graph view
@property(nonatomic) UILongPressGestureRecognizer *longPressGesture;

/// The label displayed when enablePopUpReport is set to YES
@property(strong, nonatomic) UILabel *popUpLabel;

/// The view used for the background of the popup label
@property(strong, nonatomic) UIView *popUpView;

// Tracks whether the popUpView is custom or default
@property(nonatomic) BOOL usingCustomPopupView;

@end

@implementation BEMMultiLineGraphView

- (instancetype)init {
  if (self = [super init]) {
    [self onInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self onInit];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self onInit];
  }
  return self;
}

- (void)onInit {

  self.numberOfPoints = NSUIntegerMax;
  self.maxNumberOfPoints = NSUIntegerMax;
}

#pragma mark - Setters

- (void)setOptions:(BEMGraphOptions *)options {
  _options = options;

  [self setupConstant];
}

- (void)setupConstant {
  CGFloat YAxisLabelXOffset =
      self.options.overlapYAxisWithGraph ? 0 : self.YAxisLabelXOffset;

  NSInteger xAxisHeight = 20;
  CGFloat xOrigin = self.options.positionYAxisRight ? 0 : YAxisLabelXOffset;
  CGFloat viewWidth = self.frame.size.width - YAxisLabelXOffset;
  CGFloat adjustedHeight = self.bounds.size.height - xAxisHeight;

  CGRect rect = CGRectMake(xOrigin, 0, viewWidth, adjustedHeight);
  self.drawableGraphArea = rect;

  [self onInit];
}

- (void)reloadGraph {
  [self removeGraphViewsIfNeeded];
  [self setupGraphData];
  [self drawGraph];
}

- (void)setupGraphData {
  NSMutableArray<BEMGraphDataSet *> *dataSets = [NSMutableArray array];
  for (NSUInteger i = 0; i < [self.dataSource numberOfLinesInGraph]; i++) {
    [dataSets addObject:[self.dataSource lineGraph:self
                            dataSetForPointAtLineSection:i]];
  }
  self.dataSets = dataSets;
}

#pragma mark - Draw

- (void)drawGraph {
  // Let the delegate know that the graph began layout updates
  if ([self.delegate respondsToSelector:@selector(lineGraphDidBeginLoading:)])
    [self.delegate lineGraphDidBeginLoading:self];

  // Get the number of points in the graph
  [self layoutNumberOfPoints];

  if (self.numberOfPoints <= 1) {
    return;
  } else {
    // Draw the graph
    [self drawEntireGraph];

    // Setup the touch report
    [self layoutTouchReport];

    // Let the delegate know that the graph finished updates
    if ([self.delegate
            respondsToSelector:@selector(lineGraphDidFinishLoading:)])
      [self.delegate lineGraphDidFinishLoading:self];
  }
}

- (void)removeGraphViewsIfNeeded {
  // Remove all dots that were previously on the graph
  for (UILabel *subview in [self subviews]) {

    if ([subview isEqual:self.noDataLabel])
      [subview removeFromSuperview];
    else if ([subview isKindOfClass:[UILabel class]] &&
             subview.tag == DotLastTag1000)
      [subview removeFromSuperview];
    else if ([subview isKindOfClass:[UIView class]] &&
             subview.tag == BackgroundXAxisTag2200)
      [subview removeFromSuperview];
  }
}

#pragma mark - Layout

- (void)layoutNumberOfPoints {
  // Get the total number of data points from the delegate
  //    if ([self.dataSource
  //    respondsToSelector:@selector(numberOfPointsInLineGraph:)]) {
  //        numberOfPoints = [self.dataSource numberOfPointsInLineGraph:self];
  //
  //    } else if ([self.delegate
  //    respondsToSelector:@selector(numberOfPointsInGraph)]) {
  //        [self printDeprecationWarningForOldMethod:@"numberOfPointsInGraph"
  //        andReplacementMethod:@"numberOfPointsInLineGraph:"];
  //
  //#pragma clang diagnostic push
  //#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  //        numberOfPoints = [self.delegate numberOfPointsInGraph];
  //#pragma clang diagnostic pop
  //
  //    } else if ([self.delegate
  //    respondsToSelector:@selector(numberOfPointsInLineGraph:)]) {
  //        [self
  //        printDeprecationAndUnavailableWarningForOldMethod:@"numberOfPointsInLineGraph:"];
  //        numberOfPoints = 0;
  //
  //    } else numberOfPoints = 0;

  // There are no points to load

  if (self.numberOfPoints == 0) {
    //        if (self.delegate &&
    //            [self.delegate
    //            respondsToSelector:@selector(noDataLabelEnableForLineGraph:)]
    //            &&
    //            ![self.delegate noDataLabelEnableForLineGraph:self]) return;

    NSLog(@"[BEMSimpleLineGraph] Data source contains no data. A no data label "
          @"will be displayed and drawing will stop. Add data to the data "
          @"source and then reload the graph.");

    UILabel *noDataLabel = nil;

#if !TARGET_INTERFACE_BUILDER
    noDataLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(0, 0,
                                 self.viewForBaselineLayout.frame.size.width,
                                 self.viewForBaselineLayout.frame.size.height)];
#else
    noDataLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(
                          0, 0, self.viewForBaselineLayout.frame.size.width,
                          self.viewForBaselineLayout.frame.size.height -
                              (self.viewForBaselineLayout.frame.size.height /
                               4))];
#endif

    noDataLabel.backgroundColor = [UIColor clearColor];
    noDataLabel.textAlignment = NSTextAlignmentCenter;

#if !TARGET_INTERFACE_BUILDER
    NSString *noDataText;
    if ([self.delegate
            respondsToSelector:@selector(noDataLabelTextForLineGraph:)]) {
      noDataText = [self.delegate noDataLabelTextForLineGraph:self];
    }
    noDataLabel.text = noDataText ?: NSLocalizedString(@"No Data", nil);
#else
    noDataLabel.text = @"Data is not loaded in Interface Builder";
#endif
    noDataLabel.font =
        self.options.noDataLabelFont
            ?: [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
    noDataLabel.textColor =
        self.options.noDataLabelColor ?: self.options.colorLine;

    [self.viewForBaselineLayout addSubview:noDataLabel];
    self.noDataLabel = noDataLabel;

    // Let the delegate know that the graph finished layout updates
    if ([self.delegate
            respondsToSelector:@selector(lineGraphDidFinishLoading:)])
      [self.delegate lineGraphDidFinishLoading:self];
    return;

  } else if (self.numberOfPoints == 1) {
    NSLog(@"[BEMSimpleLineGraph] Data source contains only one data point. Add "
          @"more data to the data source and then reload the graph.");
    BEMCircle *circleDot = [[BEMCircle alloc]
        initWithFrame:CGRectMake(0, 0, self.options.sizePoint,
                                 self.options.sizePoint)];
    circleDot.center =
        CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    circleDot.Pointcolor = self.options.colorPoint;
    circleDot.alpha = 1;
    [self addSubview:circleDot];
    return;
  }
}

- (void)layoutTouchReport {
  // If the touch report is enabled, set it up
  if (self.options.enableTouchReport == YES ||
      self.options.enablePopUpReport == YES) {
    // Initialize the vertical gray line that appears where the user touches the
    // graph.
    self.touchInputLine = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, self.options.widthTouchInputLine,
                                 self.frame.size.height)];
    self.touchInputLine.backgroundColor = self.options.colorTouchInputLine;
    self.touchInputLine.alpha = 0;
    [self addSubview:self.touchInputLine];

    self.panView = [[UIView alloc]
        initWithFrame:CGRectMake(10, 10,
                                 self.viewForBaselineLayout.frame.size.width,
                                 self.viewForBaselineLayout.frame.size.height)];
    self.panView.backgroundColor = [UIColor clearColor];
    [self.viewForBaselineLayout addSubview:self.panView];

    self.panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleGestureAction:)];
    self.panGesture.delegate = self;
    [self.panGesture setMaximumNumberOfTouches:1];
    [self.panView addGestureRecognizer:self.panGesture];

    self.longPressGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleGestureAction:)];
    self.longPressGesture.minimumPressDuration = 0.1f;
    [self.panView addGestureRecognizer:self.longPressGesture];

    if (self.options.enablePopUpReport == YES &&
        self.options.alwaysDisplayPopUpLabels == NO) {
      if ([self.delegate
              respondsToSelector:@selector(popUpViewForLineGraph:)]) {
        self.popUpView = [self.delegate popUpViewForLineGraph:self];
        self.usingCustomPopupView = YES;
        self.popUpView.alpha = 0;
        [self addSubview:self.popUpView];
      } else {
        NSString *maxValueString = [NSString
            stringWithFormat:self.options.formatStringForValues, self.maxValue];
        NSString *minValueString = [NSString
            stringWithFormat:self.options.formatStringForValues, self.maxValue];

        NSString *longestString = @"";
        if (maxValueString.length > minValueString.length) {
          longestString = maxValueString;
        } else {
          longestString = minValueString;
        }

        NSString *prefix = @"";
        NSString *suffix = @"";
        if ([self.delegate
                respondsToSelector:@selector(popUpSuffixForlineGraph:)]) {
          suffix = [self.delegate popUpSuffixForlineGraph:self];
        }
        if ([self.delegate
                respondsToSelector:@selector(popUpPrefixForlineGraph:)]) {
          prefix = [self.delegate popUpPrefixForlineGraph:self];
        }

        NSString *fullString = [NSString
            stringWithFormat:@"%@%@%@", prefix, longestString, suffix];

        NSString *mString = [fullString
            stringByReplacingOccurrencesOfString:@"[0-9-]"
                                      withString:@"N"
                                         options:NSRegularExpressionSearch
                                           range:NSMakeRange(
                                                     0,
                                                     [longestString length])];

        self.popUpLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        self.popUpLabel.text = mString;
        self.popUpLabel.textAlignment = 1;
        self.popUpLabel.numberOfLines = 1;
        self.popUpLabel.font = self.options.labelFont;
        self.popUpLabel.backgroundColor = [UIColor clearColor];
        [self.popUpLabel sizeToFit];
        self.popUpLabel.alpha = 0;

        self.popUpView = [[UIView alloc]
            initWithFrame:CGRectMake(0, 0,
                                     self.popUpLabel.frame.size.width + 10,
                                     self.popUpLabel.frame.size.height + 2)];
        self.popUpView.backgroundColor = self.options.colorBackgroundPopUplabel;
        self.popUpView.alpha = 0;
        self.popUpView.layer.cornerRadius = 3;
        [self addSubview:self.popUpView];
        [self addSubview:self.popUpLabel];
      }
    }
  }
}

#pragma mark - Draw

- (void)drawEntireGraph {
  // The following method calls are in this specific order for a reason
  // Changing the order of the method calls below can result in drawing glitches
  // and even crashes

  self.maxValue = self.maxValue;
  self.minValue = self.minValue;

  // Set the Y-Axis Offset if the Y-Axis is enabled. The offset is relative to
  // the size of the longest label on the Y-Axis.
  if (self.options.enableYAxisLabel) {
    NSDictionary *attributes = @{NSFontAttributeName : self.options.labelFont};
    if (self.options.autoScaleYAxis == YES) {
      NSString *maxValueString = [NSString
          stringWithFormat:self.options.formatStringForValues, self.maxValue];
      NSString *minValueString = [NSString
          stringWithFormat:self.options.formatStringForValues, self.minValue];

      NSString *longestString = @"";
      if (maxValueString.length > minValueString.length)
        longestString = maxValueString;
      else
        longestString = minValueString;

      NSString *prefix = @"";
      NSString *suffix = @"";

      if ([self.delegate
              respondsToSelector:@selector(yAxisPrefixOnLineGraph:)]) {
        prefix = [self.delegate yAxisPrefixOnLineGraph:self];
      }

      if ([self.delegate
              respondsToSelector:@selector(yAxisSuffixOnLineGraph:)]) {
        suffix = [self.delegate yAxisSuffixOnLineGraph:self];
      }

      NSString *mString = [longestString
          stringByReplacingOccurrencesOfString:@"[0-9-]"
                                    withString:@"N"
                                       options:NSRegularExpressionSearch
                                         range:NSMakeRange(
                                                   0, [longestString length])];
      NSString *fullString =
          [NSString stringWithFormat:@"%@%@%@", prefix, mString, suffix];
      self.YAxisLabelXOffset =
          [fullString sizeWithAttributes:attributes].width +
          2; // MAX([maxValueString sizeWithAttributes:attributes].width + 10,
      //    [minValueString sizeWithAttributes:attributes].width) + 5;
    } else {
      NSString *longestString =
          [NSString stringWithFormat:@"%i", (int)self.frame.size.height];
      self.YAxisLabelXOffset =
          [longestString sizeWithAttributes:attributes].width + 5;
    }

    [self drawYAxis];
  } else
    self.YAxisLabelXOffset = 0;

  // Draw the X-Axis
  [self drawXAxis];

  // Draw the graph
  [self drawDots];
}

- (void)drawXAxis {
  if (!self.options.enableXAxisLabel)
    return;
  if (![self.dataSource
          respondsToSelector:@selector(lineGraph:labelOnXAxisForIndex:)])
    return;

  // Remove all X-Axis Labels before adding them to the array
  [self.xAxisValues removeAllObjects];
  [self.xAxisLabels removeAllObjects];
  [self.xAxisLabelPoints removeAllObjects];
  self.xAxisHorizontalFringeNegationValue = 0.0;

  // Draw X-Axis Background Area

  CGFloat YAxisLabelXOffset =
      self.options.overlapYAxisWithGraph ? 0 : self.YAxisLabelXOffset;

  NSInteger xAxisHeight = 20;
  NSInteger xAxisWidth = self.drawableGraphArea.size.width + 1;
  CGFloat xAxisXOrigin =
      self.options.positionYAxisRight ? 0 : YAxisLabelXOffset;
  CGFloat xAxisYOrigin = self.bounds.size.height - xAxisHeight;
  CGRect drawableArea =
      CGRectMake(xAxisXOrigin, xAxisYOrigin, xAxisWidth, xAxisHeight);

  UIView *backgroundXAxis = [[UIView alloc] initWithFrame:drawableArea];

  backgroundXAxis.tag = BackgroundXAxisTag2200;
  if (self.options.colorBackgroundXaxis == nil)
    self.backgroundXAxis.backgroundColor = self.options.colorBottom;
  else
    backgroundXAxis.backgroundColor = self.options.colorBackgroundXaxis;
  self.backgroundXAxis.alpha = self.options.alphaBackgroundXaxis;
  [self addSubview:self.backgroundXAxis];

  NSMutableArray *xAxisLabels = [NSMutableArray array];
  NSMutableArray *xAxisLabelPoints = [NSMutableArray array];
  NSMutableArray *xAxisValues = [NSMutableArray array];

  if ([self.delegate
          respondsToSelector:@selector(
                                 incrementPositionsForXAxisOnLineGraph:)]) {
    NSArray *axisValues =
        [self.delegate incrementPositionsForXAxisOnLineGraph:self];
    for (NSNumber *increment in axisValues) {
      NSInteger index = increment.integerValue;
      NSString *xAxisLabelText = [self xAxisTextForIndex:index];

      UILabel *labelXAxis =
          [self xAxisLabelWithText:xAxisLabelText atIndex:index];
      [xAxisLabels addObject:labelXAxis];

      if (self.options.positionYAxisRight) {
        NSNumber *xAxisLabelCoordinate =
            [NSNumber numberWithFloat:labelXAxis.center.x];
        [xAxisLabelPoints addObject:xAxisLabelCoordinate];
      } else {

        CGFloat YAxisLabelXOffset =
            self.options.overlapYAxisWithGraph ? 0 : self.YAxisLabelXOffset;
        NSNumber *xAxisLabelCoordinate =
            [NSNumber numberWithFloat:labelXAxis.center.x - YAxisLabelXOffset];
        [xAxisLabelPoints addObject:xAxisLabelCoordinate];
      }

      [self addSubview:labelXAxis];
      [xAxisValues addObject:xAxisLabelText];
    }

  } else if ([self.delegate
                 respondsToSelector:@selector(baseIndexForXAxisOnLineGraph:)] &&
             [self.delegate
                 respondsToSelector:@selector(
                                        incrementIndexForXAxisOnLineGraph:)]) {
    NSInteger baseIndex = [self.delegate baseIndexForXAxisOnLineGraph:self];
    NSInteger increment =
        [self.delegate incrementIndexForXAxisOnLineGraph:self];

    NSInteger startingIndex = baseIndex;
    while (startingIndex < self.maxNumberOfPoints) {

      NSString *xAxisLabelText = [self xAxisTextForIndex:startingIndex];

      UILabel *labelXAxis =
          [self xAxisLabelWithText:xAxisLabelText atIndex:startingIndex];
      [xAxisLabels addObject:labelXAxis];

      if (self.options.positionYAxisRight) {
        NSNumber *xAxisLabelCoordinate =
            [NSNumber numberWithFloat:labelXAxis.center.x];
        [xAxisLabelPoints addObject:xAxisLabelCoordinate];
      } else {
        NSNumber *xAxisLabelCoordinate = [NSNumber
            numberWithFloat:labelXAxis.center.x - self.YAxisLabelXOffset];
        [xAxisLabelPoints addObject:xAxisLabelCoordinate];
      }

      [self addSubview:labelXAxis];
      [xAxisValues addObject:xAxisLabelText];

      startingIndex += increment;
    }
  } else {
    NSInteger numberOfGaps = 1;

    if ([self.delegate
            respondsToSelector:@selector(
                                   numberOfGapsBetweenLabelsOnLineGraph:)]) {
      numberOfGaps =
          [self.delegate numberOfGapsBetweenLabelsOnLineGraph:self] + 1;
    } else {
      numberOfGaps = 1;
    }

    if (numberOfGaps >= (self.maxNumberOfPoints - 1)) {
      NSString *firstXLabel = [self xAxisTextForIndex:0];
      NSString *lastXLabel =
          [self xAxisTextForIndex:self.maxNumberOfPoints - 1];

      CGFloat viewWidth = self.frame.size.width - self.YAxisLabelXOffset;

      CGFloat xAxisXPositionFirstOffset;
      CGFloat xAxisXPositionLastOffset;
      if (self.options.positionYAxisRight) {
        xAxisXPositionFirstOffset = 3;
        xAxisXPositionLastOffset =
            xAxisXPositionFirstOffset + 1 + viewWidth / 2;
      } else {
        xAxisXPositionFirstOffset = 3 + self.YAxisLabelXOffset;
        xAxisXPositionLastOffset =
            viewWidth / 2 + xAxisXPositionFirstOffset + 1;
      }
      UILabel *firstLabel = [self xAxisLabelWithText:firstXLabel atIndex:0];
      firstLabel.frame =
          CGRectMake(xAxisXPositionFirstOffset, self.frame.size.height - 20,
                     viewWidth / 2, 20);

      firstLabel.textAlignment = NSTextAlignmentLeft;
      [self addSubview:firstLabel];
      [xAxisValues addObject:firstXLabel];
      [xAxisLabels addObject:firstLabel];

      UILabel *lastLabel = [self xAxisLabelWithText:lastXLabel
                                            atIndex:self.maxNumberOfPoints - 1];
      lastLabel.frame =
          CGRectMake(xAxisXPositionLastOffset, self.frame.size.height - 20,
                     viewWidth / 2 - 4, 20);
      lastLabel.textAlignment = NSTextAlignmentRight;
      [self addSubview:lastLabel];
      [xAxisValues addObject:lastXLabel];
      [xAxisLabels addObject:lastLabel];

      if (self.options.positionYAxisRight) {
        NSNumber *xFirstAxisLabelCoordinate = @(firstLabel.center.x);
        NSNumber *xLastAxisLabelCoordinate = @(lastLabel.center.x);
        [xAxisLabelPoints addObject:xFirstAxisLabelCoordinate];
        [xAxisLabelPoints addObject:xLastAxisLabelCoordinate];
      } else {
        NSNumber *xFirstAxisLabelCoordinate =
            @(firstLabel.center.x - self.YAxisLabelXOffset);
        NSNumber *xLastAxisLabelCoordinate =
            @(lastLabel.center.x - self.YAxisLabelXOffset);
        [xAxisLabelPoints addObject:xFirstAxisLabelCoordinate];
        [xAxisLabelPoints addObject:xLastAxisLabelCoordinate];
      }
    } else {
      @autoreleasepool {
        NSInteger offset = [self
            offsetForXAxisWithNumberOfGaps:numberOfGaps]; // The offset (if
                                                          // possible and
                                                          // necessary) used to
                                                          // shift the Labels on
                                                          // the X-Axis for them
                                                          // to be centered.

        for (int i = 1; i <= (self.maxNumberOfPoints / numberOfGaps); i++) {
          NSInteger index = i * numberOfGaps - 1 - offset;
          NSString *xAxisLabelText = [self xAxisTextForIndex:index];

          UILabel *labelXAxis =
              [self xAxisLabelWithText:xAxisLabelText atIndex:index];
          [xAxisLabels addObject:labelXAxis];

          if (self.options.positionYAxisRight) {
            NSNumber *xAxisLabelCoordinate =
                [NSNumber numberWithFloat:labelXAxis.center.x];
            [xAxisLabelPoints addObject:xAxisLabelCoordinate];
          } else {
            NSNumber *xAxisLabelCoordinate = [NSNumber
                numberWithFloat:labelXAxis.center.x - self.YAxisLabelXOffset];
            [xAxisLabelPoints addObject:xAxisLabelCoordinate];
          }

          [self addSubview:labelXAxis];
          [xAxisValues addObject:xAxisLabelText];
        }
      }
    }
  }
  __block NSUInteger lastMatchIndex;

  if (!self.options.allowOverlappingLabels) {
    NSMutableArray *overlapLabels = [NSMutableArray arrayWithCapacity:0];
    [xAxisLabels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx,
                                              BOOL *stop) {
      if (idx == 0) {
        lastMatchIndex = 0;
      } else { // Skip first one
        UILabel *prevLabel = [xAxisLabels objectAtIndex:lastMatchIndex];
        CGRect r = CGRectIntersection(prevLabel.frame, label.frame);
        if (CGRectIsNull(r))
          lastMatchIndex = idx;
        else
          [overlapLabels addObject:label]; // Overlapped
      }

      BOOL fullyContainsLabel = CGRectContainsRect(self.bounds, label.frame);
      if (!fullyContainsLabel) {
        [overlapLabels addObject:label];
      }
    }];

    for (UILabel *l in overlapLabels) {
      [l removeFromSuperview];
    }
  }
}

- (void)drawYAxis {
  for (UIView *subview in [self subviews]) {
    if ([subview isKindOfClass:[UILabel class]] &&
        subview.tag == LabelYAxisTag2000) {
      [subview removeFromSuperview];
    } else if ([subview isKindOfClass:[UIView class]] &&
               subview.tag == BackgroundYAxisTag2100) {
      [subview removeFromSuperview];
    }
  }

  CGRect frameForBackgroundYAxis;
  CGRect frameForLabelYAxis;
  CGFloat xValueForCenterLabelYAxis;
  NSTextAlignment textAlignmentForLabelYAxis;

  if (self.options.positionYAxisRight) {
    frameForBackgroundYAxis =
        CGRectMake(self.frame.size.width - self.YAxisLabelXOffset, 0,
                   self.YAxisLabelXOffset, self.frame.size.height);
    frameForLabelYAxis =
        CGRectMake(self.frame.size.width - self.YAxisLabelXOffset - 5, 0,
                   self.YAxisLabelXOffset - 5, 15);
    xValueForCenterLabelYAxis =
        self.frame.size.width - self.YAxisLabelXOffset / 2;
    textAlignmentForLabelYAxis = NSTextAlignmentRight;
  } else {
    frameForBackgroundYAxis =
        CGRectMake(0, 0, self.YAxisLabelXOffset, self.frame.size.height);
    frameForLabelYAxis = CGRectMake(0, 0, self.YAxisLabelXOffset - 5, 15);
    xValueForCenterLabelYAxis =
        (self.YAxisLabelXOffset / 2) + self.options.marginLeftYAxisLabel;
    textAlignmentForLabelYAxis = NSTextAlignmentRight;
  }

  if (!self.options.overlapYAxisWithGraph) {
    UIView *backgroundYaxis =
        [[UIView alloc] initWithFrame:frameForBackgroundYAxis];
    backgroundYaxis.tag = BackgroundYAxisTag2100;
    if (self.options.colorBackgroundYaxis == nil)
      backgroundYaxis.backgroundColor = self.options.colorTop;
    else
      backgroundYaxis.backgroundColor = self.options.colorBackgroundYaxis;
    backgroundYaxis.alpha = self.options.alphaBackgroundYaxis;
    [self addSubview:backgroundYaxis];
  }

  NSMutableArray *yAxisLabels = [NSMutableArray arrayWithCapacity:0];
  [self.yAxisLabelPoints removeAllObjects];

  NSString *yAxisSuffix = @"";
  NSString *yAxisPrefix = @"";

  if ([self.delegate respondsToSelector:@selector(yAxisPrefixOnLineGraph:)])
    yAxisPrefix = [self.delegate yAxisPrefixOnLineGraph:self];
  if ([self.delegate respondsToSelector:@selector(yAxisSuffixOnLineGraph:)])
    yAxisSuffix = [self.delegate yAxisSuffixOnLineGraph:self];

  if (self.options.autoScaleYAxis) {
    // Plot according to min-max range
    NSNumber *minimumValue = @(self.minValue);
    NSNumber *maximumValue = @(self.maxValue);

    CGFloat numberOfLabels;
    if ([self.delegate
            respondsToSelector:@selector(numberOfYAxisLabelsOnLineGraph:)]) {
      numberOfLabels = [self.delegate numberOfYAxisLabelsOnLineGraph:self];
    } else
      numberOfLabels = 3;

    NSMutableArray *dotValues =
        [[NSMutableArray alloc] initWithCapacity:numberOfLabels];
    if ([self.delegate
            respondsToSelector:@selector(baseValueForYAxisOnLineGraph:)] &&
        [self.delegate
            respondsToSelector:@selector(incrementValueForYAxisOnLineGraph:)]) {
      CGFloat baseValue = [self.delegate baseValueForYAxisOnLineGraph:self];
      CGFloat increment =
          [self.delegate incrementValueForYAxisOnLineGraph:self];

      float yAxisPosition = baseValue;
      if (baseValue + increment * 100 < maximumValue.doubleValue) {
        NSLog(@"[BEMSimpleLineGraph] Increment does not properly lay out Y "
              @"axis, bailing early");
        return;
      }

      while (yAxisPosition < maximumValue.floatValue + increment) {
        [dotValues addObject:@(yAxisPosition)];
        yAxisPosition += increment;
      }
    } else if (numberOfLabels <= 0)
      return;
    else if (numberOfLabels == 1) {
      [dotValues removeAllObjects];
      [dotValues addObject:[NSNumber numberWithInt:(minimumValue.intValue +
                                                    maximumValue.intValue) /
                                                   2]];
    } else {
      [dotValues addObject:minimumValue];
      [dotValues addObject:maximumValue];
      for (int i = 1; i < numberOfLabels - 1; i++) {
        [dotValues
            addObject:[NSNumber numberWithFloat:(minimumValue.doubleValue +
                                                 ((maximumValue.doubleValue -
                                                   minimumValue.doubleValue) /
                                                  (numberOfLabels - 1)) *
                                                     i)]];
      }
    }

    for (NSNumber *dotValue in dotValues) {
      CGFloat yAxisPosition = [self yPositionForDotValue:dotValue.floatValue];
      UILabel *labelYAxis = [[UILabel alloc] initWithFrame:frameForLabelYAxis];
      NSString *formattedValue =
          [self formattedYLabelTextWithValue:dotValue.doubleValue];
      labelYAxis.text = [NSString
          stringWithFormat:@"%@%@%@", yAxisPrefix, formattedValue, yAxisSuffix];
      labelYAxis.textAlignment = self.options.alignmentYAxisLabel;
      labelYAxis.font = self.options.labelFont;
      labelYAxis.textColor = self.options.colorYaxisLabel;
      labelYAxis.backgroundColor = [UIColor clearColor];
      labelYAxis.tag = LabelYAxisTag2000;
      labelYAxis.center = CGPointMake(xValueForCenterLabelYAxis, yAxisPosition);
      [self addSubview:labelYAxis];
      [yAxisLabels addObject:labelYAxis];

      NSNumber *yAxisLabelCoordinate = @(labelYAxis.center.y);
      [self.yAxisLabelPoints addObject:yAxisLabelCoordinate];
    }
  } else {
    NSInteger numberOfLabels;
    if ([self.delegate
            respondsToSelector:@selector(numberOfYAxisLabelsOnLineGraph:)])
      numberOfLabels = [self.delegate numberOfYAxisLabelsOnLineGraph:self];
    else
      numberOfLabels = 3;

    CGFloat graphHeight = self.frame.size.height;
    CGFloat graphSpacing =
        (graphHeight - self.XAxisLabelYOffset) / numberOfLabels;

    CGFloat yAxisPosition =
        graphHeight - self.XAxisLabelYOffset + graphSpacing / 2;

    for (NSInteger i = numberOfLabels; i > 0; i--) {
      yAxisPosition -= graphSpacing;

      UILabel *labelYAxis = [[UILabel alloc] initWithFrame:frameForLabelYAxis];
      labelYAxis.center = CGPointMake(xValueForCenterLabelYAxis, yAxisPosition);
      labelYAxis.text = [self
          formattedYLabelTextWithValue:(graphHeight - self.XAxisLabelYOffset -
                                        yAxisPosition)];
      labelYAxis.font = self.options.labelFont;
      labelYAxis.textAlignment = self.options.alignmentYAxisLabel;
      labelYAxis.textColor = self.options.colorYaxisLabel;
      labelYAxis.backgroundColor = [UIColor clearColor];
      labelYAxis.tag = LabelYAxisTag2000;

      //            [self addSubview:labelYAxis];

      [yAxisLabels addObject:labelYAxis];

      NSNumber *yAxisLabelCoordinate = @(labelYAxis.center.y);
      [self.yAxisLabelPoints addObject:yAxisLabelCoordinate];
    }
  }

  // Detect overlapped labels
  __block NSUInteger lastMatchIndex = 0;
  NSMutableArray *overlapLabels = [NSMutableArray arrayWithCapacity:0];

  [yAxisLabels
      enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {

        if (idx == 0)
          lastMatchIndex = 0;
        else { // Skip first one
          UILabel *prevLabel = yAxisLabels[lastMatchIndex];
          CGRect r = CGRectIntersection(prevLabel.frame, label.frame);
          if (CGRectIsNull(r))
            lastMatchIndex = idx;
          else
            [overlapLabels addObject:label]; // overlapped
        }

        // Axis should fit into our own view
        BOOL fullyContainsLabel = CGRectContainsRect(self.bounds, label.frame);
        if (!fullyContainsLabel) {
          [overlapLabels addObject:label];
          [self.yAxisLabelPoints removeObject:@(label.center.y)];
        }
      }];

  for (UILabel *label in overlapLabels) {
    [label removeFromSuperview];
  }

  [self didFinishDrawingIncludingYAxis:YES];
}

- (void)drawDots {
  CGFloat positionOnXAxis; // The position on the X-axis of the point currently
                           // being created.
  CGFloat positionOnYAxis; // The position on the Y-axis of the point currently
                           // being created.

  // Remove all dots that were previously on the graph
  for (UIView *subview in [self subviews]) {
    if ([subview isKindOfClass:[BEMCircle class]] ||
        [subview isKindOfClass:[BEMPermanentPopupView class]] ||
        [subview isKindOfClass:[BEMPermanentPopupLabel class]])
      [subview removeFromSuperview];
  }

  //    // Remove all data points before adding them to the array
  //    [dataPoints removeAllObjects];

  // Remove all yAxis values before adding them to the array
  [self.yAxisValues removeAllObjects];

  // Loop through each point and add it to the graph
  @autoreleasepool {

    for (int i = 0; i < self.maxNumberOfPoints; i++) {
      CGFloat dotValue = 0;

#if !TARGET_INTERFACE_BUILDER
      if ([self.dataSource
              respondsToSelector:@selector(lineGraph:valueForPointAtIndex:)]) {
        dotValue = [self.dataSource lineGraph:self valueForPointAtIndex:i];

      } else if ([self.delegate respondsToSelector:@selector(valueForIndex:)]) {
        [self printDeprecationWarningForOldMethod:@"valueForIndex:"
                             andReplacementMethod:
                                 @"lineGraph:valueForPointAtIndex:"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dotValue = [self.delegate valueForIndex:i];
#pragma clang diagnostic pop

      } else if ([self.delegate
                     respondsToSelector:@selector(lineGraph:
                                            valueForPointAtIndex:)]) {
        [self printDeprecationAndUnavailableWarningForOldMethod:
                  @"lineGraph:valueForPointAtIndex:"];
        NSException *exception = [NSException
            exceptionWithName:@"Implementing Unavailable Delegate Method"
                       reason:@"lineGraph:valueForPointAtIndex: is no longer "
                              @"available on the delegate. It must be "
                              @"implemented on the data source."
                     userInfo:nil];
        [exception raise];

      } else
        [NSException raise:@"lineGraph:valueForPointAtIndex: protocol method "
                           @"is not implemented in the data source. Throwing "
                           @"exception here before the system throws a "
                           @"CALayerInvalidGeometry Exception."
                    format:@"Value for point %f at index %lu is invalid. "
                           @"CALayer position may contain NaN: [0 nan]",
                           dotValue, (unsigned long)i];
#else
      dotValue = (int)(arc4random() % 10000);
#endif
      //            [dataPoints addObject:@(dotValue)];

      CGFloat YAxisLabelXOffset =
          self.options.overlapYAxisWithGraph ? 0 : self.YAxisLabelXOffset;

      if (self.options.positionYAxisRight) {
        positionOnXAxis = (((self.frame.size.width - YAxisLabelXOffset) /
                            (self.maxNumberOfPoints - 1)) *
                           i);
      } else {
        positionOnXAxis = (((self.frame.size.width - YAxisLabelXOffset) /
                            (self.maxNumberOfPoints - 1)) *
                           i) +
                          YAxisLabelXOffset;
      }

      positionOnYAxis = [self yPositionForDotValue:dotValue];

      [self.yAxisValues addObject:@(positionOnYAxis)];

      // If we're dealing with an null value, don't draw the dot

      if (dotValue != BEMNullGraphValue) {
        BEMCircle *circleDot = [[BEMCircle alloc]
            initWithFrame:CGRectMake(0, 0, self.options.sizePoint,
                                     self.options.sizePoint)];
        circleDot.center = CGPointMake(positionOnXAxis, positionOnYAxis);
        circleDot.tag = i + DotFirstTag100;
        circleDot.alpha = 0;
        circleDot.absoluteValue = dotValue;
        circleDot.Pointcolor = self.options.colorPoint;

        [self addSubview:circleDot];
        if (self.options.alwaysDisplayPopUpLabels == YES) {
          if ([self.delegate
                  respondsToSelector:@selector(lineGraph:
                                         alwaysDisplayPopUpAtIndex:)]) {
            if ([self.delegate lineGraph:self alwaysDisplayPopUpAtIndex:i] ==
                YES) {
              [self displayPermanentLabelForPoint:circleDot];
            }
          } else
            [self displayPermanentLabelForPoint:circleDot];
        }

        BOOL shouldHideDot = NO;
        if ([self.delegate
                respondsToSelector:@selector(lineGraph:hideDotAtIndex:)])
          shouldHideDot = [self.delegate lineGraph:self hideDotAtIndex:i];

        // Dot entrance animation
        if (self.options.animationGraphEntranceTime == 0) {
          if (self.options.displayDotsOnly == YES)
            circleDot.alpha = 1.0;
          else {
            if (self.options.alwaysDisplayDots == NO || shouldHideDot)
              circleDot.alpha = 0;
            else
              circleDot.alpha = 1.0;
          }
        } else {
          if (self.options.displayDotsWhileAnimating && !shouldHideDot) {
            [UIView
                animateWithDuration:self.options.animationGraphEntranceTime /
                                    self.maxNumberOfPoints
                delay:(float)i * ((float)self.options.animationGraphEntranceTime /
                                  self.maxNumberOfPoints)
                options:UIViewAnimationOptionCurveLinear
                animations:^{
                  circleDot.alpha = 1.0;
                }
                completion:^(BOOL finished) {
                  if (self.options.alwaysDisplayDots == NO &&
                      self.options.displayDotsOnly == NO) {
                    [UIView
                        animateWithDuration:0.3
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                   circleDot.alpha = 0;
                                 }
                                 completion:nil];
                  }
                }];
          }
        }
      }
    }
  }

  // CREATION OF THE LINE AND BOTTOM AND TOP FILL
  [self drawLine];
}

- (void)drawLine {
  
}

#pragma mark - Misc

- (void)displayPermanentLabelForPoint:(BEMCircle *)circleDot {
  self.options.enablePopUpReport = NO;
  self.xCenterLabel = circleDot.center.x;

  BEMPermanentPopupLabel *permanentPopUpLabel =
      [[BEMPermanentPopupLabel alloc] init];
  permanentPopUpLabel.textAlignment = NSTextAlignmentCenter;
  permanentPopUpLabel.numberOfLines = 0;

  NSString *prefix = @"";
  NSString *suffix = @"";

  if ([self.delegate respondsToSelector:@selector(popUpSuffixForlineGraph:)])
    suffix = [self.delegate popUpSuffixForlineGraph:self];

  if ([self.delegate respondsToSelector:@selector(popUpPrefixForlineGraph:)])
    prefix = [self.delegate popUpPrefixForlineGraph:self];

  int index = (int)(circleDot.tag - DotFirstTag100);
//  NSNumber *value = dataPoints[index]; // @((NSInteger) circleDot.absoluteValue)
  NSNumber *value = @0;
  NSString *formattedValue =
      [NSString stringWithFormat:self.options.formatStringForValues, value.doubleValue];
  permanentPopUpLabel.text =
      [NSString stringWithFormat:@"%@%@%@", prefix, formattedValue, suffix];

  permanentPopUpLabel.font = self.options.labelFont;
  permanentPopUpLabel.backgroundColor = [UIColor clearColor];
  [permanentPopUpLabel sizeToFit];
  permanentPopUpLabel.center =
      CGPointMake(self.xCenterLabel,
                  circleDot.center.y - circleDot.frame.size.height / 2 - 15);
  permanentPopUpLabel.alpha = 0;

  BEMPermanentPopupView *permanentPopUpView = [[BEMPermanentPopupView alloc]
      initWithFrame:CGRectMake(0, 0, permanentPopUpLabel.frame.size.width + 7,
                               permanentPopUpLabel.frame.size.height + 2)];
  permanentPopUpView.backgroundColor = self.options.colorBackgroundPopUplabel;
  permanentPopUpView.alpha = 0;
  permanentPopUpView.layer.cornerRadius = 3;
  permanentPopUpView.tag = PermanentPopUpViewTag3100;
  permanentPopUpView.center = permanentPopUpLabel.center;

  if (permanentPopUpLabel.frame.origin.x <= 0) {
    self.xCenterLabel = permanentPopUpLabel.frame.size.width / 2 + 4;
    permanentPopUpLabel.center =
        CGPointMake(self.xCenterLabel,
                    circleDot.center.y - circleDot.frame.size.height / 2 - 15);
  } else if (self.options.enableYAxisLabel == YES &&
             permanentPopUpLabel.frame.origin.x <= self.YAxisLabelXOffset) {
    self.xCenterLabel = permanentPopUpLabel.frame.size.width / 2 + 4;
    permanentPopUpLabel.center =
        CGPointMake(self.xCenterLabel + self.YAxisLabelXOffset,
                    circleDot.center.y - circleDot.frame.size.height / 2 - 15);
  } else if ((permanentPopUpLabel.frame.origin.x +
              permanentPopUpLabel.frame.size.width) >= self.frame.size.width) {
    self.xCenterLabel =
        self.frame.size.width - permanentPopUpLabel.frame.size.width / 2 - 4;
    permanentPopUpLabel.center =
        CGPointMake(self.xCenterLabel,
                    circleDot.center.y - circleDot.frame.size.height / 2 - 15);
  }

  if (permanentPopUpLabel.frame.origin.y <= 2) {
    permanentPopUpLabel.center =
        CGPointMake(self.xCenterLabel,
                    circleDot.center.y + circleDot.frame.size.height / 2 + 15);
  }

  if ([self checkOverlapsForView:permanentPopUpView] == YES) {
    permanentPopUpLabel.center =
        CGPointMake(self.xCenterLabel,
                    circleDot.center.y + circleDot.frame.size.height / 2 + 15);
  }

  permanentPopUpView.center = permanentPopUpLabel.center;

  [self addSubview:permanentPopUpView];
  [self addSubview:permanentPopUpLabel];

  if (self.options.animationGraphEntranceTime == 0) {
    permanentPopUpLabel.alpha = 1;
    permanentPopUpView.alpha = 0.7;
  } else {
    [UIView animateWithDuration:0.5
                          delay:self.options.animationGraphEntranceTime
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                       permanentPopUpLabel.alpha = 1;
                       permanentPopUpView.alpha = 0.7;
                     }
                     completion:nil];
  }
}

- (BOOL)checkOverlapsForView:(UIView *)view {
    for (UIView *viewForLabel in [self subviews]) {
        if ([viewForLabel isKindOfClass:[UIView class]] && viewForLabel.tag == PermanentPopUpViewTag3100 ) {
            if ((viewForLabel.frame.origin.x + viewForLabel.frame.size.width) >= view.frame.origin.x) {
                if (viewForLabel.frame.origin.y >= view.frame.origin.y && viewForLabel.frame.origin.y <= view.frame.origin.y + view.frame.size.height) return YES;
                else if (viewForLabel.frame.origin.y + viewForLabel.frame.size.height >= view.frame.origin.y && viewForLabel.frame.origin.y + viewForLabel.frame.size.height <= view.frame.origin.y + view.frame.size.height) return YES;
            }
        }
    }
    return NO;
}

- (CGFloat)yPositionForDotValue:(CGFloat)dotValue {
  if (dotValue == BEMNullGraphValue) {
    return BEMNullGraphValue;
  }

  CGFloat positionOnYAxis; // The position on the Y-axis of the point currently
                           // being created.
  CGFloat padding = self.frame.size.height / 2;
  if (padding > 90.0) {
    padding = 90.0;
  }

  if ([self.delegate respondsToSelector:@selector(staticPaddingForLineGraph:)])
    padding = [self.delegate staticPaddingForLineGraph:self];

  if (self.options.enableXAxisLabel) {
    if ([self.dataSource
            respondsToSelector:@selector(lineGraph:labelOnXAxisForIndex:)] ||
        [self.dataSource respondsToSelector:@selector(labelOnXAxisForIndex:)]) {
      if ([self.xAxisLabels count] > 0) {
        UILabel *label = [self.xAxisLabels objectAtIndex:0];
        self.XAxisLabelYOffset =
            label.frame.size.height + self.options.widthLine;
      }
    }
  }

  if (self.minValue == self.maxValue && self.options.autoScaleYAxis == YES)
    positionOnYAxis = self.frame.size.height / 2;
  else if (self.options.autoScaleYAxis == YES)
    positionOnYAxis =
        ((self.frame.size.height - padding / 2) -
         ((dotValue - self.minValue) / ((self.maxValue - self.minValue) /
                                        (self.frame.size.height - padding)))) +
        self.XAxisLabelYOffset / 2;
  else
    positionOnYAxis = ((self.frame.size.height) - dotValue);

  positionOnYAxis -= self.XAxisLabelYOffset;

  return positionOnYAxis;
}

#pragma mark - Texts

- (NSString *)xAxisTextForIndex:(NSInteger)index {
  NSString *xAxisLabelText = @"";

  if ([self.dataSource
          respondsToSelector:@selector(lineGraph:labelOnXAxisForIndex:)]) {
    xAxisLabelText =
        [self.dataSource lineGraph:self labelOnXAxisForIndex:index];

  } else if ([self.delegate
                 respondsToSelector:@selector(labelOnXAxisForIndex:)]) {
    [self
        printDeprecationWarningForOldMethod:@"labelOnXAxisForIndex:"
                       andReplacementMethod:@"lineGraph:labelOnXAxisForIndex:"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    xAxisLabelText = [self.delegate labelOnXAxisForIndex:index];
#pragma clang diagnostic pop

  } else if ([self.delegate respondsToSelector:@selector(lineGraph:
                                                   labelOnXAxisForIndex:)]) {
    [self printDeprecationAndUnavailableWarningForOldMethod:
              @"lineGraph:labelOnXAxisForIndex:"];
    NSException *exception = [NSException
        exceptionWithName:@"Implementing Unavailable Delegate Method"
                   reason:@"lineGraph:labelOnXAxisForIndex: is no longer "
                          @"available on the delegate. It must be implemented "
                          @"on the data source."
                 userInfo:nil];
    [exception raise];

  } else {
    xAxisLabelText = @"";
  }

  return xAxisLabelText;
}

- (UILabel *)xAxisLabelWithText:(NSString *)text atIndex:(NSInteger)index {
  UILabel *labelXAxis = [[UILabel alloc] init];
  labelXAxis.text = text;
  labelXAxis.font = self.options.labelFont;
  labelXAxis.textAlignment = 1;
  labelXAxis.textColor = self.options.colorXaxisLabel;
  labelXAxis.backgroundColor = [UIColor clearColor];
  labelXAxis.tag = DotLastTag1000;

  // Add support multi-line, but this might overlap with the graph line if text
  // have too many lines
  labelXAxis.numberOfLines = 0;
  CGRect lRect = [labelXAxis.text
      boundingRectWithSize:self.viewForBaselineLayout.frame.size
                   options:NSStringDrawingUsesLineFragmentOrigin
                attributes:@{
                  NSFontAttributeName : labelXAxis.font
                }
                   context:nil];

  CGPoint center;

  /* OLD LABEL GENERATION CODE
  CGFloat availablePositionRoom = self.viewForBaselineLayout.frame.size.width;
  // Get view width of view
  CGFloat positioningDivisor = (float)index / numberOfPoints; // Generate
  relative position of point based on current index and total
  CGFloat horizontalTranslation = self.YAxisLabelXOffset + lRect.size.width;
  CGFloat xPosition = (availablePositionRoom * positioningDivisor) +
  horizontalTranslation;
  // NSLog(@"availablePositionRoom: %f, positioningDivisor: %f,
  horizontalTranslation: %f, xPosition: %f", availablePositionRoom,
  positioningDivisor, horizontalTranslation, xPosition); // Uncomment for
  debugging */

  // Determine the horizontal translation to perform on the far left and far
  // right labels
  // This property is negated when calculating the position of reference frames
  CGFloat horizontalTranslation;
  if (index == 0) {
    horizontalTranslation = lRect.size.width / 2;
  } else if (index + 1 == self.maxNumberOfPoints) {
    horizontalTranslation = -lRect.size.width / 2;
  } else
    horizontalTranslation = 0;
  self.xAxisHorizontalFringeNegationValue = horizontalTranslation;

  CGFloat YAxisLabelXOffset =
      self.options.overlapYAxisWithGraph ? 0 : self.YAxisLabelXOffset;
  // Determine the final x-axis position
  CGFloat positionOnXAxis;
  if (self.options.positionYAxisRight) {
    positionOnXAxis = (((self.frame.size.width - YAxisLabelXOffset) /
                        (self.maxNumberOfPoints - 1)) *
                       index) +
                      horizontalTranslation;
  } else {
    positionOnXAxis = (((self.frame.size.width - YAxisLabelXOffset) /
                        (self.maxNumberOfPoints - 1)) *
                       index) +
                      YAxisLabelXOffset + horizontalTranslation;
  }

  // Set the final center point of the x-axis labels
  if (self.options.positionYAxisRight) {
    center = CGPointMake(positionOnXAxis,
                         self.frame.size.height - lRect.size.height / 2);
  } else {
    center = CGPointMake(positionOnXAxis,
                         self.frame.size.height - lRect.size.height / 2);
  }

  CGRect rect = labelXAxis.frame;
  rect.size = lRect.size;
  labelXAxis.frame = rect;
  labelXAxis.center = center;

  // SCI
  if ([self.delegate
          respondsToSelector:@selector(lineGraph:hideLabelAtIndex:)] &&
      [self.delegate lineGraph:self hideLabelAtIndex:index])
    labelXAxis.hidden = YES;

  return labelXAxis;
}

#pragma mark - Event Hnadl

- (void)didFinishDrawingIncludingYAxis:(BOOL)yAxisFinishedDrawing {
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW,
                    self.options.animationGraphEntranceTime * NSEC_PER_SEC),
      dispatch_get_main_queue(), ^{
        if (self.options.enableYAxisLabel == NO) {
          // Let the delegate know that the graph finished rendering
          if ([self.delegate
                  respondsToSelector:@selector(lineGraphDidFinishDrawing:)])
            [self.delegate lineGraphDidFinishDrawing:self];
          return;
        } else {
          if (yAxisFinishedDrawing == YES) {
            // Let the delegate know that the graph finished rendering
            if ([self.delegate
                    respondsToSelector:@selector(lineGraphDidFinishDrawing:)])
              [self.delegate lineGraphDidFinishDrawing:self];
            return;
          }
        }
      });
}

#pragma mark - Utils

- (NSString *)formattedYLabelTextWithValue:(CGFloat)value {
  if (self.options.enableThousandValueFormatter)
    return [self kFormatForNumber:@(value)];
  else
    return
        [NSString stringWithFormat:self.options.formatStringForValues, value];
}

- (NSUInteger)numberOfPoints {
  if (_numberOfPoints != NSUIntegerMax) {
    return _numberOfPoints;
  }

  NSUInteger numberOfPoints = 0;
  for (BEMGraphDataSet *dataSet in self.dataSets) {
    numberOfPoints += dataSet.values.count;
  }
  _numberOfPoints = numberOfPoints;

  return _numberOfPoints;
}

- (NSUInteger)maxNumberOfPoints {
  if (_maxNumberOfPoints != NSUIntegerMax)
    return _maxNumberOfPoints;

  NSUInteger maxNumberOfPoints = NSUIntegerMax;
  for (BEMGraphDataSet *dataSet in self.dataSets) {
    maxNumberOfPoints = MAX(dataSet.count, maxNumberOfPoints);
  }
  _maxNumberOfPoints = maxNumberOfPoints;

  return _maxNumberOfPoints;
}

- (CGFloat)minPoint {
  CGFloat min = CGFLOAT_MAX;
  for (BEMGraphDataSet *dataSet in self.dataSets) {
    min = MIN(min, dataSet.minValue);
  }
  return min;
}

- (CGFloat)maxPoint {
  CGFloat max = CGFLOAT_MIN;
  for (BEMGraphDataSet *dataSet in self.dataSets) {
    max = MAX(max, dataSet.maxValue);
  }
  return max;
}

- (NSInteger)offsetForXAxisWithNumberOfGaps:(NSInteger)numberOfGaps {
  NSInteger leftGap = numberOfGaps - 1;
  NSInteger rightGap = self.maxNumberOfPoints -
                       (numberOfGaps * (self.maxNumberOfPoints / numberOfGaps));
  NSInteger offset = 0;

  if (leftGap != rightGap) {
    for (int i = 0; i <= numberOfGaps; i++) {
      if (leftGap - i == rightGap + i) {
        offset = i;
      }
    }
  }

  return offset;
}

#pragma mark - Other Methods

- (NSString *)kFormatForNumber:(NSNumber *)number {
  if (number.doubleValue < 1000)
    return [NSString stringWithFormat:self.options.formatStringForValues,
                                      number.doubleValue];

  CGFloat result = number.doubleValue / 1000;

  NSString *kFormatStringValues =
      [NSString stringWithFormat:@"%@k", self.options.formatStringForValues];
  NSString *kValue = [NSString stringWithFormat:kFormatStringValues, result];
  return kValue;
}

- (void)printDeprecationAndUnavailableWarningForOldMethod:
    (NSString *)oldMethod {
  NSLog(@"[BEMSimpleLineGraph] UNAVAILABLE, DEPRECATION ERROR. The delegate "
        @"method, %@, is both deprecated and unavailable. It is now a data "
        @"source method. You must implement this method from "
        @"BEMSimpleLineGraphDataSource. Update your delegate method as soon "
        @"as possible. One of two things will now happen: A) an exception "
        @"will be thrown, or B) the graph will not load.",
        oldMethod);
}

- (void)printDeprecationWarningForOldMethod:(NSString *)oldMethod
                       andReplacementMethod:(NSString *)replacementMethod {
  NSLog(@"[BEMSimpleLineGraph] DEPRECATION WARNING. The delegate method, %@, "
        @"is deprecated and will become unavailable in a future version. Use "
        @"%@ instead. Update your delegate method as soon as possible. An "
        @"exception will be thrown in a future version.",
        oldMethod, replacementMethod);
}

@end
