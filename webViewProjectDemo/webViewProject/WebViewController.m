//
//  WebViewController.m
//  webViewProject
//
//  Created by nickwong on 16/10/19.
//  Copyright © 2016年 nickwong. All rights reserved.
//

#import "WebViewController.h"
#import "Tools.h"
#import "WebViewJavascriptBridge.h"
#import "WXApiObject.h"
#import "WXApi.h"
#import <MapKit/MapKit.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>


//导航栏高度
#define NavHeight 64
// 窗口宽度
#define FSScreenWidth [[UIScreen mainScreen] bounds].size.width
// 窗口高度
#define FSScreenHeight [[UIScreen mainScreen] bounds].size.height

@interface WebViewController ()<UIWebViewDelegate,UIScrollViewDelegate>
{
    UIImage *_shareImage;
    NSString *shareImgUrl;
    NSString *shareUrl;
    NSString *title;
    NSString *description;
    NSString *appointmentName;
    NSString *appointmentTime;
    NSString *appointmentAddress;
    NSString *searchAppointmentAddress;
    
    NSString *remindTitle;
    NSString *remindNotes;
    NSString *remindStartDate;
    NSString *remindEndDate;
    NSString *remindURL;
    
}

@property WebViewJavascriptBridge* bridge;
@property (strong, nonatomic) JSContext *context;

@end

@implementation WebViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshMsgTimer];
}

- (void)refreshMsgTimer
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimer *timer = [NSTimer timerWithTimeInterval:100.0f target:self selector:@selector(cleanCacheAndCookie) userInfo:nil repeats:YES];
        
        //将定时器添加到runloop中
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        
        [[NSRunLoop currentRunLoop] run];
    });
}

//在这迷糊了，发现一直监听不到，不像 AVCaptureDevice那样，能监听它自己的属性---adjustFocusing
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)contex{
    
    
   }
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //通过监听web view是否能够向前 或 向后来决定按钮是否可用,以前做自定义相机的时候能用这种方式监听是否在自动对焦，然后作出相应的处理，
    //但现在不管怎么试都没用，报错显示不能这样做，也不知为什么。。。
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    NSLog(@"viewWillAppear");
    if (_bridge) { return; }
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView  = [[UIWebView alloc]initWithFrame:CGRectMake(0, 20, FSScreenWidth, FSScreenHeight-20)];
    
    webView.scalesPageToFit = YES;
    webView.allowsInlineMediaPlayback = YES;
    [self.view addSubview:webView];
    //请求链接
    
//    NSURL *url = [[NSURL alloc]initWithString:@"http://t.apiadm.chydh.com/static/web-admin/login.html"];
    
//    NSURL *url = [[NSURL alloc]initWithString:@"http://m.admin.ipm123.com/static/web-admin/login.html"];
    
    
    NSURL *url = [[NSURL alloc]initWithString:@"http://d.apiadm.chydh.com/static/web-admin/login/login.html"];
    
    NSString *urlString = @"http://d.apiadm.chydh.com/ipmadm/";
    
    NSURLRequest *currentRequest = [NSURLRequest requestWithURL:url];
   
    NSString *time = [Tools getCurTime];
    NSString *sign = [Tools getSignBeforeMD5:time];
    NSString *md5Sign = [Tools md5HexDigest:sign];
