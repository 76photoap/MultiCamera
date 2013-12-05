//
//  ViewController.m
//  MultiCamera
//
//  Created by laprasDrum on 2013/07/30.
//  Copyright (c) 2013年 laprasDrum. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ViewController.h"
#import "AVCamManager.h"

@interface ViewController ()
@property (nonatomic, strong)ALAssetsLibrary *assetsLibrary;
@end

static dispatch_queue_t serialQueue;

@implementation ViewController

- (dispatch_queue_t)serialQueue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create("com.yuyacat.multicamera.savephoto", NULL);
    });
    return serialQueue;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.assetsLibrary = [ALAssetsLibrary new];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[AVCamManager sharedManager] runSession];
    
    // プレビュー画面の設定
    AVCaptureVideoPreviewLayer *rearCamPreviewLayer = [AVCamManager sharedManager].rearCamPreviewLayer;
    rearCamPreviewLayer.transform = self.rearCameraView.layer.transform;
    rearCamPreviewLayer.frame = self.rearCameraView.bounds;
    [self.rearCameraView.layer addSublayer:rearCamPreviewLayer];

    AVCaptureVideoPreviewLayer *frontCamPreviewLayer = [AVCamManager sharedManager].frontCamPreviewLayer;
    frontCamPreviewLayer.transform = self.frontCameraView.layer.transform;
    frontCamPreviewLayer.frame = self.frontCameraView.bounds;
    [self.frontCameraView.layer addSublayer:frontCamPreviewLayer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[AVCamManager sharedManager] stopSession];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction Methods

- (IBAction)takePhotograph:(id)sender
{
    // リアカメラの撮影
    [[AVCamManager sharedManager] captureImageWithConnection:AVCamVideoTypeRear completionHandler:^{
        self.rearCameraImage.image = [AVCamManager sharedManager].rearImage;
    }];
    
    // セッションの切り替え
    [[AVCamManager sharedManager] switchCaptureSession];
    
    // フロントカメラの撮影
    [[AVCamManager sharedManager] captureImageWithConnection:AVCamVideoTypeFront completionHandler:^{
        self.frontCameraImage.image = [AVCamManager sharedManager].frontImage;
    }];
    
    // セッションの切り替え(もとに戻す)
    [[AVCamManager sharedManager] switchCaptureSession];
    
    // フォトライブラリへ保存
    dispatch_async(dispatch_get_main_queue(), ^{
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            UIImage *photo = [[AVCamManager sharedManager] compositeImage];
            UIImageWriteToSavedPhotosAlbum(photo, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        });
    });
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"save photo!");
    }
}

- (IBAction)showPhotoLibrary:(id)sender
{
//    ALAssetsLibrary *photoLibrary = [ALAssetsLibrary new];
//    [photoLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
//                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
//                                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
//                                        if (result) {
//                                            ALAssetRepresentation *representation = [result defaultRepresentation];
//                                            CGImageRef imageRef = [representation fullResolutionImage];
//                                        }
//                                    }];
//                                } failureBlock:nil];
}

@end
