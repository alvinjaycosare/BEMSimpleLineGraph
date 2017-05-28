//
//  BEMGraphOptions.h
//  SimpleLineChart
//
//  Created by twidle on 5/25/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "BEMLine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BEMGraphOptions : NSObject

/// The graph's label font used on various axis. This property may be privately
/// overwritten, do not expect full functionality from this property.
@property(strong, nonatomic, nullable) UIFont *labelFont;

/// Time of the animation when the graph appears in seconds. Default value is
/// 1.5.
@property(nonatomic) CGFloat animationGraphEntranceTime;

/** Animation style used when the graph appears. Default value is
 BEMLineAnimationDraw.
 @see Refer to \p BEMLineAnimation for a complete list of animation styles. */
@property(nonatomic) BEMLineAnimation animationGraphStyle;

/// If set to YES, the graph will report the value of the closest point from the
/// user current touch location. The 2 methods for touch event bellow should
/// therefore be implemented. Default value is NO.
@property(nonatomic) BOOL enableTouchReport;

/** The number of fingers required to report touches to the graph's delegate.
 The default value is 1.
 @discussion Setting this value to greater than 1 might be beneficial in
 interfaces that allow the graph to scroll and still want to use touch
 reporting. */
@property(nonatomic) NSInteger touchReportFingersRequired;

/// If set to YES, a label will pop up on the graph when the user touches it. It
/// will be displayed on top of the closest point from the user current touch
/// location. Default value is NO.
@property(nonatomic) BOOL enablePopUpReport;

/// The way the graph is drawn, with or without bezier curved lines. Default
/// value is NO.
@property(nonatomic) IBInspectable BOOL enableBezierCurve;

/** Show Y-Axis label on the side. Default value is NO.
 @todo Could enhance further by specifying the position of Y-Axis, i.e. Left or
 Right of the view.  Also auto detection on label overlapping. */
@property(nonatomic) IBInspectable BOOL enableYAxisLabel;

/** Show X-Axis label at the bottom of the graph. Default value is YES.
 @see \p labelOnXAxisForIndex */
@property(nonatomic) IBInspectable BOOL enableXAxisLabel;

/** When set to YES, the points on the Y-axis will be set to all fit in the
 * graph view. When set to NO, the points on the Y-axis will be set with their
 * absolute value (which means that certain points might not be visible because
 * they are outside of the view). Default value is YES. */
@property(nonatomic) BOOL autoScaleYAxis;

/// The horizontal line across the graph at the average value.
@property(strong, nonatomic) BEMAverageLine *averageLine;

/// Draws a translucent vertical lines along the graph for each X-Axis when set
/// to YES. Default value is NO.
@property(nonatomic) BOOL enableReferenceXAxisLines;

/// Draws a translucent horizontal lines along the graph for each Y-Axis label,
/// when set to YES. Default value is NO.
@property(nonatomic) BOOL enableReferenceYAxisLines;

/** Draws a translucent frame between the graph and any enabled axis, when set
 to YES. Default value is NO.
 @see enableReferenceXAxisLines or enableReferenceYAxisLines must be set to YES
 for this property to have any effect.  */
@property(nonatomic) BOOL enableReferenceAxisFrame;

/** If reference frames are enabled, this will enable/disable specific borders.
 * Default: YES */
@property(nonatomic) BOOL enableLeftReferenceAxisFrameLine;

/** If reference frames are enabled, this will enable/disable specific borders.
 * Default: YES */
@property(nonatomic) BOOL enableBottomReferenceAxisFrameLine;

/** If reference frames are enabled, this will enable/disable specific borders.
 * Default: NO */
@property(nonatomic) BOOL enableRightReferenceAxisFrameLine;

/** If reference frames are enabled, this will enable/disable specific borders.
 * Default: NO */
@property(nonatomic) BOOL enableTopReferenceAxisFrameLine;

/// If set to YES, the dots representing the points on the graph will always be
/// visible. Default value is NO.
@property(nonatomic) BOOL alwaysDisplayDots;

/// If set to YES, the dots will be drawn during the animation.  If NO, dots
/// won't show up for the animation if alwaysDisplayDots if false.  Default
/// value is YES
@property(nonatomic) BOOL displayDotsWhileAnimating;

/// If set to YES, pop up labels with the Y-value of the point will always be
/// visible. Default value is NO.
@property(nonatomic) BOOL alwaysDisplayPopUpLabels;

/// Color of the bottom part of the graph (between the line and the X-axis).
@property(strong, nonatomic) IBInspectable UIColor *colorBottom;

/// Alpha of the bottom part of the graph (between the line and the X-axis).
@property(nonatomic) IBInspectable CGFloat alphaBottom;

/// Fill gradient of the bottom part of the graph (between the line and the
/// X-axis). When set, it will draw a gradient over top of the fill provided by
/// the \p colorBottom and \p alphaBottom properties.
@property(assign, nonatomic) CGGradientRef gradientBottom;

