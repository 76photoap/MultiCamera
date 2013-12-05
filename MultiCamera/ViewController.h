//
//  ViewController.h
//  MultiCamera
//
//  Created by Yuya Moriguchi on 2013/07/30.
//  Copyright (c) 2013年 Yuya Moriguchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *rearCameraView;
@property (weak, nonatomic) IBOutlet UIView *frontCameraView;
@property (weak, nonatomic) IBOutlet UIImageView *frontCameraImage;
@property (weak, nonatomic) IBOutlet UIImageView *rearCameraImage;

- (IBAction)takePhotograph:(id)sender;
- (IBAction)showPhotoLibrary:(id)sender;
@end
