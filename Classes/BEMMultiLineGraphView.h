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

@protocol BEMMultiLineGraphViewDataSource <BEMSimpleLineGraphDataSource>

@required
- (NSUInteger)numberOfLinesInGraph;

@required
- (BEMGraphDataSet *)lineGraph:(BEMMultiLineGraphView *)lineGraph
    dataSetForPointAtLineSection:(NSUInteger)section;

@end

@interface BEMMultiLineGraphView : UIView

@property(strong, nonatomic) id<BEMMultiLineGraphViewDataSource> dataSource;

@property(strong, nonatomic) id<BEMSimpleLineGraphDelegate> delegate;

@property(strong, nonatomic) BEMGraphOptions *options;

- (void)reloadGraph;

@end
