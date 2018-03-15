//
//  CKJSwipeableCardView.m
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import "CKJSwipeableCardView.h"

@interface CKJSwipeableCardView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) CKJSwipeableCardViewLayout *layout;

@property (nonatomic, assign) NSUInteger currentLoadedIndex;
@property (nonatomic, assign) CKJSwipeableCardViewSwipeDirection currentSwipeDirection;
@property (nonatomic, strong) CKJSwipeableCardViewCell *currentMovingCell;
@property (nonatomic, assign) CGPoint baseCellCenter;
@property (nonatomic, assign) NSUInteger tierCount;

@property (nonatomic, strong) NSMutableArray <CKJSwipeableCardViewCell *> *currentCardViewCells;
@end

@implementation CKJSwipeableCardView

#pragma mark - Initial

- (instancetype)initWithFrame:(CGRect)frame {
    
    return [self initWithFrame:frame swipeableCardViewLayout:[CKJSwipeableCardViewLayout defaultLayout]];
}

- (instancetype)initWithFrame:(CGRect)frame swipeableCardViewLayout:(CKJSwipeableCardViewLayout *)layout {
    
    self = [super initWithFrame:frame];
    if (self) {
        _layout = [layout copy];
        [_layout normalize];
        _tierCount = _layout.tierCount;
        
        CGRect defaultCellFrame = [self defaultCardCellFrame];
        _baseCellCenter = CGPointMake(defaultCellFrame.origin.x + defaultCellFrame.size.width / 2.f,
                                      defaultCellFrame.origin.y + defaultCellFrame.size.height / 2.f);
        _currentCardViewCells = [NSMutableArray array];
        
        [self resetProperties];
    }
    return self;
}

#pragma mark - Inner methods

- (void)resetProperties {
    
    _currentLoadedIndex = 0;
    _currentSwipeDirection = CKJSwipeableCardViewSwipeDirectionDefault;
    _currentMovingCell = nil;
    [_currentCardViewCells removeAllObjects];
}

- (void)precheck {
    
    NSAssert(_dataSource, @"CKJSwipeableCardViewDataSource can't nil");
    NSAssert([_dataSource respondsToSelector:@selector(numberOfItemsInSwipeableCardView:)],
             @"CKJSwipeableCardViewDataSource should responds to selector : numberOfItemsInSwipeableCardView");
    NSAssert([_dataSource respondsToSelector:@selector(swipeableCardView:cellForItemAtIndex:)],
             @"CKJSwipeableCardViewDataSource should responds to selector : swipeableCardView:cellForItemAtIndex:");
}

- (CGRect)defaultCardCellFrame {
    
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    CGFloat maxSupportCellWidth = width - _layout.horizontalPadding * 2;
    CGFloat maxSupportCellHeight = height - (_layout.verticalPadding * 2 + _layout.tierSpacing * (_tierCount - 1));
    return CGRectMake(_layout.horizontalPadding, _layout.verticalPadding,
                      maxSupportCellWidth, maxSupportCellHeight);
}

- (void)configCell:(CKJSwipeableCardViewCell *)cell toLevel:(NSInteger)level {
    
    level = MAX(level, 0);
    level = MIN(level, _tierCount - 1);
    
    CGRect targetFrame = [self defaultCardCellFrame];
    CGAffineTransform targetTranform = CGAffineTransformIdentity;
    cell.transform = targetTranform;
    
    targetFrame.origin.y = targetFrame.origin.y + _layout.tierSpacing * level;
    targetTranform = CGAffineTransformScale(CGAffineTransformIdentity, 1 - _layout.tierScaleInterval * level, 1);
    cell.frame = targetFrame;
    cell.transform = targetTranform;
}

