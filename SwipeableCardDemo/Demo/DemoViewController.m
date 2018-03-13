//
//  DemoViewController.m
//  SwipeableCard
//
//  Created by ckj on 2018/3/8.
//  Copyright © 2018年 ckj. All rights reserved.
//

#import "DemoViewController.h"
#import "CKJSwipeableCardView.h"
#import "SimpleCardViewCell.h"
#import "SimpleModel.h"
#import "UIView+Convenience.h"
#import "Reachability.h"

#define FETCH_COUNT_PER_TIME            10
#define FETCH_NEXT_PAGE_THRESHOLD       5

typedef NS_OPTIONS(NSUInteger, AlertType) {
    
    AlertType_NetworkInvalid        = 0,
    AlertType_HandleTapAction       = 1,
    AlertType_NoMoreData            = 2,
};

@interface DemoViewController () <CKJSwipeableCardViewDelegate, CKJSwipeableCardViewDataSource>

@property (nonatomic, strong) CKJSwipeableCardView *cardView;
@property (nonatomic, strong) UIButton *disLikeButton;
@property (nonatomic, strong) UIButton *likeButton;

@property (nonatomic, strong) NSMutableArray <SimpleModel *> *dataSources;
@property (nonatomic, assign) BOOL isFetchingMore;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    [self refreshData];
}

