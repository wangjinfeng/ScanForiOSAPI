//
//  SacanViewController.h
//  iOS自带二维码
//
//  Created by Mc on 15/1/9.
//  Copyright (c) 2015年 boco. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScanResultDelegate <NSObject>

@required
- (void) scanResult:(NSString *)str;

@end


@interface ScanViewController : UIViewController

@property (strong, nonatomic) id<ScanResultDelegate> scanDelegate;


- (instancetype)init ;

@end