- (void)inflateNextItems {
    
    @synchronized(self) {
        NSInteger totalCount = [_dataSource numberOfItemsInSwipeableCardView:self];
        if (_currentLoadedIndex < totalCount) {
            NSUInteger inflateCount = MIN(totalCount, _tierCount);
            if (_currentMovingCell) inflateCount = MIN(totalCount, (_tierCount + 1));
            
            for (NSInteger index = _currentCardViewCells.count; index < inflateCount; index++) {
                if (_currentLoadedIndex >= totalCount) break;
                
                CKJSwipeableCardViewCell *cell = [_dataSource swipeableCardView:self
                                                             cellForItemAtIndex:_currentLoadedIndex];
                cell.currentIndex = _currentLoadedIndex;
                NSInteger level = MIN(_currentLoadedIndex, _tierCount - 1);
                [self configCell:cell toLevel:level];
                
                [cell setNeedsLayout];
                
                [self addSubview:cell];
                [self sendSubviewToBack:cell];
                
                UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
                panGestureRecognizer.delegate = self;
                [cell addGestureRecognizer:panGestureRecognizer];
                UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
                tapGestureRecognizer.delegate = self;
                [cell addGestureRecognizer:tapGestureRecognizer];
                
                [_currentCardViewCells addObject:cell];
                _currentLoadedIndex++;
            }
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    
    if ([_delegate respondsToSelector:@selector(swipeableCardView:swipeableCardViewCell:didSelectItemAtIndex:)]) {
        CKJSwipeableCardViewCell *cell = (CKJSwipeableCardViewCell *)gesture.view;
        [_delegate swipeableCardView:self swipeableCardViewCell:cell didSelectItemAtIndex:cell.currentIndex];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if (_currentMovingCell && _currentMovingCell != gestureRecognizer.view) {
        // Forbid tap gesture if handling pan gesture
        return NO;
    }
    return YES;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    
    CKJSwipeableCardViewCell *cell = (CKJSwipeableCardViewCell *)gesture.view;
    CGFloat horizontalTranslateRatio = (cell.center.x - _baseCellCenter.x) / _baseCellCenter.x;
    CGFloat verticalTranslateRatio = (cell.center.y - _baseCellCenter.y) / _baseCellCenter.y;
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            _currentMovingCell = cell;
            [self inflateNextItems];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translateDelta = [gesture translationInView:self];
            cell.center = CGPointMake(cell.center.x + translateDelta.x, cell.center.y + translateDelta.y);
            cell.transform = CGAffineTransformRotate(cell.originalTransform, horizontalTranslateRatio / _layout.normalTriggerRatio * _layout.maxRotateAngle);
            [gesture setTranslation:CGPointZero inView:self];
            
            if (horizontalTranslateRatio > 0) {
                _currentSwipeDirection = CKJSwipeableCardViewSwipeDirectionRight;
            } else if (horizontalTranslateRatio < 0) {
                _currentSwipeDirection = CKJSwipeableCardViewSwipeDirectionLeft;
            } else {
                _currentSwipeDirection = CKJSwipeableCardViewSwipeDirectionDefault;
            }
            [self adjustVisibleCells:horizontalTranslateRatio];
            
            if ([_delegate respondsToSelector:@selector(swipeableCardView:swipeableCardViewCell:draggingWidthDirection:horizontalTranslateRatio:verticalTranslateRatio:isManual:)]) {
                [_delegate swipeableCardView:self swipeableCardViewCell:cell draggingWidthDirection:_currentSwipeDirection
                    horizontalTranslateRatio:horizontalTranslateRatio verticalTranslateRatio:verticalTranslateRatio isManual:YES];
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {
            BOOL isDisappear = NO;
            // If move fast, trigger easily
            if (fabs([gesture velocityInView:self.superview].x) > 400) {
                isDisappear = (fabs(horizontalTranslateRatio) >= _layout.fastTriggerRatio);
            } else {
                isDisappear = (fabs(horizontalTranslateRatio) >= _layout.normalTriggerRatio);
            }
            
            [self finishedPanGesture:cell direction:_currentSwipeDirection isDisappear:isDisappear];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [self finishedPanGesture:cell direction:_currentSwipeDirection isDisappear:NO];
        }
            break;
        default:
            break;
    }
}

- (void)adjustVisibleCells:(CGFloat)horizontalTranslateRatio {
    
    CGFloat scaleInterval = _layout.tierScaleInterval;
    CGFloat ratio = fmin(fabs(horizontalTranslateRatio), _layout.normalTriggerRatio) / _layout.normalTriggerRatio;
    CGFloat scaleDelta = scaleInterval * ratio;
    CGFloat verticalTranslateDelta = _layout.tierSpacing * ratio;
    
    for (NSInteger index = 1; index < _currentCardViewCells.count; index++) {
        CKJSwipeableCardViewCell *cell = [_currentCardViewCells objectAtIndex:index];
        if (index >= _tierCount) {
            cell.transform = CGAffineTransformScale(CGAffineTransformIdentity, (1 - (index - 1) * scaleInterval), 1);
        } else {
            CGAffineTransform scaleTransform = CGAffineTransformScale(CGAffineTransformIdentity, (1 - index * scaleInterval) + scaleDelta, 1);
            CGAffineTransform mixTransform = CGAffineTransformTranslate(scaleTransform, 0, -verticalTranslateDelta);
            cell.transform = mixTransform;
        }
    }
}

- (void)finishedPanGesture:(CKJSwipeableCardViewCell *)cell direction:(CKJSwipeableCardViewSwipeDirection)direction isDisappear:(BOOL)isDisappear {
    
    if (isDisappear) {
        CGFloat factor = (direction == CKJSwipeableCardViewSwipeDirectionLeft ? -1 : 1);
        [UIView animateWithDuration:0.5f
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             cell.center = CGPointMake(CGRectGetWidth(self.bounds) * (factor * 2 + 0.5), _baseCellCenter.y);
                         } completion:^(BOOL finished) {
                             [cell removeFromSuperview];
                         }];
        [_currentCardViewCells removeObject:cell];
    } else {
        if (_currentMovingCell && _currentCardViewCells.count > _tierCount) {
            // Remove last cell
            CKJSwipeableCardViewCell *lastCell = [_currentCardViewCells lastObject];
            [lastCell removeFromSuperview];
            [_currentCardViewCells removeObject:lastCell];
            _currentLoadedIndex = lastCell.currentIndex;
        }
    }
    
    CKJSwipeableCardViewSwipeDirection finalDirection = (isDisappear ? direction : CKJSwipeableCardViewSwipeDirectionDefault);
    [self didEngDraggingCell:cell direction:finalDirection isManual:YES];
    
    _currentMovingCell = nil;
    [self reLayoutVisibleCells:^(BOOL finished) {
        if (_currentCardViewCells.count == 0 &&
            [_delegate respondsToSelector:@selector(swipeableCardViewDidEndDraggingLastCell:)]) {
            [_delegate swipeableCardViewDidEndDraggingLastCell:self];
        }
    }];
}

- (void)didEngDraggingCell:(CKJSwipeableCardViewCell *)cell direction:(CKJSwipeableCardViewSwipeDirection)direction isManual:(BOOL)isManual {
    
    if ([_delegate respondsToSelector:
         @selector(swipeableCardView:swipeableCardViewCell:draggingWidthDirection:horizontalTranslateRatio:verticalTranslateRatio:isManual:)]) {
        [_delegate swipeableCardView:self swipeableCardViewCell:cell draggingWidthDirection:direction
            horizontalTranslateRatio:0 verticalTranslateRatio:0 isManual:isManual];
    }
    if ([_dataSource respondsToSelector:@selector(swipeableCardView:swipeableCardViewCell:didEndDraggingWidthDirection:isManual:)]) {
        [_delegate swipeableCardView:self swipeableCardViewCell:cell didEndDraggingWidthDirection:direction isManual:isManual];
    }
}

- (void)reLayoutVisibleCells:(void (^ __nullable)(BOOL finished))completion {
    
    [UIView animateWithDuration:0.5f
                          delay:0.f
         usingSpringWithDamping:_layout.dampingRatio
          initialSpringVelocity:_layout.velocity
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         
                         for (NSInteger index = 0; index < _currentCardViewCells.count; index++) {
                             CKJSwipeableCardViewCell *cell = [_currentCardViewCells objectAtIndex:index];
                             NSInteger level = MIN(index, _tierCount - 1);
                             [self configCell:cell toLevel:level];
                             
                             cell.originalTransform = cell.transform;
                         }
                     } completion:completion];
}

#pragma mark - Public methods

- (void)reloadData {
    
    [self precheck];
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self resetProperties];
    [self inflateNextItems];
    [self reLayoutVisibleCells:nil];
}

