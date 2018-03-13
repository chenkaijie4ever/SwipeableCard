//
//  CKJSwipeableCardViewLayout.m
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import "CKJSwipeableCardViewLayout.h"
#import "CKJSwipeableCardViewDefine.h"

@implementation CKJSwipeableCardViewLayout

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _tierCount = DEFAULT_TIER_COUNT;
        _triggerRatio = DEFAULT_TRIGGER_RATIO;
        _maxRotateAngle = DEFAULT_MAX_ROTATE_ANGLE;
        _tierScaleInterval = DEFAULT_TIER_SCALE_INTERVAL;
        _tierSpacing = DEFAULT_TIER_SPACING;
        _horizontalPadding = DEFAULT_HORIZONTAL_PADDING;
        _verticalPadding = DEFAULT_VERTICAL_PADDDING;
        _dampingRatio = DEFAULT_DAMPING_RATIO;
        _velocity = DEFAULT_VELOCITY;
    }
    return self;
}

- (void)normalize {
    
    _tierCount = MAX(_tierCount, 1);
    
    _triggerRatio = fmax(0, _triggerRatio);
    _triggerRatio = fmin(1.0f , _triggerRatio);
    
    _tierScaleInterval = fmax(0, _tierScaleInterval);
    _tierScaleInterval = fmin(1.0f / _tierCount, _tierScaleInterval);
    
    _tierSpacing = fmax(0, _tierSpacing);
    
    _horizontalPadding = fmax(0, _horizontalPadding);
    _verticalPadding = fmax(0, _verticalPadding);
    
    _dampingRatio = fmax(0, _dampingRatio);
    _dampingRatio = fmin(1.0f , _dampingRatio);
    
    _velocity = fmax(0, _velocity);
    _velocity = fmin(1.0f , _velocity);
}

+ (instancetype)defaultLayout {
    
    return [[self alloc] init];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    
    CKJSwipeableCardViewLayout *layout = [[[self class] allocWithZone:zone] init];
    layout.tierCount = self.tierCount;
    layout.triggerRatio = self.triggerRatio;
    layout.maxRotateAngle = self.maxRotateAngle;
    layout.tierScaleInterval = self.tierScaleInterval;
    layout.tierSpacing = self.tierSpacing;
    layout.horizontalPadding = self.horizontalPadding;
    layout.verticalPadding = self.verticalPadding;
    layout.dampingRatio = self.dampingRatio;
    layout.velocity = self.velocity;
    return layout;
}

@end
