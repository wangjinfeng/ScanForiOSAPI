//
//  AVCaptureViewController.m
//  ScanForiOSAPI
//
//  Created by Mc on 15/1/12.
//  Copyright (c) 2015年 boco. All rights reserved.
//

#import "AVCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
                                      
@interface AVCaptureViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIView *localView;

@property (nonatomic, strong) AVCaptureSession *avCaptureSession;

@property (nonatomic, strong) AVCaptureDevice *avCaptureDevice;

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *avCaptureVideoDataOutput;

@property (nonatomic, strong) AVCaptureStillImageOutput *avCaptureStillImageOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, assign) BOOL takePictureFrame;

@property (nonatomic, assign) CGFloat frameScale;

@property (nonatomic, assign) AVCaptureDevicePosition cameraDevice;

@end

@implementation AVCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.frameScale = 1.0;
    
    self.cameraDevice = AVCaptureDevicePositionBack;
    
    self.takePictureFrame = NO;
    
    [self createControl];
    
    [self startVideoCapture];
    
    [self initPinchGesture];
}

- (void) createControl {
    
    //UI展示
    self.view.backgroundColor= [UIColor grayColor];
    UIView *localView= [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.localView = localView;
    [self.view addSubview:localView];
    
    UIView *bottomBarBgView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-60, self.view.bounds.size.width, 60)];
    bottomBarBgView.backgroundColor = [UIColor redColor];
    [localView addSubview:bottomBarBgView];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [backBtn addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setFrame:CGRectMake(10, 5, 60, 44)];
    [backBtn setTitle:@"Back" forState:UIControlStateNormal];
    [bottomBarBgView addSubview:backBtn];
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cameraBtn.frame = CGRectMake(120, 5, 80, 44);
    [cameraBtn setTitle:@"TakePhoto" forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarBgView addSubview:cameraBtn];
    
    //UIImage *deviceImage = [UIImage imageNamed:@"camera_button_switch_camera.png"];
    UIButton *deviceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [deviceBtn setTitle:@"切换" forState:UIControlStateNormal];
    //[deviceBtn setBackgroundImage:deviceImage forState:UIControlStateNormal];
    [deviceBtn addTarget:self action:@selector(swapFrontAndBackCameras:) forControlEvents:UIControlEventTouchUpInside];
    [deviceBtn setFrame:CGRectMake(250, 20, 50, 44)];
    [localView addSubview:deviceBtn];
}



- (void)startVideoCapture {
    
    //打开摄像设备，并开始捕抓图像
    if(self.avCaptureDevice || self.avCaptureSession) {
        NSLog(@"Already capturing");
        return;
    }
    if((self.avCaptureDevice = [self getCameraDevice:self.cameraDevice]) == nil) {
        NSLog(@"Failed to get valide capture device");
        return;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:&error];
    if (!videoInput) {
        NSLog(@"Failed to get video input");
        self.avCaptureDevice = nil;
        return;
    }
    self.videoInput = videoInput;
    self.avCaptureSession = [[AVCaptureSession alloc] init];
    self.avCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    [self.avCaptureSession addInput:videoInput];
    
#if 0
    // Currently, the only supported key is kCVPixelBufferPixelFormatTypeKey. Recommended pixel format choices are
    // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or kCVPixelFormatType_32BGRA.
    // On iPhone 3G, the recommended pixel format choices are kCVPixelFormatType_422YpCbCr8 or kCVPixelFormatType_32BGRA.
    //
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary*settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                             //[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                             [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                             nil];
    avCaptureVideoDataOutput.videoSettings = settings;
    
    //avCaptureVideoDataOutput.minFrameDuration = CMTimeMake(1, self.producerFps);
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue = dispatch_queue_create("avCaptureDemoQueue", NULL);
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    [self.avCaptureSession addOutput:avCaptureVideoDataOutput];
    self.avCaptureVideoDataOutput = avCaptureVideoDataOutput;
    [avCaptureVideoDataOutput release];
    dispatch_release(queue);
    
#else
    
    AVCaptureStillImageOutput *avCaptureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary*settings = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,nil];
    avCaptureStillImageOutput.outputSettings = settings;
    self.avCaptureStillImageOutput = avCaptureStillImageOutput;
    [self.avCaptureSession addOutput:avCaptureStillImageOutput];
    