- (void)refreshIfNeeded {
    
    [self inflateNextItems];
    if (!_currentMovingCell) {
        [self reLayoutVisibleCells:nil];
    }
}

- (void)removeThroughDirection:(CKJSwipeableCardViewSwipeDirection)direction {
    
    [self removeThroughDirection:direction delay:0.f];
}

- (void)removeThroughDirection:(CKJSwipeableCardViewSwipeDirection)direction delay:(CGFloat)delay {
    
    if (_currentMovingCell) return;
    if (_currentCardViewCells.count == 0) return;
    if ([_delegate respondsToSelector:@selector(swipeableCardViewShouldPerformOperation:)]
        && ![_delegate swipeableCardViewShouldPerformOperation:direction]) return;
    
    CKJSwipeableCardViewCell *cell = [_currentCardViewCells firstObject];
    _currentMovingCell = cell;
    cell.userInteractionEnabled = NO;
    
    if ([_delegate respondsToSelector:@selector(swipeableCardView:swipeableCardViewCell:draggingWidthDirection:horizontalTranslateRatio:verticalTranslateRatio:isManual:)]) {
        [_delegate swipeableCardView:self swipeableCardViewCell:cell draggingWidthDirection:direction
            horizontalTranslateRatio:0 verticalTranslateRatio:0 isManual:NO];
    }
    
    CGFloat factor = (direction == CKJSwipeableCardViewSwipeDirectionLeft ? -1 : 1);
    CGAffineTransform translateTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, CGRectGetHeight(self.bounds) * -0.02f);
    CGAffineTransform rotateTransform = CGAffineTransformRotate(translateTransform, _layout.maxRotateAngle * factor);
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5f
                          delay:delay
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         cell.center = CGPointMake(CGRectGetWidth(self.bounds) * (factor * 2 + 0.5), _baseCellCenter.y);
                         cell.transform = rotateTransform;
                     } completion:^(BOOL finished) {
                         [cell removeFromSuperview];
                         [_currentCardViewCells removeObject:cell];
                         
                         [weakSelf inflateNextItems];
                         [weakSelf reLayoutVisibleCells:nil];
                         
                         [weakSelf didEngDraggingCell:cell direction:direction isManual:NO];
                         if (_currentCardViewCells.count == 0 &&
                             [_delegate respondsToSelector:@selector(swipeableCardViewDidEndDraggingLastCell:)]) {
                             [_delegate swipeableCardViewDidEndDraggingLastCell:self];
                         }
                         _currentMovingCell = nil;
                     }];
}

@end
