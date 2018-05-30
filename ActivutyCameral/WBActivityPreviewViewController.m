//
//  WBActivityPreviewViewController.m
//  BaseLibs
//
//  Created by swit on 2018/4/19.
//

#import "WBActivityPreviewViewController.h"
#import "WBImageEditorCache.h"
#import <CoreImage/CoreImage.h>
#import "WBActivityCameraViewController.h"
#import "WBActivityNavigationController.h"
@interface WBActivityPreviewViewController ()
@property (nonatomic, strong) WBImageEditorCache *imageCache;
@property (nonatomic, strong) UIImageView *preImageView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *confirmButton;
@end

@implementation WBActivityPreviewViewController
#pragma mark - lifeCycle
- (instancetype)initWithImageEditorCache:(WBImageEditorCache *)imageCache {
    self = [super init];
    if (self) {
        self.uiCode = @"10000776";
        self.imageCache = imageCache;
        self.navigationItem.hideNavigationBar = YES;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor wbt_ColorFromHexString:@"0f0f0f"];
    [self.view addSubview:self.preImageView];
    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.confirmButton];
    self.confirmButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = self.imageCache.outputImage;
        NSInteger faceCount = 0;
        if (image) {
            NSArray *faceArray = [self detectFaceWithImage:image];
            faceCount = faceArray.count;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (faceCount == 1) {
                self.confirmButton.enabled = YES;
            } else {
                [self showFaceHint:faceCount > 1];
            }
        });
    });
    [[WBAnalysisManager sharedManager] logWithCode:@"2589" andExtraParameters:self.analysisParameters];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated  {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - action
- (void)cancelButtonPressed:(UIButton *)sender {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.analysisParameters];

    params[@"ext"] = @"button_val:5";
    [[WBAnalysisManager sharedManager] logWithCode:@"2587" andExtraParameters:params];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmButtonPressed:(UIButton *)sender {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.analysisParameters];

    params[@"ext"] = @"button_val:6";
    [[WBAnalysisManager sharedManager] logWithCode:@"2587" andExtraParameters:params];
    WBActivityNavigationController *navController = (WBActivityNavigationController *)self.navigationController;
    if ([navController.pickerDelegate respondsToSelector:@selector(WBActivityController:finishedPickFaceImageCache:)]) {
        [navController.pickerDelegate WBActivityController:navController finishedPickFaceImageCache:self.imageCache];
    }
}

- (NSArray *)detectFaceWithImage:(UIImage *)faceImag {
    CIContext *context = [CIContext contextWithOptions:nil];
    // 此处是CIDetectorAccuracyHigh，若用于real-time的人脸检测，则用CIDetectorAccuracyLow，更快,少错检
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                  context:context
                                                  options:@{ CIDetectorAccuracy: CIDetectorAccuracyLow }];
    CIImage *ciimg = [CIImage imageWithCGImage:faceImag.CGImage];
    NSArray *features = [faceDetector featuresInImage:ciimg];

    return features;
}

- (void)showFaceHint:(BOOL)isContainFace {
    UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    hintLabel.textColor = [UIColor wbt_ColorFromHexString:@"e14123"];
    hintLabel.font = [UIFont systemFontOfSize:15];
    hintLabel.text = loadMuLanguage(@"没有找到你，换张照片试试吧", nil);
    [hintLabel sizeToFit];
    hintLabel.center = CGPointMake(self.preImageView.wbtCenterX + 16, self.preImageView.wbtBottom + 21);
    [self.view addSubview:hintLabel];
    UIImageView *hintImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    hintImageView.image = [UIImage imageNamed:@"navigationbar_preview_icon_prompt"];
    hintImageView.center = CGPointMake(hintLabel.wbtLeft - 16, hintLabel.wbtCenterY);
    [self.view addSubview:hintImageView];
}

#pragma mark - subviews
- (UIImageView *)preImageView {
    if (!_preImageView) {
        self.preImageView = ({
            CGFloat topSafeMargin = [[UIDevice currentDevice] wbt_isIPhoneX] ? 44 : 0;
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, topSafeMargin, self.view.wbtWidth, self.view.wbtWidth * 4 / 3)];
            iv.image = self.imageCache.outputImage;
            iv.contentMode = UIViewContentModeScaleAspectFit;
            iv;
        });
    }

    return _preImageView;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        self.cancelButton = ({
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            btn.center = CGPointMake(self.view.wbtWidth / 4, self.view.wbtHeight - 83.5);
            [btn setImage:[UIImage imageNamed:@"navigationbar_camera_icon_cancel"] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            btn;
        });
    }

    return _cancelButton;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        self.confirmButton = ({
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            btn.center = CGPointMake(self.view.wbtWidth * 3 / 4, self.view.wbtHeight - 83.5);
            [btn setImage:[UIImage imageNamed:@"navigationbar_camera_icon_sure"] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(confirmButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            btn;
        });
    }

    return _confirmButton;
}

@end
