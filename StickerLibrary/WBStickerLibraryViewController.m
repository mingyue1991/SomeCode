//
//  WBStickerLibraryViewController.m
//  WBPhotosFramework
//
//  Created by swit on 17/5/10.
//  Copyright © 2017年 weibo. All rights reserved.
//

#import "WBStickerLibraryViewController.h"
#import "WBStickerLibrayModel.h"
#import "WBStickerLibrarySearchViewController.h"
#import "WBABTestSDK.h"
#import "WBImageEditViewController.h"
#import "WBSegmentChannelsBarView.h"
#import "WBNavigationTitleView.h"
#import "UIBarButtonItem+Helper.h"
#import "UINavigationBar+Background.h"
#import "WBStickerLibraryNavigationBar.h"
#import "WBPhotoEditorViewController.h"
#import "Masonry.h"
#import "WBBaseSegmentViewWrapper.h"
#import "WBSegmentBaseModel.h"
#import "WBProgressHUD.h"
#import "WBTDReachability.h"

#define TitleFontSize WBScaleWithOptions(14, { .iphone6 = 14, .iphone6p = 15, .ipad = 18 })

@interface WBStickerSegmentChannelsBarView : WBSegmentChannelsBarView

@property (nonatomic, assign) BOOL usingNewStyle;
@property (nonatomic, strong) UIView *originalSlider;
@property (nonatomic, strong) UIImageView *originalBottomLine;

- (void)makeNewStyle;

@end

@implementation WBStickerSegmentChannelsBarView

- (UIView *)originalSlider {
    if (!_originalSlider) {
        if ([self respondsToSelector:@selector(slider)]) {
            _originalSlider = [self valueForKey:@"slider"];
        }
    }

    return _originalSlider;
}

- (UIImageView *)originalBottomLine {
    if (!_originalBottomLine) {
        if ([self respondsToSelector:@selector(lineShadow)]) {
            UIImageView *bottomLine = [self valueForKey:@"lineShadow"];
            if ([bottomLine isKindOfClass:[UIImageView class]]) {
                _originalBottomLine = bottomLine;
            }
        }
    }

    return _originalBottomLine;
}

- (CGFloat)barItemTitleFontSize {
    return TitleFontSize;
}

- (void)makeNewStyle {
    self.usingNewStyle = YES;

    // 修改Slider的颜色
    if ([self respondsToSelector:@selector(sliderColorArray)]) {
        NSArray *newSliderColorArray = @[@"FFFFFF", @"FFFFFF"];
        [self setValue:newSliderColorArray forKey:@"sliderColorArray"];
    }

    // 修改背景色
    if ([self respondsToSelector:@selector(backgroundView)]) {
        UIImageView *backgroundView = [self valueForKey:@"backgroundView"];
        if ([backgroundView isKindOfClass:[UIImageView class]]) {
            backgroundView.image = nil;
        }
    }

    // 隐藏阴影
    if ([self respondsToSelector:@selector(barButtonsShasowLeft)]) {
        UIImageView *shadowView = [self valueForKey:@"barButtonsShasowLeft"];
        if ([shadowView isKindOfClass:[UIImageView class]]) {
            shadowView.image = nil;
        }
    }

    // 底部线条颜色
    self.originalBottomLine.image = nil;
    self.originalBottomLine.wbtHeight = 1 / [UIScreen mainScreen].scale;
    self.originalBottomLine.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    self.originalBottomLine.alpha = 0.25;
}

- (void)setChannelModels:(NSArray *)channelModels defaultIndex:(NSUInteger)defaultIndex {
    [super setChannelModels:channelModels defaultIndex:defaultIndex];
    if (self.usingNewStyle) {
        // 修改button字体等
        for (UIButton *button in self.channelButtons) {
            UIFont *normalFont = [UIFont systemFontOfSize:14];
            if ([UIDevice currentDevice].systemVersion.doubleValue >= 9.0) {
                normalFont = [UIFont fontWithName:@"PingFangSC-Regular" size:14] ? : [UIFont systemFontOfSize:14];
            }
            NSDictionary *normalAttrDic = @{ NSFontAttributeName: normalFont, NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.5] };
            UIFont *selectedFont = [UIFont systemFontOfSize:14];
            if ([UIDevice currentDevice].systemVersion.doubleValue >= 9.0) {
                selectedFont = [UIFont fontWithName:@"PingFangSC-Medium" size:14] ? : [UIFont systemFontOfSize:14];
            }
            NSDictionary *selectedAttrDic = @{ NSFontAttributeName: selectedFont, NSForegroundColorAttributeName: [UIColor whiteColor] };
            NSAttributedString *normalStr = [[NSAttributedString alloc] initWithString:button.titleLabel.text attributes:normalAttrDic];
            NSAttributedString *selectedStr = [[NSAttributedString alloc] initWithString:button.titleLabel.text attributes:selectedAttrDic];
            [button setAttributedTitle:normalStr forState:UIControlStateNormal];
            [button setAttributedTitle:selectedStr forState:UIControlStateSelected];
        }
    }
}

