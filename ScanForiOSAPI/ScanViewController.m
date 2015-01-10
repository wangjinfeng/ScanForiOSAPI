//
//  SacanViewController.m
//  iOS自带二维码
//
//  Created by Mc on 15/1/9.
//  Copyright (c) 2015年 boco. All rights reserved.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface ScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) UIButton *cancelBtn;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation ScanViewController

- (instancetype)init {
    self = [super init];
    _cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelBtn setFrame:CGRectMake(0, 20, self.view.bounds.size.width, 40)];
    [_cancelBtn addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelBtn];
    return self;
}

#pragma mark 取消按钮
- (void) cancelAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // 载入声音
    [self loadBeepSound];
    
    // 调用扫描
    [self readQRcode];
}

#pragma mark - AVCapture代理方法
// 此方法是在识别到QRCode，并且完成转换 ，如果QRCode的内容越大，转换需要的时间就越长
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if ( _audioPlayer ) {
        [_audioPlayer play];
    }
        
    // 会频繁的扫描，调用代理方法
    // 1. 如果扫描完成，停止会话
    [self.session stopRunning];
    
    // 2. 删除预览图层
    [self.previewLayer removeFromSuperlayer];
    
    // 3. 设置界面显示扫描结果
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        // 提示：如果需要对url或者名片等信息进行扫描，可以在此进行扩展！
        NSLog(@"扫描结果：%@",obj);
        [self.scanDelegate scanResult:obj.stringValue];
    }
    [self cancelAction];
}

#pragma mark 播放声音
- (void) loadBeepSound {
    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep-beep" ofType:@"aiff"];
    NSURL *beepURL = [NSURL fileURLWithPath:beepFilePath];
    NSError *error;
    NSLog(@"%@",beepFilePath);
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error) {
        NSLog(@"Could not play beep file.%@",beepFilePath);
        NSLog(@"%@", [error localizedDescription]);
    }
    else{
        [_audioPlayer prepareToPlay];
    }
}

#pragma mark - 读取二维码
- (void) readQRcode {
    
    // 1.摄像头设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 2.设置输入（因为模拟器没有摄像头，所以先做个判断）
    NSError *error=nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if ( error ) {
        NSLog(@"没有摄像头");
    }
    
    // 3.输出（metadata元数据）
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    // 设置输出代理（说明：使用主线程队列，相应比较同步，使用其他队列，相应不同步，容易让用户产生不好的体验）
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //[output setMetadataObjectsDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    //CGRect frame = CGRectMake (( 124 )/ self.view.bounds.size.height ,(( self.view.bounds.size.width - 220 )/ 2 )/ self.view.bounds.size.width , 220 / self.view.bounds.size.width , 220 / self.view.bounds.size.width );
    CGSize size = self.view.bounds.size;
    CGRect cropRect = CGRectMake(40, 100, 240, 240);
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 1920./1080.;  //使用了1080p的图像输出
    if (p1 < p2) {
        CGFloat fixHeight = size.width * 1920. / 1080.;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                  cropRect.origin.x/size.width,
                                                  cropRect.size.height/fixHeight,
                                                  cropRect.size.width/size.width);
    } else {
        CGFloat fixWidth = size.height * 1080. / 1920.;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                  (cropRect.origin.x + fixPadding)/fixWidth,
                                                  cropRect.size.height/size.height,
                                                  cropRect.size.width/fixWidth);
    }
    
    
    // 4.拍摄会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    // 决定了视频输入每一帧图像质量的大小
    [session setSessionPreset:AVCaptureSessionPresetHigh]; //AVCaptureSessionPreset1920x1080
    // 添加session的输入和输出
    [session addInput:input];
    [session addOutput:output];
    // 设置输出的格式。提示：一定要先设置会话的输出为output之后，再指定输出的元数据类型！
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code]];
    
    
    // 5. 设置预览图层（用来让用户能够看到扫描情况）
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    // 5.1 设置preview图层的属性
    [preview setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    // 5.2 设置preview图层的大小
    //[preview setFrame:self.view.bounds];
    [preview setFrame:self.view.layer.bounds];
    [preview setBorderColor:[[UIColor redColor] CGColor]];
    [preview setBorderWidth:1];
    
    // 5.3 将图层添加到视图的图层
    [self.view.layer insertSublayer:preview atIndex:0];
    self.previewLayer = preview;
    
    // 6. 启动会话
    [session startRunning];
    self.session = session;

}

#pragma mark - 系统方法
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
