//
//  BEMGraphLine.h
//  SimpleLineChart
//
//  Created by twidle on 5/28/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "BEMLine.h"

@class BEMGraphOptions;
@class BEMGraphDataSet;

@interface BEMGraphLine : BEMLine

@property(nonatomic) CGFloat xAxisHorizontalFringeNegationValue;

@property(strong, nonatomic) BEMGraphOptions *options;

@property(strong, nonatomic) BEMGraphDataSet *dataSet;

@property(strong, nonatomic) NSArray *xAxisLabelPoints;
@property(strong, nonatomic) NSArray *yAxisLabelPoints;

@end