@end

#define SegementBarHeight WBScaleWithOptions(44, { .iphone6 = 44, .iphone6p = 47, .ipad = 55 })

@interface WBStickerLibraySegmentViewWrapper : WBBaseSegmentViewWrapper

- (instancetype)initWithViewController:(WBViewController *)vc
                      isFullScreenMode:(BOOL)isFullScreenMode
                         usingNewStyle:(BOOL)usingNewStyle;

@property (nonatomic, assign) BOOL usingNewStyle;

- (void)addMemberTagWithIndex:(NSUInteger)index;

@end

@implementation WBStickerLibraySegmentViewWrapper

- (instancetype)initWithViewController:(id)vc isFullScreenMode:(BOOL)isFullScreenMode usingNewStyle:(BOOL)usingNewStyle {
    if ([super initWithViewController:vc isFullScreenMode:isFullScreenMode]) {
        self.usingNewStyle = usingNewStyle;
        if (self.usingNewStyle) {
            [(WBStickerSegmentChannelsBarView *) self.segmentChannelBar makeNewStyle];
        }
    }

    return self;
}

- (Class)viewControllerClass {
    return NSClassFromString(@"WBStickerLibraryTypeDetailViewController");
}

- (Class)segmentBarClass {
    return NSClassFromString(@"WBStickerSegmentChannelsBarView");
}

- (void)configSubviewsFrame:(CGRect)frame {
    CGFloat realNavHeight = WBDefaultTableViewBaseInsetTop;

    if (self.channelModels) {
        self.segmentChannelBar.frame = CGRectMake(0, frame.origin.y, WBKeyWindowRealWidth, SegementBarHeight);
    } else {
        self.segmentChannelBar.frame = CGRectMake(0, frame.origin.y, 0, 0);
    }

    self.segmentSwipeView.suppressScrollEvent = YES;
    self.segmentSwipeView.frame = CGRectMake(0, CGRectGetMaxY(self.segmentChannelBar.frame) - realNavHeight, WBKeyWindowRealWidth, frame.size.height - self.segmentChannelBar.wbtHeight + realNavHeight);
    self.segmentSwipeView.suppressScrollEvent = NO;

    self.segmentSwipeView.wbtTop = self.segmentChannelBar.wbtBottom;
    self.segmentSwipeView.wbtWidth = frame.size.width;
    self.segmentSwipeView.wbtHeight = frame.size.height - self.segmentChannelBar.wbtHeight;// WBKeyWindowRealHeight - WBDefaultTableViewBaseInsetTop - self.segmentChannelBar.wbtHeight;
}

- (void)configSegmentViewController:(SegmentViewController *)segmentViewController atIndex:(NSInteger)index {
    [super configSegmentViewController:segmentViewController atIndex:index];
    WBStickerLibraryTypeDetailViewController *detailViewController = ((WBStickerLibraryTypeDetailViewController *)segmentViewController);
    detailViewController.collectionView.frame = segmentViewController.view.bounds;

    if (self.usingNewStyle) {
        detailViewController.usingNewStyle = YES;
        [detailViewController updateWithNewStyle];
    }
}

- (void)addMemberTagWithIndex:(NSUInteger)index {
    if (index < self.segmentChannelBar.channelButtons.count) {
        UIButton *button = self.segmentChannelBar.channelButtons[index];
        UIImage *normalImage = [UIImage imageNamed:@"sticker_library_bar_tag_member"];
        CGRect rect = button.frame;
        CGFloat originalWidth = rect.size.width;
        rect.size.width += (normalImage.size.width + 5);
        button.frame = rect;
        button.titleEdgeInsets = UIEdgeInsetsMake(0, -(normalImage.size.width * 2), 0, 0);
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -((originalWidth + 3) * 2));
        [button setImage:normalImage forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"sticker_library_bar_tag_member_highlighted"] forState:UIControlStateSelected];
    }
}

@end

@interface WBStickerLibraryViewController ()<WBBaseSegmentViewWrapperDelegate, WBStickerLibrarySearchDelegate>

@property (nonatomic, assign) BOOL usingNewStyle;

