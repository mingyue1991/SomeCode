//
//  WBStickerLibraryTypeDetailViewController.h
//  WBPhotosFramework
//
//  Created by swit on 17/5/11.
//  Copyright © 2017年 weibo. All rights reserved.
//

#import "WBViewController.h"

@class WBStickerLibraryTypeDetailViewController;
@class WBStickerModel;
@class WBStickerLibraryViewController;
@protocol WBStickerLibraryTypeDetailViewDelegate <NSObject>
//选中一张贴纸
@required
- (void)stickerLibraryTypeDetailViewController:(WBStickerLibraryTypeDetailViewController *)stickerTypeView sticker:(WBStickerModel *)sticker;
- (void)stickerLibraryTypeDetailViewControllerDidShowVipHint:(WBStickerLibraryTypeDetailViewController *)stickerTypeView;

@end

@interface WBStickerLibraryTypeDetailViewController : WBTableViewController

@property (nonatomic, copy) NSString *categotyId;
@property (nonatomic, assign) BOOL isVipCategory;
@property (nonatomic, weak) WBStickerLibraryViewController *baseViewController;
@property (nonatomic, weak) id <WBStickerLibraryTypeDetailViewDelegate> delegate;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL usingNewStyle;

- (void)showRenewAnimation:(BOOL)animation;
- (void)hideRenewAnimation:(BOOL)animation;
- (void)updateWithNewStyle;
@end


#define KWBStickerLibraryCellReuseIdentifier     @"WBStickerLibraryTypeDetailCellIdentifier"
#define KWBStickerLibraryMoreCellReuseIdentifier @"WBStickerCollectionViewMoreCellIdentifier"
#define KWBStickerLibraryHeadReuseIdentifier     @"WBStickerCollectionViewHeadIdentifier"
