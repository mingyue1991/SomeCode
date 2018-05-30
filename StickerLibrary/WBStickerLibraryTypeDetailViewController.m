//
//  WBStickerLibraryTypeDetailViewController.m
//  WBPhotosFramework
//
//  Created by swit on 17/5/11.
//  Copyright © 2017年 weibo. All rights reserved.
//

#import "WBStickerLibraryTypeDetailViewController.h"
#import "WBStickerLibrayModel.h"
#import "WBStickerModel.h"
#import "WBStickerLibraryStickerCell.h"
#import "WBStickerLibraryStickerNewStyleCell.h"
#import "WBStickerLibraryStickerMoreCell.h"
#import "WBStickerLibraryTypeDetailHeaderView.h"
#import "WBProgressHUD.h"
#import "WBStaticStickerModel.h"
#import "WBDynamicStickerModel.h"
#import "WBAppStickerModel.h"
#import "WBStickerLibraryViewController.h"
#import "WBGIFStickerModel.h"
#import "WBFilterStickerMarket.h"
#import "WBOpenUrlManager.h"
#import "WBABTestSDK.h"
#import "WBTDReachability.h"
#import "WBSegmentChannelModel.h"
#import "UIImageView+WBImage.h"

#define NSStringIsNullOrEmpty(str) ((str == nil) || [(str) isEqualToString:@""])

#define CollectionViewRowsPerSection 3
#define CollectionViewHeaderHeight   WBScaleWithOptions(52, { .iphone6 = 52, .iphone6p = 55, .ipad = 65 })
#define CollectionViewSectionInset   13.0
#define CollectionViewSpacing        3.0
#define CollectionViewItemRatio      1
#define TitleFontSize                WBScaleWithOptions(14, { .iphone6 = 14, .iphone6p = 15, .ipad = 18 })

@interface WBStickerLibraryTypeDetailViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, WBSegmentChannelViewControllerProtocol>{
    BOOL _isSupportSplitScreen;
}
@property (nonatomic, strong) UIView *collectionViewHeaderView;
@property (nonatomic, strong) UICollectionViewLayout *collectionViewLayout;
@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, assign) CGSize cellSize;
@property (nonatomic, assign, getter = isLandscapeLayout) BOOL landscapeLayout;   // 横竖屏布局控制..
@property (nonatomic, strong) WBStickerLibrayModel *stickerLibrayModel;
@property (nonatomic, assign) BOOL isFromCache;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) WBProgressHUD *loadHudView;
@property (nonatomic, strong) WBTableViewEmptyView *errorView;
@property (nonatomic, strong) WBTableViewEmptyView *emptyView;
@property (nonatomic, strong) UIButton *payButton;
@property (nonatomic, strong) UILabel *payHintLabel;

@end

@implementation WBStickerLibraryTypeDetailViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _isSupportSplitScreen = [[UIDevice currentDevice] wbt_isIPad] && WBAvalibleOS(9);
        _isFromCache = YES;
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
    [super loadView];
    self.tableView.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self resetLayoutConfig];
    [self.view addSubview:self.collectionView];
    if (self.isVipCategory) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(vipStickerMinipayFinishedNotification:)
                                                     name:@"WBVipMinipayFinishedNotifiction"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(vipStickerIAPpayFinished:)
                                                     name:@"IapManagerBuyProductFinished"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(vipStickerIAPpayFailed:)
                                                     name:@"IapManagerBuyProductFailed"
                                                   object:nil];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([[UIDevice currentDevice] wbt_isIPad]) {
        self.payButton.frame = CGRectMake(self.collectionView.wbtWidth - 12 - 70, 8, 70, 28);
        self.payHintLabel.frame = CGRectMake(12, 0, self.payButton.wbtLeft - 12 * 2, 44);
        self.errorView.frame = CGRectMake(0, 0, self.view.wbtWidth, self.view.wbtHeight);
        self.emptyView.frame = CGRectMake(0, 0, self.view.wbtWidth, self.view.wbtHeight);
    }

    [self checkOrientation];
}

// - (void)viewWillAppear:(BOOL)animated
// {
//    [super viewWillAppear:animated];
//    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
//    //[self checkOrientation];
// }

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self hideLoadingView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)checkOrientation {
    self.landscapeLayout = (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation));
}

