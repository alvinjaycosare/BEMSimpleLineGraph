//
//  BEMGraphCircle.h
//  SimpleLineChart
//
//  Created by twidle on 5/28/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "BEMCircle.h"

@class BEMGraphOptions;

@interface BEMGraphCircle : BEMCircle

@property(strong, nonatomic) NSString *labelPrefix;

@property(strong, nonatomic) NSString *labelSuffix;

@property (strong, nonatomic) CGFloat yAxisLabelOffset;

@property(strong, nonatomic) BEMGraphOptions *options;

@property(nonatomic) BOOL shouldShowCircleLabel;

- (instancetype)initWithValue:(NSNumber *)value;

@end
