//
//  WBActivityCameraViewController.m
//  BaseLibs
//
//  Created by swit on 2018/4/19.
//

#import "WBActivityCameraViewController.h"
#import "AVCamCaptureManager.h"
#import "WBPhotoEditorGradientView.h"
#import "UIBarButtonItem+Helper.h"
#import "UIView+WBTSizes.h"
#import "UIColor+WBTHelper.h"
#import "WBALAssetPickerContextManager.h"
#import "WBActivityPreviewViewController.h"
#import "WBActivityNavigationController.h"
// static const int currentScaleFactor = 1;
@interface WBActivityCapturePreviewView : UIView
@property (weak, nonatomic, readonly) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@end

@implementation WBActivityCapturePreviewView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        [self.captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }

    return self;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

@end

@interface WBActivityAlbumButton : UIButton
@property (nonatomic, assign) BOOL isDefault;
@end
@implementation WBActivityAlbumButton
- (void)setIsDefault:(BOOL)isDefault {
    _isDefault = isDefault;
    if (isDefault) {
        [self setImage:[UIImage imageNamed:@"icon_picture_default"] forState:UIControlStateNormal];
        self.layer.borderWidth = 0;
    } else {
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor wbt_ColorFromHexString:@"E6E6E6"].CGColor;
        self.layer.cornerRadius = 2;
        self.clipsToBounds = YES;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect responseRect = CGRectInset(self.bounds, -20, -20);

    return CGRectContainsPoint(responseRect, point);
}

@end
@interface WBActivityCameraViewController ()<AVCamCaptureManagerDelegate, WBALAssetPickerContextManagerDelegate, PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) AVCamCaptureManager *cameraManager;
@property (nonatomic, strong) WBALAssetPickerContextManager *pickerManager;
@property (nonatomic, assign) BOOL libraryRegistered;
@property (nonatomic, strong) WBPhotoEditorGradientView *topview;
@property (nonatomic, strong) WBActivityCapturePreviewView *preview;
@property (nonatomic, strong) UIImageView *focusImageView;
@property (nonatomic, strong) WBActivityAlbumButton *albumButton;
@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) UIButton *switchButton;
@end

@implementation WBActivityCameraViewController
#pragma mark - Life Cycle
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.uiCode = @"10000773";
        self.navigationItem.hideNavigationBar = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor wbt_ColorFromHexString:@"0f0f0f"];
    [self configSubViews];
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    [self showAlbumCover:YES];
                } else {
                    [self showAlbumCover:NO];
                }
            });
        }];
    } else if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [self showAlbumCover:YES];
    } else {
        [self showAlbumCover:NO];
    }
    [[WBAnalysisManager sharedManager] logWithCode:@"2589" andExtraParameters:self.analysisParameters];
}

- (void)viewWillAppear:(BOOL)animated {
    //    self.navigationController.navigationBar.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    [self resumeCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated  {
    //    self.navigationController.navigationBar.hidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [self pauseCaptureSession];
}

#pragma mark - manager
- (AVCamCaptureManager *)cameraManager {
    if (!_cameraManager) {
        self.cameraManager = ({
            AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
            manager.delegate = self;
            [manager setupSession:NO captureDevicePosition:AVCaptureDevicePositionFront];
            manager;
        });
    }

    return _cameraManager;
}

- (WBALAssetPickerContextManager *)pickerManager {
    if (!_pickerManager) {
        self.pickerManager = ({
            WBALAssetPickerContextManager *picker = [[WBALAssetPickerContextManager alloc] initWithViewController:self];
            picker.delegate = self;
            picker.showBannerNotice = YES;
            picker.isEditingEnabled = NO;
            picker.isCorpEnabled = NO;
            picker.maxAllowSelectCount = 1;
            picker.isHidenCameraButton = YES;
            picker.isGifAllowed = NO;
            picker.isLivePhotoAllowed = NO;
            picker.isPanoramaAllowed = NO;
            picker;
        });
    }

    return _pickerManager;
}

#pragma mark - Method
- (void)configSubViews {
    [self.view addSubview:self.preview];
    [self.view addSubview:self.topview];
    [self.view addSubview:self.captureButton];
    [self.view addSubview:self.albumButton];
    [self.view addSubview:self.switchButton];
}

- (void)showAlbumCover:(BOOL)isShow {
    if (isShow) {
        [self loadAssetsCompletion:^(UIImage *image) {
            if (image) {
                if (!self.libraryRegistered) {
                    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
                    self.libraryRegistered = YES;
                }
                self.albumButton.isDefault = NO;
                [self.albumButton setImage:image forState:UIControlStateNormal];
            } else {
                self.albumButton.isDefault = YES;
            }
        }];
    } else {
        self.albumButton.isDefault = YES;
    }
}

