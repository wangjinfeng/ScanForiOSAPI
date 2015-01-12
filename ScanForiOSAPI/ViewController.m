//
//  ViewController.m
//  iOS自带二维码
//
//  Created by Mc on 15/1/9.
//  Copyright (c) 2015年 boco. All rights reserved.
//

#import "ViewController.h"
#import "ScanViewController.h"

@interface ViewController ()<ScanResultDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


#pragma mark - 其他方法
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions(扫描)
- (IBAction)scanAction:(id)sender {
    ScanViewController *view = [[ScanViewController alloc] init];
    [view setScanDelegate:self];
    
    [self.navigationController pushViewController:view animated:YES];
}

#pragma mark - 扫描结果代理方法
- (void) scanResult:(NSString *)str {
    
    [self.label setText:str];
    
}

@end
