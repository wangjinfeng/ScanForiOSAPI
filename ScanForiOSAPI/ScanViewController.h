//
//  SacanViewController.h
//  iOS自带二维码
//
//  Created by Mc on 15/1/9.
//  Copyright (c) 2015年 boco. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVCaptureSession;
@class AVCaptureVideoPreviewLayer;

@protocol ScanResultDelegate <NSObject>

@required
- (void) scanResult:(NSString *)str;

@end

@interface ScanViewController : UIViewController


@property (strong, nonatomic) id<ScanResultDelegate> scanDelegate;

// 二维码生成的会话
@property (strong, nonatomic)AVCaptureSession *session;

// 二维码生成的图层
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;


- (instancetype)init ;

@end
