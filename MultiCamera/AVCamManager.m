//
//  AVCamManager.m
//  MultiCamera
//
//  Created by laprasDrum on 2013/08/01.
//  Copyright (c) 2013年 laprasDrum. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import "AVCamManager.h"

@interface AVCamManager ()
@property (nonatomic, strong)AVCaptureSession *frontCamSession;
@property (nonatomic, strong)AVCaptureSession *rearCamSession;
@property (nonatomic, weak)AVCaptureVideoPreviewLayer *frontCamPreviewLayer;
@property (nonatomic, weak)AVCaptureVideoPreviewLayer *rearCamPreviewLayer;
@property (nonatomic, strong)AVCaptureStillImageOutput *frontImageOutput;
@property (nonatomic, strong)AVCaptureStillImageOutput *rearImageOutput;
@property (nonatomic, weak)UIImage *rearImage;
@property (nonatomic, weak)UIImage *frontImage;
@end

static AVCamManager *sharedInstance;

@implementation AVCamManager

+ (AVCamManager *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AVCamManager new];
        if (sharedInstance) {
            [sharedInstance setUpSession];
        }
    });
    return sharedInstance;
}

#pragma mark - Session Control Methods

- (void)setUpSession
{
    // カメラキャプチャ用セッションの作成
    self.frontCamSession = [AVCaptureSession new];
    self.rearCamSession = [AVCaptureSession new];
    [_frontCamSession setSessionPreset:AVCaptureSessionPresetPhoto];
    [_rearCamSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // カメラデバイス(フロント/リア)インプットをセッションに登録
    AVCaptureDevice *rearCam = nil;
    AVCaptureDevice *frontCam = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        switch (device.position) {
            case AVCaptureDevicePositionBack:
                rearCam = device;
                break;
                
            case AVCaptureDevicePositionFront:
                frontCam = device;
                break;
                
            default:
                break;
        }
    }
    AVCaptureDeviceInput *rearCamInput = [AVCaptureDeviceInput deviceInputWithDevice:rearCam
                                                                               error:nil];
    AVCaptureDeviceInput *frontCamInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCam
                                                                                error:nil];
    if ([_rearCamSession canAddInput:rearCamInput]) {
        [_rearCamSession addInput:rearCamInput];
    }
    if ([_frontCamSession canAddInput:frontCamInput]) {
        [_frontCamSession addInput:frontCamInput];
    }
    
    // 静止画アウトプットをセッションに追加
    self.frontImageOutput = [AVCaptureStillImageOutput new];
    if ([_frontCamSession canAddOutput:_frontImageOutput]) {
        [_frontCamSession addOutput:_frontImageOutput];
    }
    NSDictionary *outputInfo = @{AVVideoCodecKey : AVVideoCodecJPEG,
                                 (id)kCVPixelBufferPixelFormatTypeKey : @(kCMPixelFormat_32BGRA)};
    _frontImageOutput.outputSettings = outputInfo;
    
    self.rearImageOutput = [AVCaptureStillImageOutput new];
    if ([_rearCamSession canAddOutput:_rearImageOutput]) {
        [_rearCamSession addOutput:_rearImageOutput];
    }
    _rearImageOutput.outputSettings = outputInfo;
    
    // コネクションの設定
    AVCaptureConnection *frontConn = [_frontImageOutput connectionWithMediaType:AVMediaTypeVideo];
    frontConn.automaticallyAdjustsVideoMirroring = YES;
    frontConn.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    AVCaptureConnection *rearConn = [_rearImageOutput connectionWithMediaType:AVMediaTypeVideo];
    rearConn.automaticallyAdjustsVideoMirroring = YES;
    rearConn.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    // リアルタイムプレビューを画面に表示
    self.rearCamPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_rearCamSession];
    _rearCamPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    self.frontCamPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_frontCamSession];
    _frontCamPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)switchCaptureSession
{
    if ([_frontCamSession isRunning] && ![_rearCamSession isRunning]) {
        [_frontCamSession stopRunning];
        [_rearCamSession startRunning];
    } else if ([_rearCamSession isRunning] && ![_frontCamSession isRunning]) {
        [_rearCamSession stopRunning];
        [_frontCamSession startRunning];
    }
}

