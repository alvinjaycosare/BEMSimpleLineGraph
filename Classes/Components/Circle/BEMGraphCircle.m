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

    self.absoluteValue = value.floatValue;
    self.alpha = 0;
  }
  return self;
}

- (void)setOptions:(BEMGraphOptions *)options {
  _options = options;

  self.Pointcolor = options.colorPoint;
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];

  [self showCircleLabelIfNeeded];
}

- (void)showCircleLabelIfNeeded {
  if (!self.shouldShowCircleLabel)
    return;

  CGFloat xCenterLabel = self.center.x;

  BEMPermanentPopupLabel *permanentPopUpLabel =
      [[BEMPermanentPopupLabel alloc] init];
  permanentPopUpLabel.textAlignment = NSTextAlignmentCenter;
  permanentPopUpLabel.numberOfLines = 0;

  NSString *prefix = self.labelPrefix;
  NSString *suffix = self.labelSuffix;

  NSNumber *value = @(self.absoluteValue);
  NSString *formattedValue = [NSString
      stringWithFormat:self.options.formatStringForValues, value.doubleValue];
  permanentPopUpLabel.text =
      [NSString stringWithFormat:@"%@%@%@", prefix, formattedValue, suffix];

  permanentPopUpLabel.font = self.options.labelFont;
  permanentPopUpLabel.backgroundColor = [UIColor clearColor];
  [permanentPopUpLabel sizeToFit];
  permanentPopUpLabel.center = CGPointMake(
      xCenterLabel, self.center.y - self.frame.size.height / 2 - 15);
  permanentPopUpLabel.alpha = 0;

  BEMPermanentPopupView *permanentPopUpView = [[BEMPermanentPopupView alloc]
      initWithFrame:CGRectMake(0, 0, permanentPopUpLabel.frame.size.width + 7,
                               permanentPopUpLabel.frame.size.height + 2)];
  permanentPopUpView.backgroundColor = self.options.colorBackgroundPopUplabel;
  permanentPopUpView.alpha = 0;
  permanentPopUpView.layer.cornerRadius = 3;
  permanentPopUpView.tag = 3100;
  permanentPopUpView.center = permanentPopUpLabel.center;

  if (permanentPopUpLabel.frame.origin.x <= 0) {
    xCenterLabel = permanentPopUpLabel.frame.size.width / 2 + 4;
    permanentPopUpLabel.center = CGPointMake(
        xCenterLabel, self.center.y - self.frame.size.height / 2 - 15);
  } else if (self.options.enableYAxisLabel == YES &&
             permanentPopUpLabel.frame.origin.x <= self.yAxisLabelOffset) {
    xCenterLabel = permanentPopUpLabel.frame.size.width / 2 + 4;
    permanentPopUpLabel.center =
        CGPointMake(xCenterLabel + self.yAxisLabelOffset,
                    self.center.y - self.frame.size.height / 2 - 15);
  } else if ((permanentPopUpLabel.frame.origin.x +
              permanentPopUpLabel.frame.size.width) >=
             self.superview.frame.size.width) {
    xCenterLabel = self.superview.frame.size.width -
                   permanentPopUpLabel.frame.size.width / 2 - 4;
    permanentPopUpLabel.center = CGPointMake(
        xCenterLabel, self.center.y - self.frame.size.height / 2 - 15);
  }

  if (permanentPopUpLabel.frame.origin.y <= 2) {
    permanentPopUpLabel.center = CGPointMake(
        xCenterLabel, self.center.y + self.frame.size.height / 2 + 15);
  }

  if ([self checkOverlapsForView:permanentPopUpView] == YES) {
    permanentPopUpLabel.center = CGPointMake(
        xCenterLabel, self.center.y + self.frame.size.height / 2 + 15);
  }

  permanentPopUpView.center = permanentPopUpLabel.center;

  [self.superview addSubview:permanentPopUpView];
  [self.superview addSubview:permanentPopUpLabel];

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
  for (UIView *viewForLabel in [self.superview subviews]) {
    if ([viewForLabel isKindOfClass:[UIView class]] &&
        viewForLabel.tag == 3100) {
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

@end
