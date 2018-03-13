# About SwipeableCard

A card view which can be swiped left or right with single hand, just like TanTan, Tinder and Nice; You can control whether it should be commited or not before real operation.

## How to import into your project

Just drag the 'SwipeableCard' folder to your project.

## How to use it

you can initial the widget in Objective-C code in this way:

```objective-c

CKJSwipeableCardView *cardView = [[CKJSwipeableCardView alloc] initWithFrame:CGRectMake(0, 0, cardViewWidth, cardViewHeight)];
cardView.delegate = self;
cardView.dataSource = self;
[self.view addSubview:cardView];

```
you can also control the cardview's appearance using custom layout:

```objective-c

CKJSwipeableCardViewLayout *layout = [CKJSwipeableCardViewLayout defaultLayout];
layout.tierCount = 3;
layout.tierScaleInterval = 0.015f;
layout.tierSpacing = 6.f;
layout.horizontalPadding = 12.f;
layout.verticalPadding = 12.f;
...

CKJSwipeableCardView *cardView = [[CKJSwipeableCardView alloc] initWithFrame:CGRectMake(0, 0, cardViewWidth, cardViewHeight) swipeableCardViewLayout:layout];

```
Of cource, the PLSwipeableCardViewDataSource is required. This protocol represents the data model object.

```objective-c

@protocol PLSwipeableCardViewDataSource <NSObject>
@required

- (NSInteger)numberOfItemsInSwipeableCardView:(PLSwipeableCardView *)swipeableCardView;

- (__kindof PLSwipeableCardViewCell *)swipeableCardView:(PLSwipeableCardView *)swipeableCardView cellForItemAtIndex:(NSInteger)index;

@end

```
The protocol CKJSwipeableCardViewDelegate represents the display and behaviour of the cardview cells, it is optional. Typically, we implement our business logic here.

```objective-c

@protocol CKJSwipeableCardViewDelegate <NSObject>
@optional

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell didSelectItemAtIndex:(NSInteger)index;

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell draggingWidthDirection:(CKJSwipeableCardViewSwipeDirection)direction horizontalTranslateRatio:(CGFloat)horizontalTranslateRatio verticalTranslateRatio:(CGFloat)verticalTranslateRatio isManual:(BOOL)isManual;

- (void)swipeableCardView:(CKJSwipeableCardView *)swipeableCardView swipeableCardViewCell:(CKJSwipeableCardViewCell *)swipeableCardViewCell didEndDraggingWidthDirection:(CKJSwipeableCardViewSwipeDirection)direction isManual:(BOOL)isManual;

- (void)swipeableCardViewDidEndDraggingLastCell:(CKJSwipeableCardView *)swipeableCardView;

/** Returns YES if the operation is allowed, NO otherwise. */
- (BOOL)swipeableCardViewShouldPerformOperation:(CKJSwipeableCardViewSwipeDirection)direction;

@end

```
## What does it look like


## Author

Chen Kaijie

chenkaijie4ever@gmail.com


## LICENSE

Copyright 2018 Chen Kaijie

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