- (void)initUI {
    
    CKJSwipeableCardViewLayout *layout = [CKJSwipeableCardViewLayout defaultLayout];
    layout.tierCount = 3;
    
    CGFloat cardViewWidth = self.view.width;
    CGFloat cardViewHeight = [SimpleCardViewCell estimatedHeight] + layout.tierSpacing * (layout.tierCount - 1) + layout.verticalPadding * 2;
    _cardView = [[CKJSwipeableCardView alloc] initWithFrame:CGRectMake(0, 80, cardViewWidth, cardViewHeight)
                                    swipeableCardViewLayout:layout];
    _cardView.delegate = self;
    _cardView.dataSource = self;
    [self.view addSubview:_cardView];
    
    _disLikeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, _cardView.bottom + 18, 70, 70)];
    _disLikeButton.exclusiveTouch = YES;
    _disLikeButton.centerX = self.view.centerX - 65;
    [_disLikeButton setImage:[UIImage imageNamed:@"dislike_btn.png"] forState:UIControlStateNormal];
    [_disLikeButton addTarget:self action:@selector(onDislikeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_disLikeButton];
    
    _likeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
    _likeButton.exclusiveTouch = YES;
    _likeButton.centerX = self.view.centerX + 65;
    _likeButton.centerY = _disLikeButton.centerY;
    [_likeButton setImage:[UIImage imageNamed:@"like_btn.png"] forState:UIControlStateNormal];
    [_likeButton addTarget:self action:@selector(onLikeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_likeButton];
}

#pragma mark - DataSource

- (NSInteger)numberOfItemsInSwipeableCardView:(CKJSwipeableCardView *)swipeableCardView {
    
    return _dataSources.count;
}

- (CKJSwipeableCardViewCell *)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView cellForItemAtIndex:(NSInteger)index {
    
    SimpleCardViewCell *cell = [[SimpleCardViewCell alloc] initWithFrame:swipeableCardView.bounds];
    if (index < _dataSources.count) {
        SimpleModel *model = [_dataSources objectAtIndex:index];
        [cell setDataSource:model];
    }
    return cell;
}

#pragma mark - Delegate

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell didSelectItemAtIndex:(NSInteger)index {
    
    SimpleCardViewCell *cell = (SimpleCardViewCell *)swipeableCardViewCell;
    SimpleModel *model = cell.model;
    
    [self showAlertView:AlertType_HandleTapAction info:model];
}

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell draggingWidthDirection:(CKJSwipeableCardViewSwipeDirection)direction horizontalTranslateRatio:(CGFloat)horizontalTranslateRatio verticalTranslateRatio:(CGFloat)verticalTranslateRatio isManual:(BOOL)isManual {
    
    CGFloat ratio = fmin(fabs(horizontalTranslateRatio), DEFAULT_TRIGGER_RATIO) / DEFAULT_TRIGGER_RATIO;
    CGFloat scale = 1 - ratio * 0.15;
    if (direction == CKJSwipeableCardViewSwipeDirectionLeft) {
        _disLikeButton.transform = CGAffineTransformMakeScale(scale, scale);
    }
    if (direction == CKJSwipeableCardViewSwipeDirectionRight) {
        _likeButton.transform = CGAffineTransformMakeScale(scale, scale);
    }
    
    SimpleCardViewCell *cell = (SimpleCardViewCell *)swipeableCardViewCell;
    [cell handlePostmarkWithDirection:direction horizontalTranslateRatio:horizontalTranslateRatio isManual:isManual];
}

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell didEndDraggingWidthDirection:(CKJSwipeableCardViewSwipeDirection)direction isManual:(BOOL)isManual {
    
    _disLikeButton.transform = CGAffineTransformIdentity;
    _likeButton.transform = CGAffineTransformIdentity;
    
    SimpleCardViewCell *cell = (SimpleCardViewCell *)swipeableCardViewCell;
    SimpleModel *model = cell.model;
    switch (direction) {
        case CKJSwipeableCardViewSwipeDirectionLeft: {
            [self handleDislikeAction:model];
        }
            break;
        case CKJSwipeableCardViewSwipeDirectionRight: {
            [self handleLikeAction:model];
        }
        default: // Do nothing here
            break;
    }
    
    if ((_dataSources.count - cell.currentIndex) <= FETCH_NEXT_PAGE_THRESHOLD) {
        [self fetchMoreIfNecessary];
    }
}

- (void)swipeableCardViewDidEndDraggingLastCell:(CKJSwipeableCardView *)swipeableCardView {
    
    [self showAlertView:AlertType_NoMoreData info:nil];
}

- (BOOL)swipeableCardViewShouldPerformOperation:(CKJSwipeableCardViewSwipeDirection)direction {
    
    if ([Reachability networkStatus] == NotReachable) {
        [self showAlertView:AlertType_NetworkInvalid info:nil];
        return NO;
    }
    return YES;
}

#pragma mark - UI Action

- (void)onDislikeButtonClick:(id)sender {
    
    [_cardView removeThroughDirection:CKJSwipeableCardViewSwipeDirectionLeft delay:0.5f];
}

- (void)onLikeButtonClick:(id)sender {
    
    [_cardView removeThroughDirection:CKJSwipeableCardViewSwipeDirectionRight delay:0.5f];
}

#pragma mark - AlertView Logic

- (void)showAlertView:(AlertType)alertType info:(id)info {
    
    UIAlertView *alertView = nil;
    switch (alertType) {
        case AlertType_NetworkInvalid: {
            alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                   message:@"Network invalid"
                                                  delegate:nil
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Confirm", nil];
        }
            break;
        case AlertType_HandleTapAction: {
            NSString *message = [NSString stringWithFormat:@"Desc : %@", ((SimpleModel *)info).descString];
            alertView = [[UIAlertView alloc] initWithTitle:@"Tap event"
                                                   message:message
                                                  delegate:nil
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Confirm", nil];
        }
            break;
        case AlertType_NoMoreData: {
            alertView = [[UIAlertView alloc] initWithTitle:@"Prompt"
                                                   message:@"No more data."
                                                  delegate:nil
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Confirm", nil];
        }
            break;
        default:
            break;
    }
    if (alertView) {
        alertView.tag = alertType;
        [alertView show];
    }
}

#pragma mark - Logic

- (void)refreshData {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSMutableArray <SimpleModel *> *fakeData = [NSMutableArray array];
        for (NSInteger index = 0; index < FETCH_COUNT_PER_TIME; index++) {
            SimpleModel *model = [SimpleModel new];
            model.imageName = [NSString stringWithFormat:@"image_%ld.jpg", (index + 1) % 10];
            model.descString = [NSString stringWithFormat:@"Test %ld", index + 1];
            [fakeData addObject:model];
        }
        _dataSources = [NSMutableArray arrayWithArray:fakeData];
        [_cardView reloadData];
    });
}

- (void)fetchMoreIfNecessary {
    
    if (_isFetchingMore) return;
    _isFetchingMore = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSMutableArray <SimpleModel *> *fakeData = [NSMutableArray array];
        NSInteger currentCount = _dataSources.count;
        for (NSInteger index = currentCount; index < currentCount + FETCH_COUNT_PER_TIME; index++) {
            SimpleModel *model = [SimpleModel new];
            model.imageName = [NSString stringWithFormat:@"image_%ld.jpg", (index + 1) % 10];
            model.descString = [NSString stringWithFormat:@"Test %ld", index + 1];
            [fakeData addObject:model];
        }
        NSMutableArray *tmp = [NSMutableArray arrayWithArray:_dataSources];
        [tmp addObjectsFromArray:fakeData];
        _dataSources = tmp;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_cardView refreshIfNeeded];
        });
        _isFetchingMore = NO;
    });
}

- (void)handleLikeAction:(SimpleModel *)model { /** Post request */ }

- (void)handleDislikeAction:(SimpleModel *)model { /** Post request */ }

@end