@property (nonatomic, strong) WBStickerLibraySegmentViewWrapper *wrapper;
@property (nonatomic, strong) WBSegmentBaseModel *baseModel;
@property (nonatomic, strong) WBProgressHUD *loadHudView;
@property (nonatomic, strong) WBTableViewEmptyView *errorView;
@property (nonatomic, strong) WBTableViewEmptyView *emptyView;
@property (nonatomic, strong) UIView *blurBackgourndView;
@property (nonatomic, strong) UIImageView *backgourndImageView;
@property (nonatomic, assign) UIStatusBarStyle preStatusBarStyle;
@end

@implementation WBStickerLibraryViewController

#pragma mark - Life Circle

- (id)init {
    if (self = [super init]) {
        self.uiCode = @"10000577";
    }

    return self;
}

- (instancetype)initWithNewStyle {
    if (self = [self init]) {
        self.usingNewStyle = YES;
    }

    return self;
}

- (void)dealloc {
    WLog(@"WBStickerLibraryViewController dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = loadMuLanguage(@"贴纸库", nil);
    if (self.usingNewStyle) {
        self.preStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
        [self makeBlurImageBackground];
        [self.view addSubview:self.blurBackgourndView];
        [self makeCustomNavigationBar];
    }
    [self wrapper];
    [self loadChannelData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.usingNewStyle) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 44, 44);
        button.contentEdgeInsets = UIEdgeInsetsMake(0, -29, 0, 0);
        button.wbtHitTestInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        [button setImage:[UIImage imageNamed:@"sticker_navigationbar_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    } else {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem itemWithTitle:loadMuLanguage(@"取消", nil) style:WBUIBarButtonItemStyleDefault target:self action:@selector(cancelAction)];
    }

    // ABTest开关，用来开启和关闭贴纸搜索功能
    BOOL enable = [WBABTestSDK isFeatureEnabled:@"feature_photos_sticker_search_enable" withPolicy:WBABTestFeatureSyncWithServerPolicy];

    /**
     * 如果开启了贴纸搜索
     */
    if (enable) {
        UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [searchBtn setImage:[UIImage skinImageNamed:self.usingNewStyle ? @"userinfo_tabicon_search_white" : @"userinfo_tabicon_search"] forState:UIControlStateNormal];
        searchBtn.frame = CGRectMake(0, 0, 30, 30);
        if (self.usingNewStyle) {
            searchBtn.contentEdgeInsets = UIEdgeInsetsMake(-1, 0, 0, -17.5);
        }
        searchBtn.wbtHitTestInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
        UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:searchBtn];
        [searchBtn addTarget:self action:@selector(openSearchPageAction) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setRightBarButtonItem:rightBtnItem];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.usingNewStyle) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([[UIDevice currentDevice] wbt_isIPad]) {
        self.errorView.frame = CGRectMake(0, 0, self.view.wbtWidth, self.view.wbtHeight);
        self.emptyView.frame = CGRectMake(0, 0, self.view.wbtWidth, self.view.wbtHeight);
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.wrapper configSubviewsFrame:CGRectMake(0, WBDefaultTableViewBaseInsetTop, WBKeyWindowRealWidth, WBKeyWindowRealHeight - WBDefaultTableViewBaseInsetTop)];
}

#pragma mark - Methods
- (void)makeBlurImageBackground {
    self.backgourndImageView = [[UIImageView alloc] initWithFrame:self.blurBackgourndView.bounds];
    self.backgourndImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgourndImageView.image = self.backgroundImage;
    [self.blurBackgourndView addSubview:self.backgourndImageView];

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurMaskView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurMaskView.frame = self.blurBackgourndView.bounds;
    [self.blurBackgourndView addSubview:blurMaskView];
}

- (void)makeCustomNavigationBar {
    WBStickerLibraryNavigationBar *navBar = [WBStickerLibraryNavigationBar new];

    if ([self.navigationController respondsToSelector:@selector(navigationBar)]) {
        [self.navigationController setValue:navBar forKey:@"navigationBar"];
    }

    if ([self.navigationItem.titleView isKindOfClass:[WBNavigationTitleView class]]) {
        WBNavigationTitleView *titleView = (WBNavigationTitleView *)self.navigationItem.titleView;
        titleView.titleLabel.wbtTop += 1;
        [titleView setTitleLabelTextColor:[UIColor whiteColor]];
    }
}

