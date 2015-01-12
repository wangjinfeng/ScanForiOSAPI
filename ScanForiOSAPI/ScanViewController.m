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
// 二维码生成的会话
@property (strong, nonatomic)AVCaptureSession *session;

// 二维码生成的图层
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) UIView *localView;

@property (nonatomic, strong) UIView *scanView;

@property (nonatomic, strong) AVCaptureDevice *device;

@end

@implementation ScanViewController

- (instancetype)init {
    self = [super init];
    return self;
}

#pragma mark 取消按钮
- (void) back {
    self.audioPlayer = nil;
    self.previewLayer = nil;
    self.session = nil;
    self.localView = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark 播放声音
- (void) loadBeepSound {
    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep-beep" ofType:@"aiff"];
    NSURL *beepURL = [NSURL fileURLWithPath:beepFilePath];
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error) {
        NSLog(@"Could not play beep file.%@ \n%@",beepFilePath,[error localizedDescription]);
    }
    else{
        [_audioPlayer prepareToPlay];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(back)];

    
    UIView *localView= [[UIView alloc] initWithFrame:self.view.bounds];
    [localView setBackgroundColor:[UIColor clearColor]];
    self.localView = localView;
    [self.view addSubview:localView];
    
    UIView *bottomBarBgView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-60, self.view.bounds.size.width, 60)];
    bottomBarBgView.backgroundColor = [UIColor clearColor];
    [localView addSubview:bottomBarBgView];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setFrame:CGRectMake(10, 5, 60, 44)];
    [backBtn setTitle:@"Back" forState:UIControlStateNormal];
    [bottomBarBgView addSubview:backBtn];
    
    _scanView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, 180, 180)];
    [_scanView setCenter:CGPointMake(self.view.bounds.size.width*0.5, self.view.bounds.size.height*0.5)];
    _scanView.backgroundColor = [UIColor clearColor];
    [_scanView.layer setBorderColor:[[UIColor redColor] CGColor]];
    [_scanView.layer setBorderWidth:1];
    
    [localView addSubview:_scanView];
    
    
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
    [self back];
}



#pragma mark - 读取二维码
- (void) readQRcode {
    
    // 1.摄像头设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 2.设置输入（因为模拟器没有摄像头，所以先做个判断）
    NSError *error=nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
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
    [preview setFrame:CGRectMake(0, 0, self.localView.bounds.size.width, self.localView.bounds.size.height)];
    
    
    // 5.3 将图层添加到视图的图层
    //[self.view.layer insertSublayer:preview atIndex:0];
    [self.localView.layer insertSublayer:preview atIndex:0];
    self.previewLayer = preview;
    
    // 6. 启动会话
    [session startRunning];
    self.session = session;
    
    //[self focusAtPoint:CGPointMake(self.view.bounds.size.width*0.5, self.view.bounds.size.height*0.5)];
}

- (void) focusAtPoint:(CGPoint)point {
    
    AVCaptureDevice *device = self.device;
    NSError *error;
    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [device isFocusPointOfInterestSupported]) {
        
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error: %@", error);
        }
    }
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [self.view frame].size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [self previewLayer];
    
    if ([[self previewLayer] isMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[[self session] inputs] lastObject] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                    
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}


#pragma mark - 系统方法
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
