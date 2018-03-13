//
//  CKJSwipeableCardViewCell.h
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CKJSwipeableCardViewCell : UIView

/** If you want to customize cells by simply adding additional views, you should add them to the content view. */
@property (nonatomic, readonly, strong) UIView *contentView;

/** Used internally, do not modify. */
@property (nonatomic, assign) NSInteger currentIndex;
/** Used internally, do not modify. */
@property (nonatomic, assign) CGAffineTransform originalTransform;

@property (nonatomic, assign, readonly) CGFloat oriWidth;
@property (nonatomic, assign, readonly) CGFloat oriHeight;

@end
