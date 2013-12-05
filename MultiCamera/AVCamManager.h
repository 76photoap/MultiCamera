//
//  AVCamManager.h
//  MultiCamera
//
//  Created by Yuya Moriguchi on 2013/08/01.
//  Copyright (c) 2013年 Yuya Moriguchi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AVCamVideoType) {
    AVCamVideoTypeRear = 0,
    AVCamVideoTypeFront
};
typedef void(^captureCompletionBlock)(void);

@interface AVCamManager : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, readonly)AVCaptureVideoPreviewLayer *frontCamPreviewLayer;
@property (nonatomic, readonly)AVCaptureVideoPreviewLayer *rearCamPreviewLayer;
@property (nonatomic, readonly)UIImage *rearImage;
@property (nonatomic, readonly)UIImage *frontImage;

+ (AVCamManager *)sharedManager;
- (void)runSession;
- (void)stopSession;
- (void)switchCaptureSession;
- (void)captureImageWithConnection:(AVCamVideoType)videoType completionHandler:(captureCompletionBlock)completion;
- (UIImage *)compositeImage;

@end
