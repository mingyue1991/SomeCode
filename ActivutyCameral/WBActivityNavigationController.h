//
//  WBActivityNavigationController.h
//  WBPhotosFramework
//
//  Created by swit on 2018/4/28.
//  Copyright © 2018年 weibo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WBActivityNavigationController;
@class WBImageEditorCache;
@protocol WBActivityPickFaceImageCacheDelegate <NSObject>
- (void)WBActivityController:(WBActivityNavigationController *)navigationController finishedPickFaceImageCache:(WBImageEditorCache *)cache;
- (void)WBActivityControllerPickFaceImageCanceled:(WBActivityNavigationController *)navigationController;
@end

@interface WBActivityNavigationController : UINavigationController
@property (nonatomic, weak) id <WBActivityPickFaceImageCacheDelegate> pickerDelegate;
@end
