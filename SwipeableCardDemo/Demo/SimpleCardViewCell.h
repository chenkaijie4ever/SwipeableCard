//
//  SimpleCardViewCell.h
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import "CKJSwipeableCardViewCell.h"
#import "CKJSwipeableCardView.h"
#import "SimpleModel.h"

@interface SimpleCardViewCell : CKJSwipeableCardViewCell

@property (nonatomic, strong, readonly) SimpleModel *model;

- (void)setDataSource:(SimpleModel *)model;

- (void)handlePostmarkWithDirection:(CKJSwipeableCardViewSwipeDirection)direction
           horizontalTranslateRatio:(CGFloat)horizontalTranslateRatio
                           isManual:(BOOL)isManual;

+ (CGFloat)estimatedHeight;

@end
