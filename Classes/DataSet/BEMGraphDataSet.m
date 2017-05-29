//
//  BEMGraphDataSet.m
//  SimpleLineChart
//
//  Created by twidle on 5/25/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "BEMGraphDataSet.h"

@interface BEMGraphDataSet ()

@property(readwrite, strong, nonatomic) NSArray<NSNumber *> *values;

@end

@implementation BEMGraphDataSet

- (instancetype)initWithValues:(NSArray<NSNumber *> *)values {
  if (self = [super init]) {
    _values = values;

    _yAxisValues = [NSMutableArray array];
  }
  return self;
}

- (NSUInteger)count {
  return self.values.count;
}

- (BOOL)isEmpty {
  return self.values.count == 0;
}

- (CGFloat)maxValue {
  CGFloat max = CGFLOAT_MIN;
  for (NSNumber *value in self.values) {
    max = MAX(value.floatValue, max);
  }
  return max;
}

- (CGFloat)minValue {
  CGFloat min = CGFLOAT_MAX;
  for (NSNumber *value in self.values) {
    min = MIN(value.floatValue, min);
  }

  return min;
}

- (void)resetPositionValues {
  [self.yAxisValues removeAllObjects];
}

- (NSArray *)calculationDataPoints {
  NSPredicate *filter = [NSPredicate
      predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSNumber *value = (NSNumber *)evaluatedObject;
        BOOL retVal = ![value isEqualToNumber:@(CGFLOAT_MAX)];
        return retVal;
      }];
  NSArray *filteredArray = [self.values filteredArrayUsingPredicate:filter];
  return filteredArray;
}

- (NSNumber *)calculatePointValueAverage {
  NSArray *filteredArray = [self calculationDataPoints];
  if (filteredArray.count == 0)
    return [NSNumber numberWithInt:0];

  NSExpression *expression = [NSExpression
      expressionForFunction:@"average:"
                  arguments:@[ [NSExpression
                                expressionForConstantValue:filteredArray] ]];
  NSNumber *value = [expression expressionValueWithObject:nil context:nil];

  return value;
}

- (NSNumber *)calculatePointValueSum {
  NSArray *filteredArray = [self calculationDataPoints];
  if (filteredArray.count == 0)
    return [NSNumber numberWithInt:0];

  NSExpression *expression = [NSExpression
      expressionForFunction:@"sum:"
                  arguments:@[ [NSExpression
                                expressionForConstantValue:filteredArray] ]];
  NSNumber *value = [expression expressionValueWithObject:nil context:nil];

  return value;
}

- (NSNumber *)calculatePointValueMedian {
  NSArray *filteredArray = [self calculationDataPoints];
  if (filteredArray.count == 0)
    return [NSNumber numberWithInt:0];

  NSExpression *expression = [NSExpression
      expressionForFunction:@"median:"
                  arguments:@[ [NSExpression
                                expressionForConstantValue:filteredArray] ]];
  NSNumber *value = [expression expressionValueWithObject:nil context:nil];

  return value;
}

- (NSNumber *)calculatePointValueMode {
  NSArray *filteredArray = [self calculationDataPoints];
  if (filteredArray.count == 0)
    return [NSNumber numberWithInt:0];

  NSExpression *expression = [NSExpression
      expressionForFunction:@"mode:"
                  arguments:@[ [NSExpression
                                expressionForConstantValue:filteredArray] ]];
  NSMutableArray *value =
      [expression expressionValueWithObject:nil context:nil];

  return [value firstObject];
}

- (NSNumber *)calculateLineGraphStandardDeviation {
  NSArray *filteredArray = [self calculationDataPoints];
  if (filteredArray.count == 0)
    return [NSNumber numberWithInt:0];

  NSExpression *expression = [NSExpression
      expressionForFunction:@"stddev:"
                  arguments:@[ [NSExpression
                                expressionForConstantValue:filteredArray] ]];
  NSNumber *value = [expression expressionValueWithObject:nil context:nil];

  return value;
}

- (NSNumber *)calculateMinimumPointValue {
  NSArray *filteredArray = [self calculationDataPoints];
  if (filteredArray.count == 0)
    return [NSNumber numberWithInt:0];

  NSExpression *expression = [NSExpression
      expressionForFunction:@"min:"
                  arguments:@[ [NSExpression
                                expressionForConstantValue:filteredArray] ]];
  NSNumber *value = [expression expressionValueWithObject:nil context:nil];
  return value;
}

- (NSNumber *)calculateMaximumPointValue {
  NSArray *filteredArray = [self calculationDataPoints];
  if (filteredArray.count == 0)
    return [NSNumber numberWithInt:0];

  NSExpression *expression = [NSExpression
      expressionForFunction:@"max:"
                  arguments:@[ [NSExpression
                                expressionForConstantValue:filteredArray] ]];
  NSNumber *value = [expression expressionValueWithObject:nil context:nil];

  return value;
}

@end