- (void)setLandscapeLayout:(BOOL)landscapeLayout {
    if (_landscapeLayout != landscapeLayout || _isSupportSplitScreen) {
        _landscapeLayout = landscapeLayout;
        [self resetLayoutConfig];
        [self.collectionView reloadData];
    }
}

- (void)resetLayoutConfig {
    _landscapeLayout = (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation));

    CGFloat padding = CollectionViewSpacing;
    CGFloat rowCount = 4;
    if ([[UIDevice currentDevice] wbt_isIPad]) {
        //        CGFloat viewScale = self.view.wbtWidth / self.view.wbtHeight;
        //        CGFloat screenScale = [UIScreen mainScreen].bounds.size.width / [UIScreen mainScreen].bounds.size.height;
        //        CGFloat screenScale2 = [UIScreen mainScreen].bounds.size.height / [UIScreen mainScreen].bounds.size.width;
        //        BOOL isMultiscreen = (viewScale != screenScale && viewScale != screenScale2);
        // iPad分屏模式显示3个
        //        if (isMultiscreen) {
        //            rowCount = 3;
        //        }
        //        else
        // 暂不考虑分屏
        if (_landscapeLayout) {
            rowCount = 7;
        } else {
            rowCount = 5;
        }
    }
    self.rowCount = rowCount;
    CGFloat itemWidth = floor((WBKeyWindowRealWidth - CollectionViewSectionInset * 2 - padding * (rowCount - 1)) / rowCount);
    self.cellSize = CGSizeMake(itemWidth, itemWidth);
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.collectionViewLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
        // 用于自动化测试
        _collectionView.accessibilityIdentifier = @"StickerCollectionView";

        if (self.isVipCategory && ![[WBAccountManager currentAccount].user isValidMemberShip]) {// 是会员分类并且不是会员的时候显示
            _collectionView.contentInset = UIEdgeInsetsMake(44, 0, 10, 0);
            [_collectionView addSubview:self.collectionViewHeaderView];
        }
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[WBStickerLibraryStickerCell class] forCellWithReuseIdentifier:KWBStickerLibraryCellReuseIdentifier];
        [_collectionView registerClass:[WBStickerLibraryStickerMoreCell class] forCellWithReuseIdentifier:KWBStickerLibraryMoreCellReuseIdentifier];
        [_collectionView registerClass:[WBStickerLibraryTypeDetailHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:KWBStickerLibraryHeadReuseIdentifier];
    }

    return _collectionView;
}

- (UICollectionViewLayout *)collectionViewLayout {
    if (!_collectionViewLayout) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(0.0, CollectionViewSectionInset, 0.0, CollectionViewSectionInset);
        layout.minimumInteritemSpacing = CollectionViewSpacing;
        layout.minimumLineSpacing = CollectionViewSpacing;
        [layout setHeaderReferenceSize:CGSizeMake(self.view.frame.size.width, CollectionViewHeaderHeight)];
        [layout setScrollDirection:UICollectionViewScrollDirectionVertical];
        _collectionViewLayout = layout;
    }

    return _collectionViewLayout;
}

- (UIView *)collectionViewHeaderView {
    if (!_collectionViewHeaderView) {
        _collectionViewHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, -44, WBKeyWindowRealWidth, 44)];
        _collectionViewHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIButton *reNewButton = [[UIButton alloc] initWithFrame:CGRectMake(self.collectionView.wbtWidth - 12 - 70, 8, 70, 28)];
        reNewButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        reNewButton.layer.cornerRadius = 2;
        reNewButton.clipsToBounds = YES;
        UIColor *color = [UIColor wbt_ColorWithHexString:@"#FF8200"];
        reNewButton.layer.borderColor = color.CGColor;
        reNewButton.layer.borderWidth = 1;
        [reNewButton setTitleColor:color forState:UIControlStateNormal];
        [reNewButton setTitle:loadMuLanguage(@"续费会员", nil) forState:UIControlStateNormal];
        reNewButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [reNewButton addTarget:self action:@selector(reNewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.payButton = reNewButton;
        [_collectionViewHeaderView addSubview:reNewButton];

        UILabel *reNewHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, reNewButton.wbtLeft - 12 * 2, 44)];
        reNewHintLabel.numberOfLines = 2;
        reNewHintLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        reNewHintLabel.text = loadMuLanguage(@"续费会员，立即尊享会员专属贴纸！", nil);
        reNewHintLabel.font = [UIFont systemFontOfSize:TitleFontSize];
        reNewHintLabel.textColor = [UIColor wbt_ColorWithHexString:@"#333333"];
        self.payHintLabel = reNewHintLabel;
        [_collectionViewHeaderView addSubview:reNewHintLabel];

        if (self.usingNewStyle) {
            reNewButton.layer.cornerRadius = 14;
            reNewButton.contentEdgeInsets = UIEdgeInsetsMake(0, 13, 0, 13);
            [reNewButton sizeToFit];
            reNewButton.wbtRight = self.collectionView.wbtWidth - 12;
            reNewHintLabel.textColor = [UIColor whiteColor];
        }

        //        UIImageView *lineShadow = [[UIImageView alloc] initWithFrame:CGRectMake(0, 43, _collectionViewHeaderView.frame.size.width, 1)];
        //        lineShadow.image = [UIImage skinImageWithCenterStretchNamed:@"common_shadow_top.png"];
        //        lineShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        //        [_collectionViewHeaderView addSubview:lineShadow];
    }

    return _collectionViewHeaderView;
}