- (void)runSession
{
    [_rearCamSession startRunning];
}

- (void)stopSession
{
    if ([_frontCamSession isRunning]) {
        [_frontCamSession stopRunning];
    }
    if ([_rearCamSession isRunning]) {
        [_rearCamSession stopRunning];
    }
}

#pragma mark - Capture Methods
- (void)captureImageWithConnection:(AVCamVideoType)videoType completionHandler:(captureCompletionBlock)completion
{
    AVCaptureStillImageOutput *imageOut = nil;
    AVCaptureConnection *connection = nil;
    switch (videoType) {
        case AVCamVideoTypeRear:
            imageOut = self.rearImageOutput;
            connection = [imageOut connectionWithMediaType:AVMediaTypeVideo];
            break;
            
        case AVCamVideoTypeFront:
            imageOut = self.frontImageOutput;
            connection = [imageOut connectionWithMediaType:AVMediaTypeVideo];
            break;
            
        default:
            NSLog(@"cannot get image output");
            return;
            break;
    }
    [imageOut captureStillImageAsynchronouslyFromConnection:connection
                                          completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                              if (!error) {
                                                  UIImage *image = [self imageFromSampleBuffer:imageDataSampleBuffer];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      switch (videoType) {
                                                          case AVCamVideoTypeRear:
                                                              _rearImage = image;
                                                              break;
                                                              
                                                          case AVCamVideoTypeFront:
                                                              _frontImage = image;
                                                              break;
                                                              
                                                          default:
                                                              break;
                                                      }
                                                      completion();
                                                  });
                                              }
                                              else {
                                                  NSLog(@"photo err: %@", error);
                                              }
                                          }];
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // Core Videoのイメージバッファを取得後、ロックする
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // イメージ情報の取得
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // イメージ情報をもとにQuartzイメージを作成
    CGContextRef ctx = CGBitmapContextCreate(baseAddress,
                                             width,
                                             height,
                                             8,
                                             bytesPerRow,
                                             colorSpace,
                                             (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    
    // 回転調整したUIImageを作成
    UIImage *image = [UIImage imageWithCGImage:cgImage
                                         scale:1.0
                                   orientation:UIImageOrientationRight];
    
    // イメージ情報のリリース
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    CGImageRelease(cgImage);
    
    return image;
}

- (UIImage *)compositeImage
{
    if (!_rearImage || !_frontImage) {
        NSLog(@"cannot get image! take photo at first!");
        return nil;
    }
    
    // 合成イメージの情報
    // 回転調整のためサイズの幅と高さの入れ替え
    CGSize baseSize = _rearCamPreviewLayer.bounds.size;
    CGSize size = CGSizeMake(baseSize.height, baseSize.width);
    CGRect frontImageFrame = _frontCamPreviewLayer.superlayer.frame;
    CGSize frontSize = CGSizeMake(frontImageFrame.size.height, frontImageFrame.size.width);
    frontImageFrame.size = frontSize;
    
    CGImageRef rearImageRef = self.rearImage.CGImage;
    CGImageRef frontImageRef = self.frontImage.CGImage;
    unsigned char *bitmap = malloc(size.width * size.height * sizeof(unsigned char) * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Quartzイメージの作成
    CGContextRef ctx = CGBitmapContextCreate(bitmap,
                                             size.width,
                                             size.height,
                                             8,
                                             size.width * 4,
                                             colorSpace,
                                             (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
    CGContextDrawImage(ctx, (CGRect){.size = size}, rearImageRef);
    CGContextDrawImage(ctx, frontImageFrame, frontImageRef);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    
    // 回転調整したUIImageを作成
    UIImage *image = [UIImage imageWithCGImage:imageRef
                                         scale:1.0
                                   orientation:UIImageOrientationRight];

    // リソースの解放
    free(bitmap);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    CGImageRelease(imageRef);
    _rearImage = nil;
    _frontImage = nil;
    
    return image;
}

- (void)saveImageToLibrary:(UIImage *)image
{
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"failure on Saving Image");
    } else {
        NSLog(@"saved image!!");
        return;
    }
}

@end
