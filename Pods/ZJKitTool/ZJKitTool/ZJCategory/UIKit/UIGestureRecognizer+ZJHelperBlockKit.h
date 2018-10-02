//
//  UIGestureRecognizer+ZJHelperBlockKit.h
//  ZJUIKit
//
//  Created by dzj on 2018/1/18.
//  Copyright © 2018年 kapokcloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * gesture事件Block
 *
 */
typedef void(^ZJGestureBlock)(UIGestureRecognizer *gesture);


/**
 * Tap点击事件Block
 *
 */
typedef void(^ZJTapGestureBlock)(UITapGestureRecognizer *gesture);

/**
 * Tap长按事件Block
 *
 */
typedef void(^ZJLongGestureBlock)(UILongPressGestureRecognizer *gesture);

@interface UIGestureRecognizer (ZJHelperBlockKit)

/**
 *
 *    Make all gestures support block callback.
 *  This will support all kinds of gestures.
 */
@property (nonatomic, copy) ZJGestureBlock zj_onGesture;

/**
 *
 *    Make tap gesture support block callback.
 */
@property (nonatomic, copy) ZJTapGestureBlock zj_onTaped;

/**
 *
 *    Make long press gesture support block callback.
 */
@property (nonatomic, copy) ZJLongGestureBlock zj_onLongPressed;

@end