- (void)showRenewAnimation:(BOOL)animation {
    if (self.collectionView.contentInset.top < 44) {
        if (animation) {
            [UIView animateWithDuration:0.25 animations:^{
                //        self.collectionViewHeaderView.wbtBottom = 0;
                self.collectionView.contentInset = UIEdgeInsetsMake(44, 0, 10, 0);
            } completion:^(BOOL finished) {
                ;
            }];
        } else {
            self.collectionView.contentInset = UIEdgeInsetsMake(44, 0, 10, 0);
        }
    }
}

- (void)hideRenewAnimation:(BOOL)animation {
    if (self.collectionView.contentInset.top > 0) {
        if (animation) {
            [UIView animateWithDuration:0.25 animations:^{
                //        self.collectionViewHeaderView.wbtBottom = 0;
                self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
            } completion:^(BOOL finished) {
                [self.collectionViewHeaderView removeFromSuperview];
            }];
        } else {
            self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
            [self.collectionViewHeaderView removeFromSuperview];
        }
    }
}

- (void)reNewButtonPressed:(UIButton *)sender {
    if ([[WBAccountManager currentAccount].user isValidMemberShip]) {
        [self hideRenewAnimation:NO];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(stickerLibraryTypeDetailViewControllerDidShowVipHint:)]) {
            [self.delegate stickerLibraryTypeDetailViewControllerDidShowVipHint:self];
        }
        [self openVipPayView];
    }
}

- (void)showBecomeVIPTips {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerLibraryTypeDetailViewControllerDidShowVipHint:)]) {
        [self.delegate stickerLibraryTypeDetailViewControllerDidShowVipHint:self];
    }
    WBAlertController *downloadAlert = [WBAlertController alertControllerWithTitle:nil message:loadMuLanguage(@"这是会员专属贴纸，立刻续费会员使用该贴纸吗？", nil)];
    [downloadAlert addCancelButtonWithText:loadMuLanguage(@"以后再说", nil) handler:nil];
    [downloadAlert addOkButtonWithText:loadMuLanguage(@"续费会员", nil) handler:^(UIAlertAction *_Nonnull action) {
        [[WBAnalysisManager sharedManager] logWithCode:@"1923" andExtraParameters:nil];
        [self openVipPayView];
    }];

    [[[WBOpenUrlManager sharedManager] topModelViewController] presentViewController:downloadAlert animated:YES completion:nil];
}

- (void)openVipPayView {
    NSString *scheme = @"sinaweibo://vipminipay?type=sticker&channel=tq_pldt_tzk";
    // 支付宝、微信用 sinaweibo://vipminipay?type=sticker&channel=SX_weibopay_
    // 线上用 sinaweibo://vipminipay?type=sticker&channel=tq_pldt_tzk
    BOOL enable = [WBABTestSDK isFeatureEnabled:@"feature_photos_weipay_debug_enable" withPolicy:WBABTestFeatureSyncWithServerPolicy];

    if (enable) {
        scheme = @"sinaweibo://vipminipay?type=sticker&channel=SX_weibopay_";
    }
    [[WBOpenUrlManager sharedManager] addContextByString:scheme
                                      baseViewController:nil
                                           appInvokeType:EWBOpenUrlInvokeTypeInApp
                                               ejectType:EWBOpenUrlEjectViewTypePush
                                                paraDict:nil];
}

