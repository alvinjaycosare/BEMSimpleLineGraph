//
//  BEMMultiLineGraphView.h
//  SimpleLineChart
//
//  Created by twidle on 5/25/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BEMSimpleLineGraphView.h"

@class BEMMultiLineGraphView;
@class BEMGraphOptions;
@class BEMGraphDataSet;

@protocol BEMSimpleLineGraphDelegate;
@protocol BEMSimpleLineGraphDataSource;

@protocol BEMMultiLineGraphViewDataSource <NSObject>

- (BEMGraphOptions *)multiLineGraph:(BEMMultiLineGraphView *)lineGraph
       viewOptionsOfLineWithDataSet:(BEMGraphDataSet *)dataSet;

@end

@interface BEMMultiLineGraphView : BEMSimpleLineGraphView

@property(weak, nonatomic) IBOutlet id<BEMMultiLineGraphViewDataSource>
    multiLineDataSource;

@property(strong, nonatomic) NSArray<BEMGraphDataSet *> *dataSets;

@property(strong, nonatomic) BEMGraphOptions *options;

- (void)reloadGraph;

@end
