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

#import "BEMGraphCircle.h"
#import "BEMGraphLine.h"

typedef NS_ENUM(NSInteger, BEMInternalTags) {
  DotFirstTag100 = 100,
  DotLastTag1000 = 1000,
  LabelYAxisTag2000 = 2000,
  BackgroundYAxisTag2100 = 2100,
  BackgroundXAxisTag2200 = 2200,
  PermanentPopUpViewTag3100 = 3100,
};

@interface BEMMultiLineGraphView ()

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

@property(nonatomic) NSMutableArray *yAxisLabels;

@property(nonatomic) NSMutableArray *xAxisLabelPoints;
@property(nonatomic) NSMutableArray *yAxisLabelPoints;

@property(nonatomic) CGRect drawableGraphArea;
@property(nonatomic) CGRect drawableXAxisArea;

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

  self.numberOfPoints = 0;
  self.maxNumberOfPoints = 0;

  self.yAxisLabelPoints = [NSMutableArray array];
  self.xAxisLabelPoints = [NSMutableArray array];
}

- (void)layoutSubviews {

  [self setupConstant];

  [super layoutSubviews];
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

  self.drawableXAxisArea =
      CGRectMake(xOrigin, self.bounds.size.height - xAxisHeight,
                 CGRectGetWidth(rect) + 1, xAxisHeight);

  self.options.enableTouchReport = NO;
  self.options.enablePopUpReport = NO;
}

- (void)reloadGraph {
  if (!self.dataSets || self.dataSets.count == 0)
    return;

  [self drawGraph];
}

- (void)setDataSets:(NSArray<BEMGraphDataSet *> *)dataSets {
  _dataSets = dataSets;

  NSUInteger maxNumberOfPoints = 0;
  NSUInteger numberOfPoints = 0;

  CGFloat min = CGFLOAT_MAX;
  CGFloat max = CGFLOAT_MIN;

  for (BEMGraphDataSet *dataSet in self.dataSets) {
    maxNumberOfPoints = MAX(dataSet.count, maxNumberOfPoints);
    numberOfPoints += dataSet.values.count;
    min = MIN(min, dataSet.minValue);
    max = MAX(max, dataSet.maxValue);
  }
  self.numberOfPoints = numberOfPoints;
  self.maxNumberOfPoints = maxNumberOfPoints;

  self.maxValue = max;
  self.minValue = min;

  self.maxValue =
      [self.delegate respondsToSelector:@selector(maxValueForLineGraph:)]
          ? [self.delegate maxValueForLineGraph:self]
          : max;
  self.minValue =
      [self.delegate respondsToSelector:@selector(minValueForLineGraph:)]
          ? [self.delegate minValueForLineGraph:self]
          : min;
}

#pragma mark - Draw

- (void)drawGraph {
  [self removeGraphViewsIfNeeded];

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
    [subview removeFromSuperview];
  }
}

#pragma mark - Layout