- (NSInteger)columPerRow {
    return self.rowCount;
}

- (void)updateWithStickerModel:(WBStickerLibrayModel *)model isFromCache:(BOOL)isCache {
    self.stickerLibrayModel = model;
    self.isFromCache = isCache;
    [self.collectionView reloadData];
    if (!isCache && [self hasData]) {
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            [self storeToCache:self.stickerLibrayModel];
            NSMutableArray *allStickers = [[NSMutableArray alloc] init];
            for (int i = 0; i < self.stickerLibrayModel.themeList.count; i++) {
                WBStickerThemeModel *themes = self.stickerLibrayModel.themeList[i];
                for (int j = 0; j < themes.stickersList.count; j++) {
                    WBStickerModel *sticker = themes.stickersList[j];
                    if (sticker) {
                        [allStickers addObject:sticker];
                    }
                }
            }
            [[WBFilterStickerMarket sharedMarket] updateLocalStickers:allStickers];
        });
    }
}

- (BOOL)hasData {
    return self.stickerLibrayModel.themeList.count > 0;
}

- (void)showLoadingView {
    if (!self.loadHudView) {
        self.loadHudView = [[WBProgressHUD alloc] initWithView:WBWindow];
        if (self.usingNewStyle) {
            self.loadHudView.HUDView.backgroundImageView.hidden = YES;
            self.loadHudView.HUDView.textLabel.alpha = 0.7;
        }
        self.loadHudView.text = loadMuLanguage(@"加载中", @"");
    }
    [self.loadHudView show:YES];
}

- (void)hideLoadingView {
    [self.loadHudView hide:YES];
}

- (void)updateWithNewStyle {
    self.view.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
}

- (void)showErrorView {
    self.errorView.alpha = 0.0;
    [self.view addSubview:self.errorView];
    [UIView animateWithDuration:0.1 delay:0.4 options:0 animations:^{
        self.errorView.alpha = 0.7;
    } completion:nil];
}

- (void)dismissErrorView {
    if (_errorView) {
        [self.errorView removeFromSuperview];
    }
}

- (void)showEmptyView {
    [self.view addSubview:self.emptyView];
}

- (void)setUsingNewStyle:(BOOL)usingNewStyle {
    if (_usingNewStyle != usingNewStyle) {
        _usingNewStyle = usingNewStyle;
        self.payButton.layer.cornerRadius = _usingNewStyle ? 13 : 2;
        self.payButton.wbtHeight = _usingNewStyle ? 26 : 28;
        self.payHintLabel.textColor = _usingNewStyle ? [UIColor whiteColor] : [UIColor wbt_ColorWithHexString:@"#333333"];
        if (_usingNewStyle) {
            [self.collectionView registerClass:[WBStickerLibraryStickerNewStyleCell class] forCellWithReuseIdentifier:KWBStickerLibraryCellReuseIdentifier];
        }
    }
}

- (void)dismissEmptyView {
    if (_emptyView) {
        [self.emptyView removeFromSuperview];
    }
}

- (WBTableViewEmptyView *)emptyView {
    if (!_emptyView) {
        _emptyView = [[WBTableViewEmptyView alloc] initWithFrame:CGRectMake(0, 0, self.view.wbtWidth, self.view.wbtHeight)];
        _emptyView.style = WBEmptyViewStyleDefault;
        _emptyView.userInteractionEnabled = NO;
        [_emptyView showActionError:nil];
        _emptyView.imageView.image = [UIImage skinImageNamed:@"empty_default.png"];
        _emptyView.shouldShowActionButton = NO;
        _emptyView.shouldShowErrorButton = NO;
        _emptyView.titleLabel.text = loadMuLanguage(@"这里还没有内容", nil);
        if (self.usingNewStyle) {
            _emptyView.contentOffset = CGPointMake(0, 42);
            _emptyView.imageTextpadding += 12;
            _emptyView.imageView.image = [UIImage imageNamed:@"empty_sticker_alpha"];
            _emptyView.imageView.contentMode = UIViewContentModeCenter;
            _emptyView.titleLabel.font = [UIFont systemFontOfSize:16];
            _emptyView.titleLabel.textColor = [UIColor wbt_colorWithHexValue:0xbdbdbd alpha:0.7];
        }
    }

    return _emptyView;
}

