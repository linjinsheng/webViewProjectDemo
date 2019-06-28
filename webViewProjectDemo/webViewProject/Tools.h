//
//  Tools.h
//  FSIPM
//
//  Created by nickwong on 16/4/27.
//  Copyright © 2016年 nickwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "MBProgressHUD.h"

@interface Tools : NSObject

/**
 * HUD
 */
+ (void)showTipsWithHUD:(NSString *)labelText showTime:(CGFloat)time;

/**
 * 获取当前时间
 */
+ (NSString *)getCurTime;

/**
 * 在加密前获取标识
 */
+ (NSString *)getSignBeforeMD5:(NSString *)time;

/**
 * md5加密
 */
+ (NSString *)md5HexDigest:(NSString*)input;




@end