- (void)loadChannelData {
    __typeof(self) __weak weakSelf = self;

    void (^ errorBlock)(NSError *) = ^(NSError *error){
        if ([weakSelf hasCache]) {
            [weakSelf hideLoadingView];
            [weakSelf updateChannelModelsWith:[weakSelf stickerLibraryModelFromCache]];
        } else {
            if ([[WBTDReachability sharedReachability] currentReachabilityStatus] == WBTDNotReachable) { // 根据UI要求，断网的话，延迟显示“重新加载”
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf hideLoadingView];
                    [weakSelf showErrorView];// 重试按钮
                });
            } else {
                [weakSelf hideLoadingView];
                [weakSelf showErrorView];// 重试按钮
            }
        }
    };

    void (^ successBlock)(WBStickerLibrayModel *) = ^(WBStickerLibrayModel *stickerLibray){
        [weakSelf hideLoadingView];
        [weakSelf dismissErrorView];
        [weakSelf updateChannelModelsWith:stickerLibray];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf storeToCache:stickerLibray];
        });
    };

    NSString *apiPath = nil;
    BOOL enable = [WBABTestSDK isFeatureEnabled:@"feature_photos_testapi_debug_enable" withPolicy:WBABTestFeatureSyncWithServerPolicy];
    if (enable) {
        apiPath = @"http://api.test.photo.weibo.com/2/photos/sticker_library/get_theme_stickers.json";
    } else {
        apiPath = @"sdk/Thumbtack_Sticker_List";
    }
    // 测试接口    /2/photos/sticker_library/get_theme_stickers.json
    [self dismissEmptyView];
    [self dismissErrorView];
    [self showLoadingView];
    [[WBNetworkClient sharedClient] getPath:apiPath
                                 parameters:@{ @"cat_only": @"1" }
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
}

- (void)openSearchPageAction {
    [[WBAnalysisManager sharedManager] logWithCode:@"2110" andExtraParameters:nil];
    WBStickerLibrarySearchViewController *searchPage;
    if (self.usingNewStyle) {
        searchPage = [[WBStickerLibrarySearchViewController alloc] initWithNewStyleBackgroundImage:self.backgroundImage];
    } else {
        searchPage = [[WBStickerLibrarySearchViewController alloc] init];
    }
    searchPage.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:searchPage];
    [self presentViewController:nav animated:YES];
}

- (void)updateChannelModelsWith:(WBStickerLibrayModel *)stickerLibray {
    [self configBaseModelWith:stickerLibray];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:schemeParaDict];
    NSString *selectedID = [((WBSegmentChannelModel *)[self.baseModel.channelList firstObject]) containerId];
    [userInfo wbt_setObject:selectedID forKey:kUserInfoKeySelectedID];
    [self.wrapper configSubviewsFrame:CGRectMake(0, WBDefaultTableViewBaseInsetTop, WBKeyWindowRealWidth, WBKeyWindowRealHeight - WBDefaultTableViewBaseInsetTop)];
    [self.wrapper updateChannelModels:self.baseModel.channelList userInfo:userInfo];
}

- (void)configBaseModelWith:(WBStickerLibrayModel *)stickerLibray {
    NSString *categoryName = nil;
    BOOL isVipCat = NO;// 是否是会员分类
    NSInteger lanSet = [[NSUserDefaults standardUserDefaults] integerForKey:@"MulanguageSet"];

    NSMutableArray *channelList = [[NSMutableArray alloc] init];

    for (WBStickerCategoryModel *category in stickerLibray.categoryList) {
        switch (lanSet) {
            case 0:// 简体中文
                categoryName = category.categoryName;
                break;

            case 1:// 繁体中文
                categoryName = category.categoryNameTaiwan;
                break;

            case 2:// 英文
                categoryName = category.categoryNameEnglish;
                break;
        }
        isVipCat = [category.type isEqualToString:@"M"];
        [channelList addObject:@{ @"containerid": category.categoryId, @"name": categoryName, @"default_add": @(isVipCat) }];
    }
    self.baseModel = [WBSegmentBaseModel objectWithDictionary:@{ @"channel_list": channelList }];
}

- (void)showLoadingView {
    if (!self.loadHudView) {
        self.loadHudView = [[WBProgressHUD alloc] initWithView:self.view];
        if (self.usingNewStyle) {
            self.loadHudView.HUDView.backgroundImageView.hidden = YES;
            self.loadHudView.HUDView.textLabel.alpha = 0.7;
        }
        self.loadHudView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.loadHudView.text = loadMuLanguage(@"加载中", @"");
    }
    [self.loadHudView show:YES];
}