- (WBTableViewEmptyView *)errorView {
    if (!_errorView) {
        _errorView = [[WBTableViewEmptyView alloc] initWithFrame:CGRectMake(0, 0, self.view.wbtWidth, self.view.wbtHeight)];
        _errorView.style = WBEmptyViewStyleDefault;
        _errorView.userInteractionEnabled = YES;
        __weak typeof(self)weakSelf = self;
        _errorView.actionHandleBlock = ^{
            [weakSelf tapReload:nil];
        };
        [_errorView showActionError:nil];
        _errorView.imageView.image = [UIImage skinImageNamed:@"empty_failed.png"];
        _errorView.actionButtonName = loadMuLanguage(@"重新加载", nil);
        [_errorView setShouldShowActionButton:YES];
        [_errorView setShouldShowError:YES];
        _errorView.titleLabel.text = loadMuLanguage(@"网络出错啦，请点击按钮重新加载(C9101)", nil);
        if (self.usingNewStyle) {
            _errorView.alpha = 0.7;
            _errorView.contentOffset = CGPointMake(0, 43);
            _errorView.imageTextpadding = -13;
            _errorView.imageView.image = [UIImage imageNamed:@"mediaeditor_failed_reload"];
            _errorView.imageView.contentMode = UIViewContentModeCenter;
            _errorView.titleLabel.text = loadMuLanguage(@"加载失败，点击重试", nil);
            _errorView.titleLabel.textColor = [UIColor whiteColor];
            [_errorView.actionButton setTitle:@"" forState:UIControlStateNormal];
            _errorView.actionButton.hidden = YES;
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = _errorView.frame;
            [button addTarget:self action:@selector(tapReload:) forControlEvents:UIControlEventTouchUpInside];
            [_errorView addSubview:button];
        }
    }

    return _errorView;
}

- (void)tapReload:(id)sender {
    [self.errorView removeFromSuperview];
    [self refresh:WBSegmentChannelViewControllerRefreshTypeForced];
}

#pragma mark cache
- (BOOL)hasCache {
    NSString *cachePath = [self cachePathForStickerCategory:self.categotyId];

    if (!cachePath) {
        return NO;
    }

    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
}

- (WBStickerLibrayModel *)stickerLibraryModelFromCache {
    NSString *cachePath = [self cachePathForStickerCategory:self.categotyId];
    NSData *data = [NSData dataWithContentsOfFile:cachePath];
    WBStickerLibrayModel *model = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    return model;
}

- (BOOL)storeToCache:(WBStickerLibrayModel *)stickerLibrayModel {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:stickerLibrayModel];

    NSString *cachePath = [self cachePathForStickerCategory:self.categotyId];

    if (cachePath) {
        if ([data writeToFile:cachePath atomically:YES]) {
            return YES;
        }
    }

    return NO;
}

- (NSString *)cachePathForStickerCategory:(NSString *)categoryId {
    NSString *stickerLibraryCacheDirectory = [self stickerLibraryCacheDirectory];

    if ([self createDirectoryIfNonExistent:stickerLibraryCacheDirectory]) {
        return [stickerLibraryCacheDirectory stringByAppendingPathComponent:categoryId];
    }

    return nil;
}

- (NSString *)stickerLibraryCacheDirectory {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                              NSUserDomainMask, YES);
    NSString *cacheDirectory = [cachePaths objectAtIndex:0];

    return [cacheDirectory stringByAppendingPathComponent:@"stickerLibrary"];
}

- (BOOL)createDirectoryIfNonExistent:(NSString *)directory {
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:directory isDirectory:&isDir]) {
        if (![fileManager createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:NULL]) {
            WLog(@"Error: Create folder failed %@", directory);

            return NO;
        }
    }

    return YES;
}

#pragma mark Notification
// 接收支付成功的通知：收起续费提示
- (void)vipStickerMinipayFinishedNotification:(NSNotification *)notification {
    [self hideRenewAnimation:NO];
}

// 接收IAP支付成功的通知：收起续费提示
- (void)vipStickerIAPpayFinished:(NSNotification *)notification {
    [self hideRenewAnimation:NO];
}

- (void)vipStickerIAPpayFailed:(NSNotification *)notification {
    // 以此判断是不是 『订单正在处理中，成功后将会发送通知到微博消息箱，请注意查收』这个错误提示 (实际上这种情况应该是充值成功，但是订单还在处理未返回的失败逻辑，取消或者真正失败userInfo里通过ProcessResult字段返回
    if (notification.userInfo && [notification.userInfo objectForKey:@"Message"]) {
        [self hideRenewAnimation:NO];
    }
}

