//
//  ViewControllerTest.m
//  MultiCamera
//
//  Created by laprasDrum on 2013/08/07.
//  Copyright (c) 2013年 laprasDrum. All rights reserved.
//

#import "ViewControllerTest.h"

@interface ViewControllerTest ()
@property BOOL isFinishedSaveAction;
@property (nonatomic, weak)NSDate *runloopInterval;
@end

@implementation ViewControllerTest

- (void)setUp
{
    _isFinishedSaveAction = false;
    _runloopInterval = [NSDate dateWithTimeIntervalSinceNow:1.0];
}

- (void)tearDown
{
    do {
        [[NSRunLoop currentRunLoop] runUntilDate:_runloopInterval];
    } while (!_isFinishedSaveAction);
}

#pragma mark - test case

- (void)testSaveImageWithUIKitMethod
{
    UIImage *image = [UIImage imageNamed:@"handSign.jpg"];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        STFail(@"failure on save action");
        _isFinishedSaveAction = true;
    } else {
        _isFinishedSaveAction = true;
    }
}

@end
