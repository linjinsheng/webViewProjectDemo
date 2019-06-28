//
//  Tools.m
//  FSIPM
//
//  Created by nickwong on 16/4/27.
//  Copyright © 2016年 nickwong. All rights reserved.
//

#import "Tools.h"

@implementation Tools

//HUD
+ (void)showTipsWithHUD:(NSString *)labelText showTime:(CGFloat)time
{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[[[UIApplication sharedApplication] delegate] window]] ;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = labelText;
    hud.labelFont = [UIFont systemFontOfSize:15.0];
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    [[[[UIApplication sharedApplication] delegate] window] addSubview:hud];
    
    [hud hide:YES afterDelay:time];
}

//获取当前时间
+ (NSString *)getCurTime
{
    NSTimeInterval curTime = [[NSDate date]timeIntervalSince1970];
    NSString *timeS = [NSString stringWithFormat:@"%.3f",curTime];
    NSMutableString *time = [NSMutableString stringWithString:timeS];
    [time deleteCharactersInRange:[timeS rangeOfString:@"."]];
    return time;
}

//在加密前获取标识
+ (NSString *)getSignBeforeMD5:(NSString *)time
{
    NSMutableString *sign = [[NSMutableString alloc]init];
    [sign appendString:@"ios"];
    [sign appendString:@"id="];
    [sign appendString:time];
    //[sign appendString:@"bc005d648c2769b3d728fb8"];
    [sign appendString:@"8693af6762ad44e98352591dbaceb6f2"];
    
    return sign;
}

//md5加密
+ (NSString *)md5HexDigest:(NSString*)input
{
    const char *str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    
    for (int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}



@end