/// Color of the top part of the graph (between the line and the top of the view
/// the graph is drawn in).
@property(strong, nonatomic) IBInspectable UIColor *colorTop;

/// Alpha of the top part of the graph (between the line and the top of the view
/// the graph is drawn in).
@property(nonatomic) IBInspectable CGFloat alphaTop;

/// Fill gradient of the top part of the graph (between the line and the top of
/// the view the graph is drawn in). When set, it will draw a gradient over top
/// of the fill provided by the \p colorTop and \p alphaTop properties.
@property(assign, nonatomic) CGGradientRef gradientTop;

/// Color of the line of the graph.
@property(strong, nonatomic) IBInspectable UIColor *colorLine;

/// Fill gradient of the line of the graph, which will be scaled to the length
/// of the graph. Overrides the line color provided by \p colorLine
@property(assign, nonatomic) CGGradientRef gradientLine;

/// The drawing direction of the line gradient color, which defaults to
/// horizontal
@property(nonatomic) BEMLineGradientDirection gradientLineDirection;

/// Alpha of the line of the graph.
@property(nonatomic) IBInspectable CGFloat alphaLine;

/// Width of the line of the graph. Default value is 1.0.
@property(nonatomic) IBInspectable CGFloat widthLine;

/// Width of the reference lines of the graph. Default is the value of
/// widthLine/2.
@property(nonatomic) IBInspectable CGFloat widthReferenceLines;

/// Color of the reference lines of the graph. Default is same color as
/// `colorLine`.
@property(strong, nonatomic) UIColor *colorReferenceLines;

/// The size of the circles that represent each point. Default is 10.0.
@property(nonatomic) IBInspectable CGFloat sizePoint;

/// The color of the circles that represent each point. Default is white at 70%
/// alpha.
@property(strong, nonatomic) IBInspectable UIColor *colorPoint;

/// The color of the line that appears when the user touches the graph.
@property(strong, nonatomic) UIColor *colorTouchInputLine;

/// The alpha of the line that appears when the user touches the graph.
@property(nonatomic) CGFloat alphaTouchInputLine;

/// The width of the line that appears when the user touches the graph.
@property(nonatomic) CGFloat widthTouchInputLine;

/// Color of the label's text displayed on the X-Axis. Defaut value is
/// blackColor.
@property(strong, nonatomic) IBInspectable UIColor *colorXaxisLabel;

/// Color of the background of the X-Axis
@property(strong, nonatomic, nullable) UIColor *colorBackgroundXaxis;

/// Alpha of the background of the X-Axis
@property(nonatomic) CGFloat alphaBackgroundXaxis;

/// Color of the background of the Y-Axis
@property(strong, nonatomic, nullable) UIColor *colorBackgroundYaxis;

/// Alpha of the background of the Y-Axis
@property(nonatomic) CGFloat alphaBackgroundYaxis;

/// Color of the label's text displayed on the Y-Axis. Defaut value is
/// blackColor.
@property(strong, nonatomic) IBInspectable UIColor *colorYaxisLabel;

/// Color of the pop up label's background displayed when the user touches the
/// graph.
@property(strong, nonatomic) UIColor *colorBackgroundPopUplabel;

/// Position of the y-Axis in relation to the chart (Default: NO)
@property(nonatomic) BOOL positionYAxisRight;

/// A line dash patter to be applied to X axis reference lines.  This allows you
/// to draw a dotted or hashed line
@property(nonatomic, strong) NSArray *lineDashPatternForReferenceXAxisLines;

/// A line dash patter to be applied to Y axis reference lines.  This allows you
/// to draw a dotted or hashed line
@property(nonatomic, strong) NSArray *lineDashPatternForReferenceYAxisLines;

/// Color to be used for the no data label on the chart
@property(nonatomic, strong) UIColor *noDataLabelColor;

/// Font to be used for the no data label on the chart
@property(nonatomic, strong) UIFont *noDataLabelFont;

/// Float format string to be used when formatting popover and y axis values
@property(nonatomic, strong) NSString *formatStringForValues;

/** If a null value is present, interpolation would draw a best fit line through
 * the null point bound by its surrounding points.  Default: YES*/
@property(nonatomic) BOOL interpolateNullValues;

/// When set to YES, dots will be displayed at full opacity and no line will be
/// drawn through the dots. Default value is NO.
@property(nonatomic) BOOL displayDotsOnly;

@property(nonatomic) BOOL overlapYAxisWithGraph;

@property(nonatomic) BOOL enableThousandValueFormatter;

@property(nonatomic) NSTextAlignment alignmentYAxisLabel;

@property(nonatomic) BOOL allowOverlappingLabels;

@property(nonatomic) CGFloat marginLeftYAxisLabel;

@end

NS_ASSUME_NONNULL_END