- (void)layoutNumberOfPoints {
  if (self.numberOfPoints == 0) {
    if (self.delegate &&
        [self.delegate
            respondsToSelector:@selector(noDataLabelEnableForLineGraph:)] &&
        ![self.delegate noDataLabelEnableForLineGraph:self])
      return;

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
  [self calculateYAxisLabelXOffset];

  // Draw the X-Axis
  [self drawYAxis];
  // Draw the X-Axis
  [self drawXAxis];

  // Draw the graph
  [self drawDots];
}

- (void)drawXAxis {
  if (![self.dataSource
          respondsToSelector:@selector(lineGraph:labelOnXAxisForIndex:)] ||
      !self.options.enableXAxisLabel)
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
  backgroundXAxis.backgroundColor = (self.options.colorBackgroundXaxis == nil)
                                        ? self.options.colorBottom
                                        : self.options.colorBackgroundXaxis;
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

      UILabel *labelXAxis = [self xAxisLabelatIndex:index];
      [xAxisLabels addObject:labelXAxis];

      CGFloat YAxisLabelXOffset =
          self.options.overlapYAxisWithGraph ? 0 : self.YAxisLabelXOffset;
      NSNumber *xAxisLabelCoordinate =
          (self.options.positionYAxisRight)
              ? @(labelXAxis.center.x)
              : @(labelXAxis.center.x - YAxisLabelXOffset);
      [xAxisLabelPoints addObject:xAxisLabelCoordinate];

      [self addSubview:labelXAxis];
    }

  } else if ([self.delegate
                 respondsToSelector:@selector(baseIndexForXAxisOnLineGraph:)] &&
             [self.delegate
                 respondsToSelector:@selector(
                                        incrementIndexForXAxisOnLineGraph:)]) {
    NSInteger baseIndex = [self.delegate baseIndexForXAxisOnLineGraph:self];
    NSInteger increment =
        [self.delegate incrementIndexForXAxisOnLineGraph:self];

    for (NSInteger startingIndex = baseIndex;
         startingIndex < self.maxNumberOfPoints; startingIndex += increment) {

      UILabel *labelXAxis = [self xAxisLabelatIndex:startingIndex];
      [xAxisLabels addObject:labelXAxis];

      NSNumber *xAxisLabelCoordinate =
          (self.options.positionYAxisRight)
              ? @(labelXAxis.center.x)
              : @(labelXAxis.center.x - self.YAxisLabelXOffset);
      [xAxisLabelPoints addObject:xAxisLabelCoordinate];

      [self addSubview:labelXAxis];
    }
  } else {
    NSInteger numberOfGaps =
        ([self.delegate
            respondsToSelector:@selector(
                                   numberOfGapsBetweenLabelsOnLineGraph:)])
            ? [self.delegate numberOfGapsBetweenLabelsOnLineGraph:self] + 1
            : 1;

    if (numberOfGaps >= (self.maxNumberOfPoints - 1)) {
      NSString *firstXLabel = [self xAxisTextForIndex:0];
      NSString *lastXLabel =
          [self xAxisTextForIndex:self.maxNumberOfPoints - 1];

      CGFloat viewWidth = self.frame.size.width - self.YAxisLabelXOffset;

      CGFloat xAxisXPositionFirstOffset =
          (self.options.positionYAxisRight) ? 3 : 3 + self.YAxisLabelXOffset;

      CGFloat xAxisXPositionLastOffset =
          (self.options.positionYAxisRight)
              ? xAxisXPositionFirstOffset + 1 + viewWidth / 2
              : viewWidth / 2 + xAxisXPositionFirstOffset + 1;

      UILabel *firstLabel = [self xAxisLabelatIndex:0];
      firstLabel.frame =
          CGRectMake(xAxisXPositionFirstOffset, self.frame.size.height - 20,
                     viewWidth / 2, 20);

      firstLabel.textAlignment = NSTextAlignmentLeft;
      [self addSubview:firstLabel];
      [xAxisValues addObject:firstXLabel];
      [xAxisLabels addObject:firstLabel];

      UILabel *lastLabel = [self xAxisLabelatIndex:self.maxNumberOfPoints - 1];
      lastLabel.frame =
          CGRectMake(xAxisXPositionLastOffset, self.frame.size.height - 20,
                     viewWidth / 2 - 4, 20);
      lastLabel.textAlignment = NSTextAlignmentRight;
      [self addSubview:lastLabel];
      [xAxisValues addObject:lastXLabel];
      [xAxisLabels addObject:lastLabel];

      NSNumber *xFirstAxisLabelCoordinate =
          (self.options.positionYAxisRight)
              ? @(firstLabel.center.x)
              : @(firstLabel.center.x - self.YAxisLabelXOffset);

      NSNumber *xLastAxisLabelCoordinate =
          (self.options.positionYAxisRight)
              ? @(lastLabel.center.x)
              : @(lastLabel.center.x - self.YAxisLabelXOffset);
      [xAxisLabelPoints addObject:xFirstAxisLabelCoordinate];
      [xAxisLabelPoints addObject:xLastAxisLabelCoordinate];

    } else {
      NSInteger offset =
          [self offsetForXAxisWithNumberOfGaps:numberOfGaps]; // The offset (if
                                                              // possible and
      // necessary) used to
      // shift the Labels on
      // the X-Axis for them
      // to be centered.

      for (int i = 1; i <= (self.maxNumberOfPoints / numberOfGaps); i++) {
        NSInteger index = i * numberOfGaps - 1 - offset;

        UILabel *labelXAxis = [self xAxisLabelatIndex:index];
        [xAxisLabels addObject:labelXAxis];

        NSNumber *xAxisLabelCoordinate =
            (self.options.positionYAxisRight)
                ? @(labelXAxis.center.x)
                : @(labelXAxis.center.x - self.YAxisLabelXOffset);
        [xAxisLabelPoints addObject:xAxisLabelCoordinate];

        [self addSubview:labelXAxis];
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

  [self.xAxisLabels addObjectsFromArray:xAxisLabels];
  self.xAxisLabelPoints = xAxisLabelPoints;
}

- (void)drawYAxis {
  //  CGRect frameForBackgroundYAxis =
  //      (self.options.positionYAxisRight)
  //          ? CGRectMake(self.frame.size.width - self.YAxisLabelXOffset, 0,
  //                       self.YAxisLabelXOffset, self.frame.size.height)
  //          : CGRectMake(0, 0, self.YAxisLabelXOffset,
  //          self.frame.size.height);

  CGRect frameForLabelYAxis =
      (self.options.positionYAxisRight)
          ? CGRectMake(self.frame.size.width - self.YAxisLabelXOffset - 5, 0,
                       self.YAxisLabelXOffset - 5, 15)
          : CGRectMake(0, 0, self.YAxisLabelXOffset - 5, 15);

  CGFloat xValueForCenterLabelYAxis =
      (self.options.positionYAxisRight)
          ? self.frame.size.width - self.YAxisLabelXOffset / 2
          : (self.YAxisLabelXOffset / 2) + self.options.marginLeftYAxisLabel;

  NSMutableArray *yAxisLabels = [NSMutableArray arrayWithCapacity:0];
  [self.yAxisLabelPoints removeAllObjects];

  NSString *yAxisSuffix =
      ([self.delegate respondsToSelector:@selector(yAxisSuffixOnLineGraph:)])
          ? [self.delegate yAxisSuffixOnLineGraph:self]
          : @"";
  NSString *yAxisPrefix =
      ([self.delegate respondsToSelector:@selector(yAxisPrefixOnLineGraph:)])
          ? [self.delegate yAxisPrefixOnLineGraph:self]
          : @"";

  CGFloat numberOfLabels =
      ([self.delegate
          respondsToSelector:@selector(numberOfYAxisLabelsOnLineGraph:)])
          ? [self.delegate numberOfYAxisLabelsOnLineGraph:self]
          : 3;

  NSNumber *minimumValue = @(self.minValue);
  NSNumber *maximumValue = @(self.maxValue);

  if (self.options.autoScaleYAxis) {
    // Plot according to min-max range

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
    } else if (numberOfLabels <= 0) {
      return;
    } else if (numberOfLabels == 1) {
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
      [self addSubview:labelYAxis];

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
          // Let the delegate know that the graph finished rendering
          if ([self.delegate
                  respondsToSelector:@selector(lineGraphDidFinishDrawing:)])
            [self.delegate lineGraphDidFinishDrawing:self];
        }
      });

  [self didFinishDrawingIncludingYAxis:YES];
}

