//
//  CKJSwipeableCardView.h
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKJSwipeableCardViewCell.h"
#import "CKJSwipeableCardViewLayout.h"
#import "CKJSwipeableCardViewDefine.h"
@class CKJSwipeableCardView;

typedef NS_OPTIONS(NSUInteger, CKJSwipeableCardViewSwipeDirection) {
    
    CKJSwipeableCardViewSwipeDirectionDefault           = 0,
    CKJSwipeableCardViewSwipeDirectionLeft              = 1 << 0,
    CKJSwipeableCardViewSwipeDirectionRight             = 1 << 1,
};

@protocol CKJSwipeableCardViewDataSource <NSObject>
@required

- (NSInteger)numberOfItemsInSwipeableCardView:(CKJSwipeableCardView *)swipeableCardView;

- (__kindof CKJSwipeableCardViewCell *)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView cellForItemAtIndex:(NSInteger)index;

@end

@protocol CKJSwipeableCardViewDelegate <NSObject>
@optional

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell didSelectItemAtIndex:(NSInteger)index;

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell draggingWidthDirection:(CKJSwipeableCardViewSwipeDirection)direction horizontalTranslateRatio:(CGFloat)horizontalTranslateRatio verticalTranslateRatio:(CGFloat)verticalTranslateRatio isManual:(BOOL)isManual;

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell didEndDraggingWidthDirection:(CKJSwipeableCardViewSwipeDirection)direction isManual:(BOOL)isManual;

- (void)swipeableCardViewDidEndDraggingLastCell:(CKJSwipeableCardView *)swipeableCardView;

/** Returns YES if the operation is allowed, NO otherwise. */
- (BOOL)swipeableCardViewShouldPerformOperation:(CKJSwipeableCardViewSwipeDirection)direction;

@end

@interface CKJSwipeableCardView : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame swipeableCardViewLayout:(CKJSwipeableCardViewLayout *)layout;

@property (nonatomic, weak) id <CKJSwipeableCardViewDelegate> delegate;
@property (nonatomic, weak) id <CKJSwipeableCardViewDataSource> dataSource;

/**
 * Reload the whole cardview, usually called for the first time.
 *
 * Example usage:
 *
 * - (void)fetchFirstPage {
 *     [_dataLogic fetchFirstPage:^(NSArray *dataList) {
 *         dataSource = dataList;
 *         [cardView reloadData];
 *     }];
 * }
 */
- (void)reloadData;
/**
 * Just refresh UI, called when appending data.
 *
 * Example usage:
 *
 * - (void)fetchMore {
 *     [_dataLogic fetchMore:^(NSArray *dataList) {
 *         [dataSource append:dataList];
 *         [cardView refreshIfNeeded];
 *     }];
 * }
 */
- (void)refreshIfNeeded;

- (void)removeThroughDirection:(CKJSwipeableCardViewSwipeDirection)direction;
- (void)removeThroughDirection:(CKJSwipeableCardViewSwipeDirection)direction delay:(CGFloat)delay;

@end