- (void)loadAssetsCompletion:(nonnull void (^)(UIImage *image))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHFetchResult *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsInAssetCollection:collections.firstObject options:nil];
        PHAsset *asset = result.lastObject;
        if (asset) {
            PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(100, 100) contentMode:PHImageContentModeAspectFill options:requestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(result);
                    });
                }
            }];
        } else {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil);
                });
            }
        }
    });
}

- (void)pauseCaptureSession {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cameraManager pauseCaptureSession];
        });
    });
}

- (void)resumeCaptureSession {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cameraManager resumeCaptureSession];
        });
    });
}

- (void)previewSelectedImageCache:(WBImageEditorCache *)imageCache {
    WBActivityPreviewViewController *vc = [[WBActivityPreviewViewController alloc] initWithImageEditorCache:imageCache];

    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - actions
- (void)backButtonClicked {
    if ([self.navigationController isKindOfClass:[WBActivityNavigationController class]]) {
        WBActivityNavigationController *navController = (WBActivityNavigationController *)self.navigationController;
        if ([navController.pickerDelegate respondsToSelector:@selector(WBActivityControllerPickFaceImageCanceled:)]) {
            [navController.pickerDelegate WBActivityControllerPickFaceImageCanceled:navController];

            return;
        }
    }
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)captureButtonPressed:(UIButton *)sender {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.analysisParameters];

    params[@"ext"] = @"button_val:2";
    [[WBAnalysisManager sharedManager] logWithCode:@"2587" andExtraParameters:params];
    self.captureButton.userInteractionEnabled = NO;
    WBSLIDESHOW_WEAKSELF
    [self.cameraManager getCurrentSampleImage:^(UIImage *image) {
        if (image) {
            WBImageEditorCache *imageCache = [[WBImageEditorCache alloc] init];
            NSDictionary *oriDict = [WBALAssetPickerContextManager writeImageToFile:image error:nil];
            imageCache.originalDict = oriDict;
            [weakSelf previewSelectedImageCache:imageCache];
        }
        self.captureButton.userInteractionEnabled = YES;
    }];
    //    [self.cameraManager captureImageWithScaleFactor: currentScaleFactor andOrientation:[AVCamCaptureManager deviceOrientationToVideoOrientation:UIDeviceOrientationPortrait] completionHandler:^(UIImage *image, NSError *error) {
    //        if (image) {
    //            WBImageEditorCache *imageCache = [[WBImageEditorCache alloc] init];
    //            NSDictionary *oriDict = [WBALAssetPickerContextManager writeImageToFile:image error:nil];
    //            imageCache.originalDict = oriDict;
    //            [weakSelf previewSelectedImageCache:imageCache];
    //        }
    //        self.captureButton.userInteractionEnabled = YES;
    //    }];
}

- (void)albumButtonPressed:(UIButton *)sender {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.analysisParameters];

    params[@"ext"] = @"button_val:3";
    [[WBAnalysisManager sharedManager] logWithCode:@"2587" andExtraParameters:params];
    [self.pickerManager pushAlbumPicker:YES];
}

- (void)switchButtonPressed:(UIButton *)sender {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.analysisParameters];

    params[@"ext"] = @"button_val:4";
    [[WBAnalysisManager sharedManager] logWithCode:@"2587" andExtraParameters:params];
    [self.cameraManager toggleCamera];
    [self.cameraManager continuousFocusAtPoint:CGPointMake(.5, .5)];
}

- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint tapPoint = [gestureRecognizer locationInView:self.preview];
    CGPoint focusPoint = [AVCamCaptureManager convertToPointOfInterestFromViewCoordinates:tapPoint view:self.preview AVCaptureDeviceInput:self.cameraManager.videoInput AVCaptureVideoPreviewLayer:self.preview.captureVideoPreviewLayer preViewScale:1];

    [self.cameraManager continuousFocusAndExposureAtPoint:focusPoint];
    [self beginFocusAnimationAtPoint:tapPoint];
}

- (void)beginFocusAnimationAtPoint:(CGPoint)point {
    if (!self.focusImageView.superview) {
        [self.preview addSubview:self.focusImageView];
    }
    self.focusImageView.transform = CGAffineTransformMakeScale(1.65f, 1.65f);
    self.focusImageView.center = point;

    [UIView animateWithDuration:0.95f delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:15.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.focusImageView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
    }];

    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.focusImageView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25f delay:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.focusImageView.alpha = 0.0f;
        } completion:^(BOOL finished) {
        }];
    }];
}

#pragma mark - AVCamCaptureManagerDelegate
- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error {
    [self.captureButton setUserInteractionEnabled:YES];
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [WBAlertController alertWithTitle:[error wb_formattedDescription] message:[error localizedFailureReason] cancelTitle:loadMuLanguage(@"OK", @"OK button title") okTitle:nil cancel:NULL complete:NULL];
    });
}

