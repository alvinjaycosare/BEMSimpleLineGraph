//
//  BEMGraphDataSet.h
//  SimpleLineChart
//
//  Created by twidle on 5/25/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BEMGraphDataSet : NSObject

@property(readonly, nonatomic) BOOL isEmpty;

@property(readonly, nonatomic) CGFloat maxValue;

@property(readonly, nonatomic) CGFloat minValue;

@property(readonly, nonatomic) NSUInteger count;

@property(readonly, strong, nonatomic) NSArray<NSNumber *> *values;

@property(readonly, strong, nonatomic) NSMutableArray<NSNumber *> *yAxisValues;

- (instancetype)initWithValues:(NSArray<NSNumber *> *)values;

- (void)resetPositionValues;

/** Calculates the average (mean) of all points on the line graph.
 @return The average (mean) number of the points on the graph. Originally a
 float. */
- (NSNumber *)calculatePointValueAverage;

/** Calculates the sum of all points on the line graph.
 @return The sum of the points on the graph. Originally a float. */
- (NSNumber *)calculatePointValueSum;

/** Calculates the median of all points on the line graph.
 @return The median number of the points on the graph. Originally a float. */
- (NSNumber *)calculatePointValueMedian;

/** Calculates the mode of all points on the line graph.
 @return The mode number of the points on the graph. Originally a float. */
- (NSNumber *)calculatePointValueMode;

/** Calculates the standard deviation of all points on the line graph.
 @return The standard deviation of the points on the graph. Originally a float.
 */
- (NSNumber *)calculateLineGraphStandardDeviation;

/** Calculates the minimum value of all points on the line graph.
 @return The minimum number of the points on the graph. Originally a float. */
- (NSNumber *)calculateMinimumPointValue;

/** Calculates the maximum value of all points on the line graph.
 @return The maximum value of the points on the graph. Originally a float. */
- (NSNumber *)calculateMaximumPointValue;

@end