//    NSLog(@"md5Sign为%@",md5Sign);
    
    // 1、开启日志
    
    // 2、给ObjC与JS建立桥梁
    _bridge = [WebViewJavascriptBridge bridgeForWebView:webView];
    
    // 3、设置代理
    [_bridge setWebViewDelegate:self];
    [WebViewJavascriptBridge enableLogging];
    
    id data = @{@"time":time };
    
    //  4、直接调用JS端注册的HandleName
    
    data = @{@"mark":@"babyMark"};
    
    // 5、注册HandleName，用于给JS端调用iOS端
    [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSString *time = [Tools getCurTime];
        NSString *sign = [Tools getSignBeforeMD5:time];
        NSString *md5Sign = [Tools md5HexDigest:sign];
        
        data = @{@"id":time,
                 @"caller":@"ios",
                 @"sign":md5Sign,
                 @"urlString":urlString
                 };
        
        responseCallback(data);
        
        id  returnData = responseCallback;
        NSLog(@"returnData是: %@", returnData);
        
    }];
    
    [_bridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded:%@", response);
    }];
    
    
    //bridge注册js分享链接回调方法
    [_bridge registerHandler:@"js_Call_Objc_Func" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSLog(@"js_Call_Objc_Func的data: %@", data[@"shareUrl"]);
        shareUrl = data[@"shareUrl"];
        title = data[@"title"];
        description = data[@"description"];
        shareImgUrl = data[@"coverImageUrl"];
        
        NSLog(@"js_Call_Objc_Func的shareUrl: %@", shareUrl);
        NSLog(@"js_Call_Objc_Func的title: %@", title);
        NSLog(@"js_Call_Objc_Func的description: %@", description);
        NSLog(@"js_Call_Objc_Func的shareImgUrl: %@", shareImgUrl);
        
        NSLog(@"js_Call_Objc_Func的data长度为: %lu", (unsigned long)shareUrl.length);
        NSInteger shareUrlLength = shareUrl.length;
        if (shareUrlLength>0) {
            [self downloadShareImageWithBlock:nil];
        }
    }];
    
    //bridge注册js添加事件到日历回调方法
    [_bridge registerHandler:@"js_Call_Objc_Appoint_Func" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSLog(@"js_Call_Objc_Appoint_Func的data: %@", data[@"appointmentName"]);
        appointmentName = data[@"appointmentName"];
        appointmentTime = data[@"appointmentTime"];
        appointmentAddress = data[@"appointmentAddress"];
        
        NSLog(@"js_Call_Objc_Appoint_Func的appointmentName: %@", appointmentName);
        NSLog(@"js_Call_Objc_Appoint_Func的appointmentTime: %@", appointmentTime);
        NSLog(@"js_Call_Objc_Appoint_Func的appointmentAddress: %@", appointmentAddress);
        
        NSLog(@"js_Call_Objc_Appoint_Func的appointmentName长度为: %lu", (unsigned long)appointmentName.length);
        NSInteger appointmentNameLength = appointmentName.length;
        if (appointmentNameLength>0) {
            [self addToCalender];
        }
    }];
    
    //bridge注册js添加备注到日历回调方法
    [_bridge registerHandler:@"js_Call_Objc_Remind_Func" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSLog(@"js_Call_Objc_Remind_Func的data: %@", data[@"remindTitle"]);
        remindTitle = data[@"remindTitle"];
        remindNotes  = data[@"remindNotes"];
        remindStartDate = data[@"remindStartDate"];
        remindEndDate= data[@"remindEndDate"];
        remindURL= data[@"remindURL"];
        
        NSLog(@"js_Call_Objc_Remind_Func的remindTitle: %@", remindTitle);
        NSLog(@"js_Call_Objc_Remind_Func的remindNotes: %@", remindNotes);
        NSLog(@"js_Call_Objc_Remind_Func的remindStartDate: %@", remindStartDate);
        NSLog(@"js_Call_Objc_Remind_Func的remindEndDate: %@", remindEndDate);
        NSLog(@"js_Call_Objc_Remind_Func的remindURL: %@", remindURL);
        
        NSLog(@"js_Call_Objc_Remind_Func的remindTitle长度为: %lu", (unsigned long)remindTitle.length);
        
        NSInteger remindTitlesLength = remindTitle.length;
        if (remindTitlesLength>0) {
            [self addRemindToCalender];
        }
    }];
    
    //bridge注册js添加事件到搜索地点回调方法
    [_bridge registerHandler:@"js_Call_Objc_SearchAppointmentAddress_Func" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSLog(@"js_Call_Objc_SearchAppointmentAddress_Func的data: %@", data[@"searchAppointmentAddress"]);
        searchAppointmentAddress = data[@"searchAppointmentAddress"];
        
        NSLog(@"js_Call_Objc_SearchAppointmentAddress_Func的searchAppointmentAddress: %@", searchAppointmentAddress);
        
        NSLog(@"js_Call_Objc_SearchAppointmentAddress_Func的searchAppointmentAddress长度为: %lu", (unsigned long)searchAppointmentAddress.length);
        NSInteger searchAppointmentAddressLength = searchAppointmentAddress.length;
        if (searchAppointmentAddressLength>0) {
            [self addMapNav];
        }
    }];
    
    
    //bridge注册js添加事件到搜索清除缓存方法
    [_bridge registerHandler:@"js_Call_Objc_Search_Func" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSLog(@"js_Call_Objc_Search_Func的data: %@", data[@"searchString"]);
        NSString *searchString = data[@"searchString"];
        
        NSLog(@"js_Call_Objc_Search_Func的searchString: %@", searchString);
        
        NSLog(@"js_Call_Objc_Search_Func的searchString长度为: %lu", (unsigned long)searchString.length);
        NSInteger searchStringLength = searchString.length;
        if (searchStringLength>0) {
            [self cleanCacheAndCookie];
        }
    }];
    
    [webView loadRequest:currentRequest];
}