#endif
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.avCaptureSession];
    previewLayer.frame = CGRectMake(0, 0, self.localView.bounds.size.width, self.localView.bounds.size.height-60);
    previewLayer.videoGravity= AVLayerVideoGravityResizeAspectFill;
    //[self.localView.layer addSublayer:previewLayer];
    [self.localView.layer insertSublayer:previewLayer atIndex:0];
    self.previewLayer = previewLayer;
    [self.avCaptureSession startRunning];
    NSLog(@"Video capture started");
}

- (AVCaptureDevice *)getCameraDevice:(AVCaptureDevicePosition) devicePosition {
    
    //获取前置摄像头设备
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras) {
        if (device.position == devicePosition)
            return device;
    }
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void)stopVideoCapture:(id)arg {
    //停止摄像头捕抓
    if(self.avCaptureSession){
        [self.avCaptureSession stopRunning];
        [self.avCaptureSession removeInput:self.videoInput];
        self.videoInput = nil;
        
        [self.avCaptureSession removeOutput:self.avCaptureVideoDataOutput];
        self.avCaptureVideoDataOutput = nil;
        
        self.avCaptureSession= nil;
        NSLog(@"Video capture stopped");
    }
    self.avCaptureDevice= nil;
    
    //移除localView里面的预览内容
    for(CALayer *layer in self.localView.layer.sublayers){
        if ([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]]){
            [layer removeFromSuperlayer];
            return;
        }
    }
    self.previewLayer = nil;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the buffer*/
    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess) {
        //UInt8 *bufferPtr = (UInt8 *)CVPixelBufferGetBaseAddress(pixelBuffer);
        //size_t buffeSize = CVPixelBufferGetDataSize(pixelBuffer);
        if(self.takePictureFrame){
            self.takePictureFrame = NO;
            //第一次数据要求：宽高，类型
            //int width_1 = CVPixelBufferGetWidth(pixelBuffer);
            //int height_1 = CVPixelBufferGetHeight(pixelBuffer);
            /*
             int pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
             switch (pixelFormat) {
             casekCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
             //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_nv12; // iPhone 3GS or 4
             NSLog(@"Capture pixel format=NV12");
             break;
             casekCVPixelFormatType_422YpCbCr8:
             //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_uyvy422; // iPhone 3
             NSLog(@"Capture pixel format=UYUY422");
             break;
             default:
             //TMEDIA_PRODUCER(producer)->video.chroma = tmedia_rgb32;
             NSLog(@"Capture pixel format=RGB32");
             break;
             }
             */
            /*Create a CGImageRef from the CVImageBufferRef*/
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

            /*Lock the image buffer*/
            CVPixelBufferLockBaseAddress(imageBuffer,0);
            uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
            size_t width = CVPixelBufferGetWidth(imageBuffer);
            size_t height = CVPixelBufferGetHeight(imageBuffer);

            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
            CGImageRef newImage = CGBitmapContextCreateImage(newContext);

            /*We release some components*/
            CGContextRelease(newContext);
            CGColorSpaceRelease(colorSpace);
            UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];

            /*We relase the CGImageRef*/
            CGImageRelease(newImage);
            [self performSelectorOnMainThread:@selector(takeImageFinished:) withObject:image waitUntilDone:NO];
            /*We unlock the  image buffer*/
            CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        }
        /*We unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
}

-(UIImage *) getImageBySampleBuffer:(CMSampleBufferRef)sampleBuffer {
    UIImage *image = nil;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the buffer*/
    if(CVPixelBufferLockBaseAddress(pixelBuffer, 0) == kCVReturnSuccess) {
        /*Create a CGImageRef from the CVImageBufferRef*/
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);

        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];

        /*We relase the CGImageRef*/
        CGImageRelease(newImage);

        //[self performSelectorOnMainThread:@selector(takeImageFinished:) withObject:image waitUntilDone:NO];
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);

        /*We unlock the buffer*/
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    return image;
}

#pragma mark - button response