#pragma mark WBSegmentChannelModelProtocol
+ (instancetype)segmentViewControllerWithSegmentChannel:(id<WBSegmentChannelModelProtocol> )model baseViewController:(WBViewController *)baseVC userInfo:(NSDictionary *)userInfo {
    WBStickerLibraryTypeDetailViewController *detailViewController = [[WBStickerLibraryTypeDetailViewController alloc] init];

    detailViewController.categotyId = model.containerId;
    detailViewController.isVipCategory = model.defaultAdd;
    if ([baseVC isKindOfClass:[WBStickerLibraryViewController class]]) {
        detailViewController.baseViewController = baseVC;
        detailViewController.delegate = baseVC;
    }

    return detailViewController;
}

- (BOOL)refresh:(WBSegmentChannelViewControllerRefreshType)type {
    if (type != WBSegmentChannelViewControllerRefreshTypeForced) {// 自动刷新的情况下
        if (!self.isFromCache) {// 只要不是本地缓存 是服务器返回数据就不刷新了（不管网络失败了还是数据为空）
            return NO;
        }
        if ([self hasCache]) {// 没有数据，有缓存先加载缓存
            [self updateWithStickerModel:[self stickerLibraryModelFromCache] isFromCache:YES];
        } else {
            [self showLoadingView];
        }
    } else {// 强制刷新（失败后点击重新加载）
        [self showLoadingView];
    }

    __typeof(self) __weak weakSelf = self;

    void (^ errorBlock)(NSError *) = ^(NSError *error){
        weakSelf.isFromCache = NO;
        if (![weakSelf hasData]) {
            if ([[WBTDReachability sharedReachability] currentReachabilityStatus] == WBTDNotReachable) { // 根据UI要求，断网的话，延迟显示“重新加载”
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf hideLoadingView];
                    [weakSelf showErrorView];// 重试按钮
                });
            } else {
                [weakSelf hideLoadingView];
                [weakSelf showErrorView];// 重试按钮
            }
        } else {
            //有缓存然后加载失败的提示？
        }
    };

    void (^ successBlock)(WBStickerLibrayModel *) = ^(WBStickerLibrayModel *stickerLibray){
        [weakSelf hideLoadingView];
        [weakSelf dismissErrorView];
        [weakSelf updateWithStickerModel:stickerLibray isFromCache:NO];
        if (![weakSelf hasData]) {
            [weakSelf showEmptyView];
        }
    };
    // 测试接口    /2/photos/sticker_library/get_theme_stickers.json
    [self dismissEmptyView];
    [self dismissErrorView];
    NSString *apiPath = nil;
    BOOL enable = [WBABTestSDK isFeatureEnabled:@"feature_photos_testapi_debug_enable" withPolicy:WBABTestFeatureSyncWithServerPolicy];
    if (enable) {
        apiPath = @"http://api.test.photo.weibo.com/2/photos/sticker_library/get_theme_stickers.json";
    } else {
        apiPath = @"sdk/Thumbtack_Sticker_List";
    }
    [[WBNetworkClient sharedClient] getPath:apiPath
                                 parameters:@{ @"cat_id": self.categotyId }
                            completionBlock:^(SNHTTPRequestOperationWrapper *operationWrapper, id responseObject, NSError *error) {
                                if (error) {
                                    errorBlock(error);

                                    return;
                                }
                                NSDictionary *dict = responseObject;
                                NSInteger rsp = 0;
                                if (dict) {
                                    rsp = [dict wbt_integerForKey:@"rsp"];
                                } else {
                                    errorBlock(nil);

                                    return;
                                }
                                if (rsp == 1) {
                                    NSDictionary *data = [dict wbt_dictForKey:@"data"];
                                    WBStickerLibrayModel *dataModel = [[WBStickerLibrayModel alloc] initWithDictionary:data];
                                    successBlock(dataModel);
                                } else {
                                    errorBlock(nil);
                                }
                            }];

    return YES;
}

- (WBSegmentChannelViewControllerAnalysisOwnerOption)analysisOwnerOption {
    return WBSegmentChannelViewControllerAnalysisOwnerOptionNone;
}

