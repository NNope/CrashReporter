//
//  UncaughtExceptionHandler.m
//  UncaughtExceptionDemo
//
//  Created by 谈Xx on 17/2/8.
//  Copyright (c) 2017年  谈Xx. All rights reserved.
//

#import "UncaughtExceptionHandler.h"
//#include <libkern/OSAtomic.h>
//#include <execinfo.h>
//#import <UIKit/UIKit.h>


// 我的捕获handler
static NSUncaughtExceptionHandler custom_exceptionHandler;
static NSUncaughtExceptionHandler *oldhandler;

@implementation UncaughtExceptionHandler

+(void)saveCreash:(NSString *)exceptionInfo
{
    NSString * _libPath  = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"OCCrash"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_libPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:_libPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[dat timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f", a];
    
    NSString * savePath = [_libPath stringByAppendingFormat:@"/error%@.log",timeString];
    
    BOOL sucess = [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"YES sucess:%d",sucess);
}

// 注册
void InstallUncaughtExceptionHandler(void)
{
    
    
    if(NSGetUncaughtExceptionHandler() != custom_exceptionHandler)
    oldhandler = NSGetUncaughtExceptionHandler();
    
    NSSetUncaughtExceptionHandler(&custom_exceptionHandler);
    
}

// 注册回原有的
void Uninstall()
{
    NSSetUncaughtExceptionHandler(oldhandler);
}

void custom_exceptionHandler(NSException *exception)
{
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    
    // 出现异常的原因
    NSString *reason = [exception reason];
    
    // 异常名称
    NSString *name = [exception name];
    
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    
    NSLog(@"%@", exceptionInfo);

    [UncaughtExceptionHandler saveCreash:exceptionInfo];
    
    // 注册回之前的handler
    Uninstall();
}
    
@end