//切换前、后置摄像头
- (void)swapFrontAndBackCameras:(id)sender {
    
    if (self.cameraDevice == AVCaptureDevicePositionBack ) {
        self.cameraDevice = AVCaptureDevicePositionFront;
    }
    else {
        self.cameraDevice = AVCaptureDevicePositionBack;
    }
    self.avCaptureDevice = [self getCameraDevice:self.cameraDevice];
    [[self.previewLayer session] beginConfiguration];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.avCaptureDevice error:nil];
    for (AVCaptureInput *oldInput in [[self.previewLayer session] inputs]) {
        [[self.previewLayer session] removeInput:oldInput];
    }
    
    [[self.previewLayer session] addInput:input];
    [[self.previewLayer session] commitConfiguration];
}

- (void) closeView {
    [self stopVideoCapture:nil];
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void) takePicture {
    [self.avCaptureStillImageOutput captureStillImageAsynchronouslyFromConnection:[self connectionWithMediaType:AVMediaTypeVideo fromConnections:self.avCaptureStillImageOutput.connections] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (error.code == 0 || error == nil){
            UIImage *image = [self getImageBySampleBuffer:imageDataSampleBuffer];
            [self performSelectorOnMainThread:@selector(takeImageFinished:) withObject:image waitUntilDone:NO];
        }
    }];
}

-(void) takeImageFinished:(UIImage *)aImage {
    UIImageWriteToSavedPhotosAlbum(aImage, nil, nil, nil);
    //if ([self.customDelegate respondsToSelector:@selector(cameraPhoto:)]) {
     //   [self.customDelegate cameraPhoto:aImage];
    //}
    [self stopVideoCapture:nil];
    [self dismissViewControllerAnimated:NO completion:NULL];
}


-(AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
    
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}


#if 0

#pragma mark - 录制视频

-(void)startRecording {
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:m_captureMovieFileOutput.connections] ;
    // if ([videoConnection isVideoOrientationSupported])
    // 此处保存的视频可以更换宽高AVCaptureVideoOrientationPortrait||AVCaptureVideoOrientationLandscapeRight
    [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    NSURL *outputFileUrl = [GLRecord tempFileURL];
    
    // 生成缓存文件
    //AVCaptureMovieFileOutput
    [m_captureMovieFileOutput startRecordingToOutputFileURL:outputFileUrl recordingDelegate:self];
}

-(void)stopRecording {
    [m_captureMovieFileOutput stopRecording];
}


- (void) resetRecording {
    [m_captureMovieFileOutput stopRecording];
    
    // 移除缓存文件
}

#pragma mark - 设置焦点，焦点范围0-1，左上（0，0）

- (void) focusAtPoint:(CGPoint)point {
    
    AVCaptureDevice *device = self.avCaptureDevice;
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
#endif


-(void) initPinchGesture {
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.localView addGestureRecognizer:pinchGestureRecognizer];
}

- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer {
    
    if ((self.frameScale * recognizer.scale) < 1.0)
        return;
    
#if 0
    
    AVCaptureConnection *focusConnection =[self.avCaptureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if (recognizer.scale > [focusConnection videoMaxScaleAndCropFactor])
        return;
    self.frameScale = self.frameScale * recognizer.scale;
    //self.previewLayer.transform = CATransform3DScale(self.previewLayer.transform, recognizer.scale, recognizer.scale, 1);
    focusConnection.videoScaleAndCropFactor = self.frameScale;
#else
    
    if (recognizer.scale > self.avCaptureDevice.activeFormat.videoMaxZoomFactor)
        return;
    
    self.frameScale = self.frameScale * recognizer.scale;
    [self.avCaptureDevice lockForConfiguration:nil];
    self.avCaptureDevice.videoZoomFactor = self.frameScale;
    [self.avCaptureDevice unlockForConfiguration];
    
#endif
    
    recognizer.scale = 1;
}

// 此方法是在识别到QRCode，并且完成转换 ，如果QRCode的内容越大，转换需要的时间就越长
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    // 会频繁的扫描，调用代理方法
    // 1. 如果扫描完成，停止会话
    [self.avCaptureSession stopRunning];
    
    // 2. 删除预览图层
    [self.previewLayer removeFromSuperlayer];
    
    // 3. 设置界面显示扫描结果
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        // 提示：如果需要对url或者名片等信息进行扫描，可以在此进行扩展！
        NSLog(@"扫描结果：%@",obj);
    }
}



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
