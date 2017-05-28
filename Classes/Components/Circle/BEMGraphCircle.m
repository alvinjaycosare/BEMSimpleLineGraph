//
//  BEMGraphCircle.m
//  SimpleLineChart
//
//  Created by twidle on 5/28/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import "BEMGraphCircle.h"

#import "BEMGraphOptions.h"
#import "BEMPermanentPopupView.h"

@interface BEMGraphCircle ()

@property(strong, nonatomic) UILabel *label;

@property(strong, nonatomic) NSNumber *value;

@end

@implementation BEMGraphCircle

- (instancetype)initWithValue:(NSNumber *)value {
  if (self = [super init]) {
    _value = value;
  }
  return self;
}

- (void)setOptions:(BEMGraphOptions *)options {
  _options = options;
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
}

@end
