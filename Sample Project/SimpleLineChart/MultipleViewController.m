//
//  MultipleViewController.m
//  SimpleLineChart
//
//  Created by twidle on 5/29/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "MultipleViewController.h"

#import "BEMGraphDataSet.h"

#import "BEMGraphOptions.h"
#import "BEMMultiLineGraphView.h"

static const NSUInteger kTotalPoints = 5;

@interface MultipleViewController () <BEMMultiLineGraphViewDataSource>

@property(weak, nonatomic) IBOutlet BEMMultiLineGraphView *graphView;

@property(strong, nonatomic) BEMGraphOptions *options;

@end

@implementation MultipleViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Do any additional setup after loading the view.
  [self setupGraph];
}

- (void)setupGraph {
  BEMGraphOptions *options = [[BEMGraphOptions alloc] init];
  options.autoScaleYAxis = YES;

  options.colorPoint = [UIColor darkGrayColor];

  options.colorTop = [UIColor clearColor];

  options.colorBottom = [UIColor blueColor];
  options.alphaBottom = 0.5;
  options.colorReferenceLines = [UIColor lightGrayColor];

  options.enableYAxisLabel = YES;
  options.autoScaleYAxis = YES;
  options.alwaysDisplayDots = YES;
//  options.enableReferenceXAxisLines = YES;
  options.enableReferenceYAxisLines = YES;
  options.enableReferenceAxisFrame = YES;
  options.alwaysDisplayPopUpLabels = NO;

  options.colorBackgroundXaxis = [UIColor whiteColor];
  // Draw an average line
  options.averageLine.enableAverageLine = YES;
  options.averageLine.alpha = 0.6;
  options.averageLine.color = [UIColor darkGrayColor];
  options.averageLine.width = 2.5;
  options.averageLine.dashPattern = @[ @(2), @(2) ];
  // Set the graph's animation style to draw, fade, or none
  options.animationGraphStyle = BEMLineAnimationDraw;
  // Dash the y reference lines
  options.lineDashPatternForReferenceXAxisLines = @[ @(2), @(2) ];
  // Show the y axis values with this format string
  options.formatStringForValues = @"%.1f";
  options.overlapYAxisWithGraph = YES;
  options.alignmentYAxisLabel = NSTextAlignmentLeft;
  options.enableThousandValueFormatter = YES;
  options.allowOverlappingLabels = YES;
  options.marginLeftYAxisLabel = 8.f;

  options.enableThousandValueFormatter = YES;

  options.allowOverlappingLabels = YES;

  options.marginLeftYAxisLabel = 8.f;

  self.graphView.multiLineDataSource = self;

  self.graphView.options = options;
  self.options = options;

  BEMGraphDataSet *dataSet =
      [[BEMGraphDataSet alloc] initWithValues:[self getValues]];

  BEMGraphDataSet *other =
      [[BEMGraphDataSet alloc] initWithValues:[self getValues]];

  self.graphView.dataSets = @[ dataSet, other ];

  [self.graphView reloadGraph];
}

- (NSArray *)getValues {

  NSMutableArray *values = [NSMutableArray array];

  for (NSUInteger i = 0; i < kTotalPoints; i++) {
    CGFloat value = [self getRandomFloat];
    [values addObject:@(value)];
  }
  return values;
}

- (float)getRandomFloat {
  float i1 = (float)(arc4random() % 1000000) / 100;
  return i1;
}

- (IBAction)didTapRefresh:(id)sender {
  [self.graphView reloadGraph];
}

#pragma mark - MultiGraph DataSource

- (BEMGraphOptions *)multiLineGraph:(BEMMultiLineGraphView *)lineGraph
       viewOptionsOfLineWithDataSet:(BEMGraphDataSet *)dataSet
                        inLineIndex:(NSUInteger)lineIndex {

  BEMGraphOptions *options = [[BEMGraphOptions alloc] init];
  options.autoScaleYAxis = YES;

  options.colorPoint = [UIColor darkGrayColor];

  options.colorTop = [UIColor clearColor];

  options.colorBottom = [UIColor darkGrayColor];
  options.alphaBottom = 0.5;
  options.colorReferenceLines = [UIColor lightGrayColor];

  options.enableYAxisLabel = YES;
  options.autoScaleYAxis = YES;
  options.alwaysDisplayDots = YES;
//  options.enableReferenceXAxisLines = YES;
  options.enableReferenceYAxisLines = YES;
  options.enableReferenceAxisFrame = YES;
  options.alwaysDisplayPopUpLabels = NO;

  options.colorBackgroundXaxis = [UIColor whiteColor];
  // Draw an average line
  options.averageLine.enableAverageLine = YES;
  options.averageLine.alpha = 0.6;
  options.averageLine.color = [UIColor darkGrayColor];
  options.averageLine.width = 2.5;
  options.averageLine.dashPattern = @[ @(2), @(2) ];
  // Set the graph's animation style to draw, fade, or none
  options.animationGraphStyle = BEMLineAnimationDraw;
  // Dash the y reference lines
  options.lineDashPatternForReferenceXAxisLines = @[ @(2), @(2) ];
  // Show the y axis values with this format string
  options.formatStringForValues = @"%.1f";
  options.overlapYAxisWithGraph = YES;
  options.alignmentYAxisLabel = NSTextAlignmentLeft;
  options.enableThousandValueFormatter = YES;
  options.allowOverlappingLabels = YES;
  options.marginLeftYAxisLabel = 8.f;

  options.enableThousandValueFormatter = YES;

  options.allowOverlappingLabels = YES;

  options.marginLeftYAxisLabel = 8.f;

  return (lineIndex == 0) ? self.options : options;
}

@end
