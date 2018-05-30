//
//  WBStickerLibraryViewController.h
//  WBPhotosFramework
//
//  Created by swit on 17/5/10.
//  Copyright © 2017年 weibo. All rights reserved.
//

#import "WBViewController.h"
#import "WBStickerLibraryTypeDetailViewController.h"
#import "WBStickerModel.h"
@class WBStickerLibraryViewController;

@protocol WBStickerLibraryViewControllerDelegate <NSObject>
@required
- (void)stickerLibraryViewController:(WBStickerLibraryViewController *)stickerLibaryView sticker:(WBStickerModel *)sticker;
- (void)stickerLibraryViewControllerDidShowVipHint:(WBStickerLibraryViewController *)stickerLibaryView;

- (void)stickerLibraryViewController:(WBStickerLibraryViewController *)stickerLibaryView stickerID:(NSString *)stickerID;
@end

/**
 *  贴纸库页面
 */
@interface WBStickerLibraryViewController : WBViewController<WBStickerLibraryTypeDetailViewDelegate>

@property (nonatomic, weak) id<WBStickerLibraryViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *backgroundImage;

/**
 启用新的样式

 @return WBStickerLibraryViewController实例
 */
- (instancetype)initWithNewStyle;

@end