#pragma mark - UICollectionView DataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section < self.stickerLibrayModel.themeList.count) {
        NSInteger itemsInSection = [self columPerRow] * CollectionViewRowsPerSection;
        WBStickerThemeModel *theme = [self.stickerLibrayModel.themeList objectAtIndex:section];
        if (theme.isShowAll) {
            return theme.stickersList.count + 1;// 加一个收起
        } else {
            return MIN(theme.stickersList.count, itemsInSection);
        }
    }

    return 0;
}

- (UICollectionViewCell *)getStickersCellOfTheme:(WBStickerThemeModel *)theme withIndexPath:(NSIndexPath *)indexPath {
    WBStickerLibraryStickerCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:KWBStickerLibraryCellReuseIdentifier forIndexPath:indexPath];
    WBStickerModel *sticker = [theme.stickersList objectAtIndex:indexPath.item];
    //    cell.stickerId = sticker.filterID;

    NSInteger tag = cell.tag + 1;

    cell.tag = tag;

    if (sticker.owner == WBStickerOwnerMembership && !self.usingNewStyle) {
        cell.signImageView.hidden = NO;
        cell.cornerType = WBStickerLibraryCellCornerTypeMembership;
        [cell setNeedsLayout];
    } else {
        if (sticker.showCornerIcon) {
            cell.signImageView.hidden = NO;
            if (sticker.type == WBStickerTypeApp) {
                cell.cornerType = WBStickerLibraryCellCornerTypeWBCamera;
            } else if (sticker.type == WBStickerTypeGIF) {
                cell.cornerType = WBStickerLibraryCellCornerTypeGif;
            } else {
                cell.cornerType = WBStickerLibraryCellCornerTypeDefault;
                [cell.signImageView setImageWithURL:sticker.showSignUrl placeholderImage:nil complete:^(UIImageView *imageView, UIImage *image, BOOL fromCache) {
                    if (cell.tag == tag) {
                        imageView.image = image;
                    }
                }];
            }
            [cell setNeedsLayout];
        } else {
            cell.signImageView.hidden = YES;
        }
    }
    //    [cell.stickerImageView setImageWithURL:sticker.squareIconURL];//直接使用这个会出现重用的问题 切记不能用
    __weak typeof(WBStickerLibraryStickerCell *)weakCell = cell;
    [cell.stickerImageView setImageWithURL:sticker.squareIconURL placeholderImage:nil complete:^(UIImageView *imageView, UIImage *image, BOOL fromCache) {
        if (weakCell.tag == tag) {
            imageView.image = image;

            if ([weakCell isKindOfClass:[WBStickerLibraryStickerNewStyleCell class]] && self.usingNewStyle) {
                [(WBStickerLibraryStickerNewStyleCell *) weakCell removeBackgroundPlaceholder];
            }
        }
    }];

    return cell;
}

- (UICollectionViewCell *)getMoreCellOfType:(WBStickerMoreCellType)type withIndexPath:(NSIndexPath *)indexPath {
    WBStickerLibraryStickerMoreCell *moreCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:KWBStickerLibraryMoreCellReuseIdentifier forIndexPath:indexPath];

    moreCell.type = type;
    if (self.usingNewStyle) {
        [moreCell updateWithNewStyle];
    }

    return moreCell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WBStickerThemeModel *theme = [self.stickerLibrayModel.themeList objectAtIndex:indexPath.section];

    if (theme.isShowAll) {
        if (indexPath.item == theme.stickersList.count) {
            return [self getMoreCellOfType:WBStickerMoreCellTypeClose withIndexPath:indexPath];
        } else {
            return [self getStickersCellOfTheme:theme withIndexPath:indexPath];
        }
    } else {
        NSInteger itemsInSection = [self columPerRow] * CollectionViewRowsPerSection;
        if (theme.stickersList.count > itemsInSection && indexPath.item == itemsInSection - 1) {
            return [self getMoreCellOfType:WBStickerMoreCellTypeOpen withIndexPath:indexPath];
        } else {
            return [self getStickersCellOfTheme:theme withIndexPath:indexPath];
        }
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.stickerLibrayModel.themeList.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    WBStickerLibraryTypeDetailHeaderView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:KWBStickerLibraryHeadReuseIdentifier forIndexPath:indexPath];
    WBStickerThemeModel *theme = [self.stickerLibrayModel.themeList objectAtIndex:indexPath.section];
    NSInteger lanSet = [[NSUserDefaults standardUserDefaults] integerForKey:@"MulanguageSet"];
    NSString *name = theme.name;

    switch (lanSet) {
        case 0:// 简体中文
            name = theme.name;
            break;

        case 1:// 繁体中文
            name = theme.nameTaiwan;
            break;

        case 2:// 英文
            name = theme.nameEnglish;
            break;
    }
    if (NSStringIsNullOrEmpty(name)) {
        name = theme.name;
    }
    [headView setThemeName:name andStickerCount:theme.stickersNum];
    if (self.usingNewStyle) {
        NSString *imageName;
        if (self.isVipCategory) {
            imageName = @"sticker_library_member_tag";
        }
        [headView updateWithNewStyleWithTagImageName:imageName];
    }

    return headView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellSize;
}

