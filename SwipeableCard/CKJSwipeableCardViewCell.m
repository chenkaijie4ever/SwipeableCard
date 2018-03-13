//
//  CKJSwipeableCardViewCell.m
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import "CKJSwipeableCardViewCell.h"

@interface CKJSwipeableCardViewCell ()

@property (nonatomic, readwrite, strong) UIView *contentView;

@end

@implementation CKJSwipeableCardViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.exclusiveTouch = YES;
        
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.layer.masksToBounds = YES;
        [self addSubview:_contentView];
    }
    return self;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    _contentView.frame = self.bounds;
}

- (CGFloat)oriWidth {
    
    return self.bounds.size.width;
}

- (CGFloat)oriHeight {
    
    return self.bounds.size.width;
}

@end