#pragma mark -- 加载地图信息
-(void)addMapNav
{
    //这个判断其实是不需要的
    if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"https://maps.apple.com/"]]){
        
        //MKMapItem 使用场景: 1. 跳转原生地图 2.计算线路
        
        MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
        //地理编码器
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        
        //我们假定一个终点坐标，上海嘉定伊宁路2000号报名大厅:121.229296,31.336956
        
        [geocoder geocodeAddressString:searchAppointmentAddress completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            
            CLPlacemark *endPlacemark  = placemarks.lastObject;
            //创建一个地图的地标对象
            
            MKPlacemark *endMKPlacemark = [[MKPlacemark alloc] initWithPlacemark:endPlacemark];
            
            //在地图上标注一个点(终点)
            MKMapItem *endMapItem = [[MKMapItem alloc] initWithPlacemark:endMKPlacemark];

            //MKLaunchOptionsDirectionsModeKey 指定导航模式
            
            //NSString * const MKLaunchOptionsDirectionsModeDriving; 驾车
            
            //NSString * const MKLaunchOptionsDirectionsModeWalking; 步行
            
            //NSString * const MKLaunchOptionsDirectionsModeTransit; 公交
            
            [MKMapItem openMapsWithItems:@[currentLocation, endMapItem]
             
                           launchOptions:@{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES]}];

        }];
        
    }
}

#pragma mark -- 添加约见到日历
-(void)addToCalender
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
                }
                else if (!granted)
                {
                    
                }
                else
                {
                    //事件保存到日历
                    
                    //创建事件
                    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
                    event.title    =  [NSString stringWithFormat:@" 安排事件:%@约见", appointmentName];
                    event.location = [NSString stringWithFormat:@"位置:%@",appointmentAddress];
                    
                    NSDateFormatter *tempFormatter = [[NSDateFormatter alloc]init];
                    [tempFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    
                    NSDate *inputDate =  [tempFormatter dateFromString:appointmentTime];
                    NSDate *outputDate =  [[tempFormatter dateFromString:appointmentTime]dateByAddingTimeInterval:60 * 60 * 2];
                    
                    event.startDate = inputDate;
                    event.endDate = outputDate;
                    
                    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                    NSError *err;
                    [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
                    
                    NSLog(@"保存的appointmentName为%@",appointmentName);
                    NSLog(@"保存的appointmentAddress为%@",appointmentAddress);
                    NSLog(@"保存的appointmentTime为%@",appointmentTime);
                    
                    [Tools showTipsWithHUD:@"成功添加约见到日历" showTime:1.0f];
                    
                }
            });
        }];
    }
}

#pragma mark -- 添加备忘到日历
-(void)addRemindToCalender
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
                }
                else if (!granted)
                {
                    
                }
                else
                {
                    //事件保存到日历
                    
                    //创建事件
                    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
                    event.title =  [NSString stringWithFormat:@"%@", remindTitle];
                    event.notes = [NSString stringWithFormat:@"%@", remindNotes];
                    
                    NSDateFormatter *tempFormatter = [[NSDateFormatter alloc]init];
                    [tempFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    
                    event.URL=[NSURL URLWithString:remindURL];
                    NSDate *startDate =  [tempFormatter dateFromString:remindStartDate];
                    NSDate *endDate =  [tempFormatter dateFromString:remindEndDate];
                    
                    event.startDate = startDate;
                    event.endDate = endDate;
                    
                    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                    NSError *err;
                    [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
                    
                    NSLog(@"保存的remindTitle为%@",remindTitle);
                    NSLog(@"保存的remindNotes为%@",remindNotes);
                    
                    [Tools showTipsWithHUD:@"成功添加备注到日历" showTime:1.0f];
                    
                }
            });
        }];
    }
}


