//
//  SimpleCardViewCell.m
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import "SimpleCardViewCell.h"
#import "UIView+Convenience.h"

@interface SimpleCardViewCell()

@property (nonatomic, strong, readwrite) SimpleModel *model;
@property (nonatomic, assign) CKJSwipeableCardViewSwipeDirection preDirection;

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIImageView *likePostmark;
@property (nonatomic, strong) UIImageView *dislikePostmark;

@end

@implementation SimpleCardViewCell

+ (CGFloat)estimatedHeight {
    
    return [UIScreen mainScreen].bounds.size.width + 20;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        _preDirection = CKJSwipeableCardViewSwipeDirectionDefault;
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.allowsEdgeAntialiasing = YES;
        self.layer.cornerRadius = 10.f;
        self.layer.masksToBounds = NO;
        self.layer.shadowRadius = 3.f;
        self.layer.shadowOpacity = 0.2f;
        self.layer.shadowOffset = CGSizeMake(0, 1.f);
        
        self.contentView.layer.cornerRadius = self.layer.cornerRadius;
        self.contentView.layer.masksToBounds = YES;
        
        _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        _avatarImageView.backgroundColor = [UIColor colorWithRed:238 / 255.f green:238 / 255.f blue:238 / 255.f alpha:1];
        [self.contentView addSubview:_avatarImageView];
        
        _descLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _descLabel.numberOfLines = 1;
        _descLabel.textColor = [UIColor colorWithRed:118 / 255.f green:118 / 255.f blue:118 / 255.f alpha:1]; 
        _descLabel.font = [UIFont systemFontOfSize:20];
        [self.contentView addSubview:_descLabel];
        
        _likePostmark = [[UIImageView alloc] initWithFrame:CGRectZero];
        _likePostmark.image = [UIImage imageNamed:@"like_postmark.png"];
        _likePostmark.frame = CGRectMake(0, 0, 115, 86);
        _likePostmark.alpha = 0;
        [self.contentView addSubview:_likePostmark];
        
        _dislikePostmark = [[UIImageView alloc] initWithFrame:CGRectZero];
        _dislikePostmark.image = [UIImage imageNamed:@"dislike_postmark.png"];
        _dislikePostmark.frame = CGRectMake(0, 0, 115, 86);
        _dislikePostmark.alpha = 0;
        [self.contentView addSubview:_dislikePostmark];
    }
    return self;
}

- (void)setDataSource:(SimpleModel *)model {
    
    if (_model != model) {
        _model = model;
        
        _avatarImageView.image = [UIImage imageNamed:_model.imageName];
        _descLabel.text = _model.descString ?: @"";
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    CGFloat currentMaxY = 0.f;
    CGFloat maxSupportWidth = self.oriWidth - 2 * 16.f;
    
    _avatarImageView.frame = CGRectMake(0, 0, self.oriWidth, self.oriWidth);
    currentMaxY = _avatarImageView.bottom;
    
    [_descLabel sizeToFit];
    _descLabel.top = currentMaxY + 12;
    _descLabel.width = fmin(_descLabel.width, maxSupportWidth);
    _descLabel.centerX = self.oriWidth / 2.f;
    currentMaxY = _descLabel.bottom;
    
    _likePostmark.left = -20.f;
    _likePostmark.top = 40.f;
    
    _dislikePostmark.right = self.oriWidth + 20.f;
    _dislikePostmark.top = 40.f;
}

- (void)handlePostmarkWithDirection:(CKJSwipeableCardViewSwipeDirection)direction
           horizontalTranslateRatio:(CGFloat)horizontalTranslateRatio
                           isManual:(BOOL)isManual {
    
    if (!isManual) {
        BOOL stateChanged = (_preDirection != direction);
        switch (direction) {
            case CKJSwipeableCardViewSwipeDirectionLeft: {
                if (stateChanged) {
                    [self showPostmarkWithAnimation:_dislikePostmark];
                }
            }
                break;
            case CKJSwipeableCardViewSwipeDirectionRight: {
                if (stateChanged) {
                    [self showPostmarkWithAnimation:_likePostmark];
                }
            }
                break;
            default: // Do nothing
                break;
        }
        _preDirection = direction;
    } else {
        static CGFloat threshold = 0.05f;
        if (horizontalTranslateRatio <= -threshold) {
            direction = CKJSwipeableCardViewSwipeDirectionLeft;
        } else if (horizontalTranslateRatio < threshold) {
            direction = CKJSwipeableCardViewSwipeDirectionDefault;
        } else {
            direction = CKJSwipeableCardViewSwipeDirectionRight;
        }
        BOOL stateChanged = (_preDirection != direction);
        switch (direction) {
            case CKJSwipeableCardViewSwipeDirectionLeft: {
                if (stateChanged) {
                    [self showPostmarkWithAnimation:_dislikePostmark];
                }
            }
                break;
            case CKJSwipeableCardViewSwipeDirectionRight: {
                if (stateChanged) {
                    [self showPostmarkWithAnimation:_likePostmark];
                }
            }
                break;
            case CKJSwipeableCardViewSwipeDirectionDefault: {
                if (stateChanged && _preDirection == CKJSwipeableCardViewSwipeDirectionLeft) {
                    [self dismissPostmarkWithAnimation:_dislikePostmark];
                }
                if (stateChanged && _preDirection == CKJSwipeableCardViewSwipeDirectionRight) {
                    [self dismissPostmarkWithAnimation:_likePostmark];
                }
            }
                break;
        }
        _preDirection = direction;
    }
}

- (void)showPostmarkWithAnimation:(UIView *)view {
    
    view.alpha = 0;
    view.transform = CGAffineTransformMakeScale(1.8, 1.8);
    [UIView animateWithDuration:0.6f
                          delay:0.f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:1.0f
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         view.alpha = 1;
                         view.transform = CGAffineTransformIdentity;
                     } completion:nil];
}


- (void)dismissPostmarkWithAnimation:(UIView *)view {
    
    view.alpha = 1;
    view.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.6f
                          delay:0.f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:1.0f
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         view.alpha = 0;
                         view.transform = CGAffineTransformMakeScale(1.8, 1.8);
                     } completion:nil];
}

@end
