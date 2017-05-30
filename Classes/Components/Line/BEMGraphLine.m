//
//  BEMGraphself.m
//  SimpleselfChart
//
//  Created by twidle on 5/28/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "BEMGraphLine.h"

#import "BEMGraphDataSet.h"
#import "BEMGraphOptions.h"

#import "BEMAverageLine.h"

@implementation BEMGraphLine

- (instancetype)init {
  if (self = [super init]) {
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
  self.opaque = NO;
  self.alpha = 1;
  self.backgroundColor = [UIColor clearColor];
}

- (void)setDataSet:(BEMGraphDataSet *)dataSet {
  _dataSet = dataSet;

  self.arrayOfPoints = dataSet.yAxisValues;
  self.arrayOfValues = dataSet.values;

  BEMAverageLine *averageLine = [[BEMAverageLine alloc] init];

  if (self.averageLine.enableAverageLine == YES) {
    if (self.averageLine.yValue == 0.0)
      self.averageLine.yValue =
          [self.dataSet calculatePointValueAverage].floatValue;
    self.averageLine = averageLine;
  } else
    self.averageLine = averageLine;
}

- (void)setOptions:(BEMGraphOptions *)options {
  _options = options;

  self.topColor = [UIColor clearColor];
  self.bottomColor = self.options.colorBottom;
  self.topAlpha = self.options.alphaTop;
  self.bottomAlpha = self.options.alphaBottom;
  self.topGradient = self.options.gradientTop;
  self.bottomGradient = self.options.gradientBottom;
  self.lineWidth = self.options.widthLine;
  self.referenceLineWidth = self.options.widthReferenceLines
                                ? self.options.widthReferenceLines
                                : (self.options.widthLine / 2);
  self.lineAlpha = self.options.alphaLine;
  self.bezierCurveIsEnabled = self.options.enableBezierCurve;

  self.lineDashPatternForReferenceYAxisLines =
      self.options.lineDashPatternForReferenceYAxisLines;
  self.lineDashPatternForReferenceXAxisLines =
      self.options.lineDashPatternForReferenceXAxisLines;
  self.interpolateNullValues = self.interpolateNullValues;

  self.enableRefrenceFrame = self.options.enableReferenceAxisFrame;
  self.enableRightReferenceFrameLine =
      self.options.enableRightReferenceAxisFrameLine;
  self.enableTopReferenceFrameLine =
      self.options.enableTopReferenceAxisFrameLine;
  self.enableLeftReferenceFrameLine =
      self.options.enableLeftReferenceAxisFrameLine;
  self.enableBottomReferenceFrameLine =
      self.options.enableBottomReferenceAxisFrameLine;

  if (self.options.enableReferenceXAxisLines ||
      self.options.enableReferenceYAxisLines) {
    self.enableRefrenceLines = YES;
    self.refrenceLineColor = self.options.colorReferenceLines;
    self.verticalReferenceHorizontalFringeNegation =
        self.xAxisHorizontalFringeNegationValue;

    self.arrayOfVerticalRefrenceLinePoints =
        self.options.enableReferenceXAxisLines ? self.xAxisLabelPoints : nil;
    self.arrayOfHorizontalRefrenceLinePoints =
        self.options.enableReferenceYAxisLines ? self.yAxisLabelPoints : nil;
  }

  self.color = self.options.colorLine;
  self.lineGradient = self.options.gradientLine;
  self.lineGradientDirection = self.options.gradientLineDirection;
  self.animationTime = self.options.animationGraphEntranceTime;
  self.animationType = self.options.animationGraphStyle;

  self.disableMainLine = self.options.displayDotsOnly;
}

@end