#pragma mark - WBALAssetPickerContextManagerDelegate
- (void)WBALAssetPickerContextManagerCanceled:(WBALAssetPickerContextManager *)context {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)WBALAssetPickerContextManager:(WBALAssetPickerContextManager *)context finishedPickImageAttachments:(NSArray *)attachment {
    WBImageEditorCache *imageCahce = attachment.firstObject;

    [self previewSelectedImageCache:imageCahce];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self showAlbumCover:YES];
}

#pragma mark - subviews
- (WBPhotoEditorGradientView *)topview {
    if (!_topview) {
        self.topview = ({
            CGFloat topSafeMargin = [[UIDevice currentDevice] wbt_isIPhoneX] ? 44 : 0;
            WBPhotoEditorGradientView *view = [[WBPhotoEditorGradientView alloc] initWithFrame:CGRectMake(0, 0, self.view.wbtWidth, 70 + topSafeMargin)];
            view.startPoint = CGPointMake(0.5, 0.0);
            view.endPoint = CGPointMake(0.5, 1.0);
            view.colors = @[[UIColor colorWithWhite:0 alpha:0.15], [UIColor colorWithWhite:0 alpha:0]];
            view.locations = @[@0.0, @1.0];

            UIButton *backBtn = [UIBarButtonItem backButtonViewWithTitle:loadMuLanguage(@"返回", nil) image:[UIImage imageNamed:@"navigationbar_icon_back_withtext_white"] highlightedImage:nil normalTextColor:[UIColor whiteColor] highlightedTextColor:[UIColor colorWithWhite:1 alpha:0.8] target:self action:@selector(backButtonClicked) showsTouchWhenHighlighted:NO];
            backBtn.wbtLeft = 12.5;
            backBtn.wbtTop = topSafeMargin + 16;
            [view addSubview:backBtn];
            view;
        });
    }

    return _topview;
}

- (WBActivityCapturePreviewView *)preview {
    if (!_preview) {
        self.preview = ({
            CGFloat topSafeMargin = [[UIDevice currentDevice] wbt_isIPhoneX] ? 44 : 0;
            WBActivityCapturePreviewView *view = [[WBActivityCapturePreviewView alloc] initWithFrame:CGRectMake(0, topSafeMargin, self.view.wbtWidth, self.view.wbtWidth * 4 / 3)];
            view.captureVideoPreviewLayer.session = self.cameraManager.session;
            UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
            [view addGestureRecognizer:singleTap];

            UIImageView *headFrameImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 322, 309)];
            headFrameImageView.center = CGPointMake(view.wbtCenterX, view.wbtHeight / 2 + 5);
            headFrameImageView.image = [UIImage imageNamed:@"camera_head_frame"];
            [view addSubview:headFrameImageView];

            view;
        });
    }

    return _preview;
}

- (UIButton *)captureButton {
    if (!_captureButton) {
        self.captureButton = ({
            UIButton *bt = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
            bt.center = CGPointMake(self.view.wbtCenterX, self.view.wbtHeight - 83.5);
            [bt setImage:[UIImage imageNamed:@"activity_photograph_startbutton"] forState:UIControlStateNormal];
            [bt setImage:[UIImage imageNamed:@"activity_photograph_startbutton_press"] forState:UIControlStateHighlighted];
            [bt addTarget:self action:@selector(captureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            bt;
        });
    }

    return _captureButton;
}

- (WBActivityAlbumButton *)albumButton {
    if (!_albumButton) {
        self.albumButton = ({
            WBActivityAlbumButton *bt = [[WBActivityAlbumButton alloc] initWithFrame:CGRectMake((self.captureButton.wbtLeft - 25) / 2, 0, 25, 25)];
            bt.wbtCenterY = self.captureButton.wbtCenterY;
            [bt addTarget:self action:@selector(albumButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            bt;
        });
    }

    return _albumButton;
}

- (UIButton *)switchButton {
    if (!_switchButton) {
        self.switchButton = ({
            UIButton *bt = [[UIButton alloc] initWithFrame:CGRectMake(self.captureButton.wbtRight + (self.view.wbtWidth - self.captureButton.wbtRight - 38) / 2, 0, 38, 38)];
            bt.wbtCenterY = self.captureButton.wbtCenterY;
            [bt setImage:[UIImage imageNamed:@"navigationbar_camera_overturn"] forState:UIControlStateNormal];
            [bt addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            bt;
        });
    }

    return _switchButton;
}

- (UIImageView *)focusImageView {
    if (!_focusImageView) {
        self.focusImageView = ({
            UIImageView *fiv = [[UIImageView alloc] initWithFrame:CGRectZero];
            fiv.image = [UIImage imageNamed:@"wb_camera_panel_focus_ring"];
            fiv.alpha = 0.0f;
            [fiv sizeToFit];
            fiv;
        });
    }

    return _focusImageView;
}

@end