- (void)hideLoadingView {
    [self.loadHudView hide:YES];
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

- (void)dismissEmptyView {
    if (_emptyView) {
        [self.emptyView removeFromSuperview];
    }
}

#pragma mark - Getter & Setter

- (WBStickerLibraySegmentViewWrapper *)wrapper {
    if (!_wrapper) {
        _wrapper = [[WBStickerLibraySegmentViewWrapper alloc] initWithViewController:self isFullScreenMode:NO usingNewStyle:self.usingNewStyle];
        _wrapper.delegate = self;
    }

    return _wrapper;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    CGImageRef newCgImage = CGImageCreateCopy(backgroundImage.CGImage);

    _backgroundImage = [UIImage imageWithCGImage:newCgImage
                                           scale:backgroundImage.scale
                                     orientation:backgroundImage.imageOrientation];
    self.backgourndImageView.image = _backgroundImage;
}

- (UIView *)blurBackgourndView {
    if (!_blurBackgourndView) {
        _blurBackgourndView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _blurBackgourndView.backgroundColor = [UIColor blackColor];
        _blurBackgourndView.autoresizesSubviews = NO;
    }

    return _blurBackgourndView;
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
            _errorView.contentOffset = CGPointMake(0, 96);
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

#pragma mark - Actions

- (void)tapReload:(id)sender {
    [self.errorView removeFromSuperview];
    [self loadChannelData];
}

- (void)cancelAction {
    [self dismissSelfWithAnimation:YES];
}

- (void)dismissSelfWithAnimation:(BOOL)isAnimation {
    [UIApplication sharedApplication].statusBarStyle = self.preStatusBarStyle;
    [super dismissSelfWithAnimation:isAnimation];
}

#pragma mark - cache
- (BOOL)hasCache {
    NSString *cachePath = [self cachePathForStickerCategoryList];

    if (!cachePath) {
        return NO;
    }

    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
}

- (WBStickerLibrayModel *)stickerLibraryModelFromCache {
    NSString *cachePath = [self cachePathForStickerCategoryList];
    NSData *data = [NSData dataWithContentsOfFile:cachePath];
    WBStickerLibrayModel *model = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    return model;
}

- (BOOL)storeToCache:(WBStickerLibrayModel *)stickerLibrayModel {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:stickerLibrayModel];

    NSString *cachePath = [self cachePathForStickerCategoryList];

    if (cachePath) {
        if ([data writeToFile:cachePath atomically:YES]) {
            return YES;
        }
    }

    return NO;
}

- (NSString *)cachePathForStickerCategoryList {
    NSString *stickerLibraryCacheDirectory = [self stickerLibraryCacheDirectory];

    if ([self createDirectoryIfNonExistent:stickerLibraryCacheDirectory]) {
        return [stickerLibraryCacheDirectory stringByAppendingPathComponent:@"categoryList"];
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

#pragma mark - WBStickerLibrarySearchDelegate

- (void)stickerLibrarySearchResult:(NSString *)stickerID {
    UIViewController *vc = self;

    for (UIViewController *item in self.presentingViewController.childViewControllers) {
        if ([item isMemberOfClass:[WBImageEditViewController class]] || [item isMemberOfClass:[WBPhotoEditorViewController class]]) {
            vc = item;
            break;
        }
    }

    [vc dismissViewControllerAnimated:YES completion:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(stickerLibraryViewController:stickerID:)]) {
            [self.delegate stickerLibraryViewController:self stickerID:stickerID];
        }
    }];
}

#pragma mark - WBStickerLibraryViewControllerDelegate
- (void)stickerLibraryTypeDetailViewController:(WBStickerLibraryTypeDetailViewController *)stickerTypeView sticker:(WBStickerModel *)sticker {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(stickerLibraryViewController:sticker:)]) {
            [self.delegate stickerLibraryViewController:self sticker:sticker];
        }
    }];
}

- (void)stickerLibraryTypeDetailViewControllerDidShowVipHint:(WBStickerLibraryTypeDetailViewController *)stickerTypeView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerLibraryViewControllerDidShowVipHint:)]) {
        [self.delegate stickerLibraryViewControllerDidShowVipHint:self];
    }
}

#pragma mark - WBBaseSegmentViewWrapperDelegate
- (void)wrapperWillSelectChannelsBar:(WBSegmentChannelsBarView *)channelsView toIndex:(NSInteger)index {
    if (index < self.wrapper.segmentViewControllers.count) {
        WBStickerLibraryTypeDetailViewController *detailVC = (WBStickerLibraryTypeDetailViewController *)[self.wrapper.segmentViewControllers objectAtIndex:index];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.analysisParameters];
        [parameters wbt_setSafeObject:[NSString stringWithFormat:@"category:%@", detailVC.categotyId] forKey:@"oid"];
        [[WBAnalysisManager sharedManager] logWithCode:@"1922" andExtraParameters:parameters];
    }
}

@end