#pragma mark - UICollectionView Delegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WBStickerThemeModel *theme = [self.stickerLibrayModel.themeList objectAtIndex:indexPath.section];

    __weak typeof(self)weakSelf = self;
    void (^ stickerSelectBlock)() = ^(){
        WBStickerModel *sticker = [theme.stickersList objectAtIndex:indexPath.item];
        /**1.带随手拍标识的贴纸
         未安装客户端 弹下载提示框 ;
         已安装  回到编辑页面 跳转随手拍
         2.静态贴纸 （天气贴纸也走这？）
         回到编辑页面，带上所选贴纸id
         3.gif贴纸
         已下载：带上回到编辑页应用
         未下载：开始下载
         正在下载：不处理
         */
        // ****以上是770及以前  771改为不在贴纸库页面下载，跳转到编辑页再下载 点击只判断是不是会员贴纸  未下载区分网络情况
        if (sticker.type == WBStickerTypeApp) {
            WBAppStickerModel *appStickerModel = (WBAppStickerModel *)sticker;
            // 安装了随手拍
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appStickerModel.appScheme]]) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(stickerLibraryTypeDetailViewController:sticker:)]) {
                    [weakSelf.delegate stickerLibraryTypeDetailViewController:weakSelf sticker:appStickerModel];
                }
            } else {
                [WBPlusConfigEngine showWeiboCameraAlertViewWithBackgroundImage:nil withScheme:appStickerModel.appScheme andUrl:appStickerModel.appleUrl andAnalysisParameters:[self analysisParameters] baseViewController:self clickOpenCameraButtonCallback:nil];
            }
        } else {
            if (sticker.owner == WBStickerOwnerMembership) {// 会员贴纸
                if (![[WBAccountManager currentAccount].user isValidMemberShip]) {//不是会员
                    // 弹框续费会员
                    [weakSelf showBecomeVIPTips];

                    return;
                }
            }
            // 非会员贴纸  或者 会员贴纸并且是会员
            if ([[WBTDReachability sharedReachability] currentReachabilityStatus] == WBTDNotReachable && ![sticker isDownload]) {// 未下载贴纸，当前断网
                [WBProgressHUD showWarningWithText:loadMuLanguage(@"联网后才可以使用贴纸哦", nil) duration:1.5f];
            } else {
                [[WBFilterStickerMarket sharedMarket] cleanDownloadedStickerIfNeeded:sticker];
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(stickerLibraryTypeDetailViewController:sticker:)]) {
                    [weakSelf.delegate stickerLibraryTypeDetailViewController:weakSelf sticker:sticker];
                }
            }
        }
    };
    if (theme.isShowAll) {
        if (indexPath.item < theme.stickersList.count) {
            stickerSelectBlock();//选择贴纸
        } else if (indexPath.item == theme.stickersList.count) {
            theme.isShowAll = !theme.isShowAll;
            [self reloadSectionData:indexPath];
            //            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
        }
    } else {
        NSInteger itemsInSection = [self columPerRow] * CollectionViewRowsPerSection;
        if (theme.stickersList.count > itemsInSection && indexPath.item == itemsInSection - 1) {
            theme.isShowAll = !theme.isShowAll;
            [self reloadSectionData:indexPath];
            //            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
        } else if (indexPath.item < theme.stickersList.count) {
            stickerSelectBlock();//选择贴纸
        }
    }
}

- (void)reloadSectionData:(NSIndexPath *)indexPath {
    [UIView animateWithDuration:0 animations:^{
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
            [self.collectionView layoutIfNeeded];
        } completion:nil];
    }];
    //    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
}

@end