- (void)drawDots {
  for (BEMGraphDataSet *dataSet in self.dataSets)
    [dataSet resetPositionValues];

  CGFloat YAxisLabelXOffset =
      self.options.overlapYAxisWithGraph ? 0 : self.YAxisLabelXOffset;

  void (^addCircleDotView)(CGFloat, CGFloat, CGFloat, NSUInteger,
                           NSUInteger) = ^(CGFloat xAxisPos, CGFloat yAxisPos,
                                           CGFloat value, NSUInteger xAxisIndex,
                                           NSUInteger dataSetIndex) {

    NSUInteger i = xAxisIndex;

    BEMGraphOptions *options =
        [self.multiLineDataSource multiLineGraph:self
                    viewOptionsOfLineWithDataSet:self.dataSets[dataSetIndex]
                                     inLineIndex:dataSetIndex];

    BEMGraphCircle *circleDot = [[BEMGraphCircle alloc] initWithValue:@(value)];
    circleDot.frame =
        CGRectMake(0, 0, self.options.sizePoint, self.options.sizePoint);
    circleDot.center = CGPointMake(xAxisPos, yAxisPos);
    circleDot.alpha = 0;
    circleDot.options = options;
    circleDot.absoluteValue = value;
    circleDot.yAxisLabelOffset = YAxisLabelXOffset;

    BOOL shouldDisplayLabel = self.options.alwaysDisplayPopUpLabels;
    shouldDisplayLabel &=
        ([self.delegate
            respondsToSelector:@selector(lineGraph:alwaysDisplayPopUpAtIndex:)])
            ? [self.delegate lineGraph:self alwaysDisplayPopUpAtIndex:i]
            : shouldDisplayLabel;

    circleDot.shouldShowCircleLabel = shouldDisplayLabel;

    circleDot.labelSuffix =
        ([self.delegate respondsToSelector:@selector(popUpSuffixForlineGraph:)])
            ? [self.delegate popUpSuffixForlineGraph:self]
            : @"";

    circleDot.labelPrefix =
        ([self.delegate respondsToSelector:@selector(popUpPrefixForlineGraph:)])
            ? [self.delegate popUpPrefixForlineGraph:self]
            : @"";

    [self addSubview:circleDot];

    BOOL shouldHideDot = self.options.alwaysDisplayDots;
    shouldHideDot = ([self.delegate respondsToSelector:@selector(lineGraph:
                                                            hideDotAtIndex:)])
                        ? [self.delegate lineGraph:self hideDotAtIndex:i]
                        : shouldHideDot;

    // Dot entrance animation
    if (self.options.animationGraphEntranceTime == 0) {
      circleDot.alpha =
          (self.options.displayDotsOnly) ? 1.0f : (shouldHideDot) ? 0 : 1.0f;
    } else {
      if (self.options.displayDotsWhileAnimating && !shouldHideDot) {
        [UIView animateWithDuration:self.options.animationGraphEntranceTime /
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
                [UIView animateWithDuration:0.3
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
  };

  for (int i = 0; i < self.maxNumberOfPoints; i++) {

    // The position on the X-axis of the point currently
    // being created.
    CGFloat positionOnXAxis =
        (self.options.positionYAxisRight)
            ? (((self.frame.size.width - YAxisLabelXOffset) /
                (self.maxNumberOfPoints - 1)) *
               i)

            : (((self.frame.size.width - YAxisLabelXOffset) /
                (self.maxNumberOfPoints - 1)) *
               i) +
                  YAxisLabelXOffset;

    for (NSUInteger j = 0; j < self.dataSets.count; j++) {
      BEMGraphDataSet *dataSet = self.dataSets[j];

      CGFloat dotValue = dataSet.values[i].floatValue;

      // If we're dealing with an null value, don't draw the dot
      if (dotValue == BEMNullGraphValue)
        return;

      CGFloat positionOnYAxis = [self yPositionForDotValue:dotValue];
      [dataSet.yAxisValues addObject:@(positionOnYAxis)];

      addCircleDotView(positionOnXAxis, positionOnYAxis, dotValue, i, j);
    }
  }

  //  // CREATION OF THE LINE AND BOTTOM AND TOP FILL
  [self drawLine];
}

- (void)drawLine {

  for (NSUInteger i = 0; i < self.dataSets.count; i++) {
    BEMGraphDataSet *dataSet = self.dataSets[i];

    BEMGraphLine *line =
        [[BEMGraphLine alloc] initWithFrame:self.drawableGraphArea];
    line.dataSet = dataSet;
    line.yAxisLabelPoints = self.yAxisLabelPoints;
    line.xAxisLabelPoints = self.xAxisLabelPoints;

    line.options = ([self.multiLineDataSource
                       respondsToSelector:@selector(multiLineGraph:
                                              viewOptionsOfLineWithDataSet:
                                                               inLineIndex:)])
                       ? [self.multiLineDataSource multiLineGraph:self
                                     viewOptionsOfLineWithDataSet:dataSet
                                                      inLineIndex:i]
                       : self.options;

    line.averageLineYCoordinate =
        (line.averageLine.enableAverageLine)
            ? [self yPositionForDotValue:line.averageLine.yValue]
            : 0;

    [self insertSubview:line atIndex:i];
  }

  [self didFinishDrawingIncludingYAxis:NO];
}

#pragma mark - Calculations

- (BEMCircle *)closestDotFromtouchInputLine:(UIView *)touchInputLine {
  CGFloat currentlyCloser = CGFLOAT_MAX;
  BEMCircle *closestDot = nil;
  for (BEMCircle *point in self.subviews) {
    if ([point isMemberOfClass:[BEMCircle class]]) {
      if (self.alwaysDisplayDots == NO && self.displayDotsOnly == NO) {
        point.alpha = 0;
      }
      if (pow(((point.center.x) - touchInputLine.center.x), 2) <
          currentlyCloser) {
        currentlyCloser = pow(((point.center.x) - touchInputLine.center.x), 2);
        closestDot = point;
      }
    }
  }
  return closestDot;
}

- (void)calculateYAxisLabelXOffset {

  // Set the Y-Axis Offset if the Y-Axis is enabled. The offset is relative to
  // the size of the longest label on the Y-Axis.

  if (self.options.enableYAxisLabel) {

    NSDictionary *attributes = @{NSFontAttributeName : self.options.labelFont};
    if (self.options.autoScaleYAxis == YES) {

      NSString *maxValueString = [NSString
          stringWithFormat:self.options.formatStringForValues, self.maxValue];
      NSString *minValueString = [NSString
          stringWithFormat:self.options.formatStringForValues, self.minValue];

      NSString *longestString = (maxValueString.length > minValueString.length)
                                    ? maxValueString
                                    : minValueString;

      NSString *prefix =
          ([self.delegate
              respondsToSelector:@selector(yAxisPrefixOnLineGraph:)])
              ? [self.delegate yAxisPrefixOnLineGraph:self]
              : @"";
      NSString *suffix =
          ([self.delegate
              respondsToSelector:@selector(yAxisSuffixOnLineGraph:)])
              ? [self.delegate yAxisSuffixOnLineGraph:self]
              : @"";

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

  } else {
    self.YAxisLabelXOffset = 0;
  }
}

#pragma mark - Misc

- (BOOL)checkOverlapsForView:(UIView *)view {
  for (UIView *viewForLabel in [self subviews]) {
    if ([viewForLabel isKindOfClass:[UIView class]] &&
        viewForLabel.tag == PermanentPopUpViewTag3100) {
      if ((viewForLabel.frame.origin.x + viewForLabel.frame.size.width) >=
          view.frame.origin.x) {
        if (viewForLabel.frame.origin.y >= view.frame.origin.y &&
            viewForLabel.frame.origin.y <=
                view.frame.origin.y + view.frame.size.height)
          return YES;
        else if (viewForLabel.frame.origin.y + viewForLabel.frame.size.height >=
                     view.frame.origin.y &&
                 viewForLabel.frame.origin.y + viewForLabel.frame.size.height <=
                     view.frame.origin.y + view.frame.size.height)
          return YES;
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

- (UILabel *)xAxisLabelatIndex:(NSInteger)index {
  UILabel *labelXAxis = [[UILabel alloc] init];
  labelXAxis.text = [self xAxisTextForIndex:index];
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
  labelXAxis.hidden =
      ([self.delegate
           respondsToSelector:@selector(lineGraph:hideLabelAtIndex:)] &&
       [self.delegate lineGraph:self hideLabelAtIndex:index]);

  return labelXAxis;
}

#pragma mark - Event Handler

- (void)didFinishDrawingIncludingYAxis:(BOOL)yAxisFinishedDrawing {
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW,
                    self.animationGraphEntranceTime * NSEC_PER_SEC),
      dispatch_get_main_queue(), ^{
        if (self.enableYAxisLabel == NO) {
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
