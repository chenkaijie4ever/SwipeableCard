//
//  CKJSwipeableCardViewLayout.h
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CKJSwipeableCardViewLayout : NSObject

@property (nonatomic, assign) NSUInteger tierCount;

@property (nonatomic, assign) CGFloat fastTriggerRatio;
@property (nonatomic, assign) CGFloat normalTriggerRatio;
@property (nonatomic, assign) CGFloat maxRotateAngle;

@property (nonatomic, assign) CGFloat tierScaleInterval;
@property (nonatomic, assign) CGFloat tierSpacing;

@property (nonatomic, assign) CGFloat horizontalPadding;
@property (nonatomic, assign) CGFloat verticalPadding;

@property (nonatomic, assign) CGFloat dampingRatio;
@property (nonatomic, assign) CGFloat velocity;

- (void)normalize;

+ (instancetype)defaultLayout;

@end