#pragma mark -- 加载下载图片
- (void)downloadShareImageWithBlock:(void(^)(void))callBack
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *imageUrl = [NSString stringWithFormat:@"%@",shareImgUrl];
        
        NSLog(@"downloadShareImageWithBlock的imageUrl: %@", imageUrl);
        
        if ([imageUrl isKindOfClass:[NSNull class]]||[imageUrl isEqualToString:@"<null>"]||(imageUrl.length ==0)||(imageUrl == nil)||[imageUrl isEqualToString:@""]||(imageUrl == NULL)||[imageUrl isEqual:[NSNull null]]) {
            
            imageUrl = @"http://static.ipm123.com/web/avatar/commonLogo.jpg";
            NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:imageUrl]];
            UIImage *shareImage = [UIImage imageWithData:imageData];
            _shareImage = shareImage;
            NSLog(@"为空的_shareImage: %@", _shareImage);
        }else{
            
            NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:imageUrl]];
            UIImage *shareImage = [UIImage imageWithData:imageData];
            _shareImage = shareImage;
            NSLog(@"不为空的_shareImage: %@", _shareImage);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callBack)
            {
                callBack();
            }
        });
        
        [self  shareWithMsg];
    });
}

#pragma mark -- 分享信息
- (void)shareWithMsg
{
    NSString *sharePath = shareUrl;
    //创建发送对象实例
    SendMessageToWXReq *sendReq = [[SendMessageToWXReq alloc] init];
    sendReq.bText = NO; //不使用文本信息
    sendReq.scene = 0;  //0 = 好友列表 1 = 朋友圈 2 = 收藏
    
    _shareImage = [self croppIngimageByImageName:_shareImage toRect:CGRectMake(_shareImage.size.width/2.0 - 50, _shareImage.size.height/2.0 - 50, 100, 100)];
    
    //创建分享内容对象
    WXMediaMessage *urlMessage = [WXMediaMessage message];
    urlMessage.title = title;
    urlMessage.description = description;
    NSLog(@"创建分享内容对象的_shareImage: %@", _shareImage);
    [urlMessage setThumbImage:_shareImage];
    
    //创建多媒体对象
    WXWebpageObject *webObj = [WXWebpageObject object];
    webObj.webpageUrl = sharePath;//分享链接
    
    //完成发送对象实例
    urlMessage.mediaObject = webObj;
    sendReq.message = urlMessage;
    //发送分享信息
    [WXApi sendReq:sendReq];
}

- (UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}


- (BOOL)prefersStatusBarHidden
{
    return NO;//隐藏为YES，显示为NO
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
    NSLog(@"webViewDidStartLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
}

- (void)webViewDidFinishLoad:(UIWebView *)web{
    
    NSLog(@"webViewDidFinishLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)webView:(UIWebView*)webView  DidFailLoadWithError:(NSError*)error{
    
    NSLog(@"DidFailLoadWithError");
}


#pragma mark -- UIWebDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    return  YES;
}

#pragma mark -- 清除cookies和缓存
- (void)cleanCacheAndCookie
{
    //清除cookies
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]){
        [storage deleteCookie:cookie];
    }
    //清除UIWebView的缓存
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLCache * cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    [cache setDiskCapacity:0];
    [cache setMemoryCapacity:0];
    
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    NSLog(@"%@进行webView缓存清理",dateString);
}

@end

























//-(void)shareWithMsg:(NSString *)shareUrl title:(NSString *)title description:(NSString *)description
//{
//    NSString *sharePath = shareUrl;
//    //创建发送对象实例
//    SendMessageToWXReq *sendReq = [[SendMessageToWXReq alloc] init];
//    sendReq.bText = NO; //不使用文本信息
//    sendReq.scene = 0;  //0 = 好友列表 1 = 朋友圈 2 = 收藏
//
//    _shareImage = [self croppIngimageByImageName:_shareImage toRect:CGRectMake(_shareImage.size.width/2.0 - 50, _shareImage.size.height/2.0 - 50, 100, 100)];
//
//    //创建分享内容对象
//    WXMediaMessage *urlMessage = [WXMediaMessage message];
//    urlMessage.title = title;
//    urlMessage.description = description;
//    NSLog(@"创建分享内容对象的_shareImage: %@", _shareImage);
//    [urlMessage setThumbImage:_shareImage];
//
//    //创建多媒体对象
//    WXWebpageObject *webObj = [WXWebpageObject object];
//    webObj.webpageUrl = sharePath;//分享链接
//
//    //完成发送对象实例
//    urlMessage.mediaObject = webObj;
//    sendReq.message = urlMessage;
//    //发送分享信息
//    [WXApi sendReq:sendReq];
//}






















