//
//  SignalHandler.m
//  UncaughtExceptionDemo
//
//  Created by 谈Xx on 17/2/8.
//  Copyright (c) 2017年  谈Xx. All rights reserved.
//

#import "SignalHandler.h"
//#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <UIKit/UIKit.h>
//#import "UncaughtExceptionHandler.h"
#import "sys/utsname.h"

@interface SignalHandler()<UIAlertViewDelegate>

@end


@implementation SignalHandler

+(void)saveCreash:(NSString *)exceptionInfo
{
    NSString * _libPath  = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"SigCrash"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_libPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:_libPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate *date=[NSDate date];
    // 日期的格式
    NSDateFormatter *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYYMMdd-HHmmss"];
    
    // 输出日期
    NSString *dateString=[dateformatter stringFromDate:date];
    
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
//    NSTimeInterval a=[dat timeIntervalSince1970];
//    NSString *timeString = [NSString stringWithFormat:@"%f", a];
    
    NSString * savePath = [_libPath stringByAppendingFormat:@"/Crash%@.log",dateString];
    exceptionInfo = [exceptionInfo stringByAppendingString:getAppInfo()];
    BOOL sucess = [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"YES sucess:%d",sucess);
}





void SignalExceptionHandler(int signal)
{
    
    NSMutableString *mstr = [[NSMutableString alloc] init];
    [mstr appendString:@"Stack:\n"];
    void* callstack[128];
    int i, frames = backtrace(callstack, 128);
    char** strs = backtrace_symbols(callstack, frames);
    for (i = 0; i <frames; ++i) {
        [mstr appendFormat:@"%s\n", strs[i]];
    }
    [SignalHandler saveCreash:mstr];

}

void InstallSignalHandler(void)
{

//    
//    struct sigaction mySigAction;
//    mySigAction.sa_sigaction = SignalExceptionHandler;
//    mySigAction.sa_flags = SA_SIGINFO;
//    
//    sigemptyset(&mySigAction.sa_mask);
//    sigaction(SIGQUIT, &mySigAction, NULL);
//    sigaction(SIGILL , &mySigAction, NULL);
//    sigaction(SIGTRAP, &mySigAction, NULL);
//    sigaction(SIGABRT, &mySigAction, NULL);
//    sigaction(SIGEMT , &mySigAction, NULL);
//    sigaction(SIGFPE , &mySigAction, NULL);
//    sigaction(SIGBUS , &mySigAction, NULL);
//    sigaction(SIGSEGV, &mySigAction, NULL);
//    sigaction(SIGSYS , &mySigAction, NULL);
//    sigaction(SIGPIPE, &mySigAction, NULL);
//    sigaction(SIGALRM, &mySigAction, NULL);
//    sigaction(SIGXCPU, &mySigAction, NULL);
//    sigaction(SIGXFSZ, &mySigAction, NULL);
   
    signal(SIGHUP, SignalExceptionHandler);
    signal(SIGINT, SignalExceptionHandler);
    signal(SIGQUIT, SignalExceptionHandler);
    
    signal(SIGABRT, SignalExceptionHandler);
    signal(SIGILL, SignalExceptionHandler);
    signal(SIGSEGV, SignalExceptionHandler);
    signal(SIGFPE, SignalExceptionHandler);
    signal(SIGBUS, SignalExceptionHandler);
    signal(SIGPIPE, SignalExceptionHandler);
}


NSString* getAppInfo()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    machine = [SignalHandler Devicemachine:machine];
    NSString *appInfo = [NSString stringWithFormat:@"App :%@ %@ %@(%@)\nDevice : %@\nOS Version : %@ \nUDID :%@ \nDateime:%@",
                         // 应用名
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                         // 应用版本号
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                         machine,
                         [UIDevice currentDevice].systemName,
                         [UIDevice currentDevice].systemVersion,
                         [UIDevice currentDevice].identifierForVendor,
                         [NSDate date]];
    NSLog(@"Crash!!!! %@", appInfo);
    
    return appInfo;
    
}

+(NSString *)Devicemachine:(NSString *)machine
{
    if ([machine isEqualToString:@"iPhone1,1"]) return @"iPhone 2G (A1203)";
    
    if ([machine isEqualToString:@"iPhone1,2"]) return @"iPhone 3G (A1241/A1324)";
    
    if ([machine isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS (A1303/A1325)";
    
    if ([machine isEqualToString:@"iPhone3,1"]) return @"iPhone 4 (A1332)";
    
    if ([machine isEqualToString:@"iPhone3,2"]) return @"iPhone 4 (A1332)";
    
    if ([machine isEqualToString:@"iPhone3,3"]) return @"iPhone 4 (A1349)";
    
    if ([machine isEqualToString:@"iPhone4,1"]) return @"iPhone 4S (A1387/A1431)";
    
    if ([machine isEqualToString:@"iPhone5,1"]) return @"iPhone 5 (A1428)";
    
    if ([machine isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (A1429/A1442)";
    
    if ([machine isEqualToString:@"iPhone5,3"]) return @"iPhone 5c (A1456/A1532)";
    
    if ([machine isEqualToString:@"iPhone5,4"]) return @"iPhone 5c (A1507/A1516/A1526/A1529)";
    
    if ([machine isEqualToString:@"iPhone6,1"]) return @"iPhone 5s (A1453/A1533)";
    
    if ([machine isEqualToString:@"iPhone6,2"]) return @"iPhone 5s (A1457/A1518/A1528/A1530)";
    
    if ([machine isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus (A1522/A1524)";
    
    if ([machine isEqualToString:@"iPhone7,2"]) return @"iPhone 6 (A1549/A1586)";
    
    if ([machine isEqualToString:@"iPod1,1"]) return @"iPod Touch 1G (A1213)";
    if ([machine isEqualToString:@"iPod2,1"]) return @"iPod Touch 2G (A1288)";
    
    if ([machine isEqualToString:@"iPod3,1"]) return @"iPod Touch 3G (A1318)";
    
    if ([machine isEqualToString:@"iPod4,1"]) return @"iPod Touch 4G (A1367)";
    
    if ([machine isEqualToString:@"iPod5,1"]) return @"iPod Touch 5G (A1421/A1509)";
    
    if ([machine isEqualToString:@"iPad1,1"]) return @"iPad 1G (A1219/A1337)";
    
    if ([machine isEqualToString:@"iPad2,1"]) return @"iPad 2 (A1395)";
    
    if ([machine isEqualToString:@"iPad2,2"]) return @"iPad 2 (A1396)";
    
    if ([machine isEqualToString:@"iPad2,3"]) return @"iPad 2 (A1397)";
    
    if ([machine isEqualToString:@"iPad2,4"]) return @"iPad 2 (A1395+New Chip)";
    
    if ([machine isEqualToString:@"iPad2,5"]) return @"iPad Mini 1G (A1432)";
    
    if ([machine isEqualToString:@"iPad2,6"]) return @"iPad Mini 1G (A1454)";
    
    if ([machine isEqualToString:@"iPad2,7"]) return @"iPad Mini 1G (A1455)";
    
    if ([machine isEqualToString:@"iPad3,1"]) return @"iPad 3 (A1416)";
    
    if ([machine isEqualToString:@"iPad3,2"]) return @"iPad 3 (A1403)";
    
    if ([machine isEqualToString:@"iPad3,3"]) return @"iPad 3 (A1430)";
    
    if ([machine isEqualToString:@"iPad3,4"]) return @"iPad 4 (A1458)";
    
    if ([machine isEqualToString:@"iPad3,5"]) return @"iPad 4 (A1459)";
    
    if ([machine isEqualToString:@"iPad3,6"]) return @"iPad 4 (A1460)";
    
    if ([machine isEqualToString:@"iPad4,1"]) return @"iPad Air (A1474)";
    
    if ([machine isEqualToString:@"iPad4,2"]) return @"iPad Air (A1475)";
    
    if ([machine isEqualToString:@"iPad4,3"]) return @"iPad Air (A1476)";
    
    if ([machine isEqualToString:@"iPad4,4"]) return @"iPad Mini 2G (A1489)";
    
    if ([machine isEqualToString:@"iPad4,5"]) return @"iPad Mini 2G (A1490)";
    
    if ([machine isEqualToString:@"iPad4,6"]) return @"iPad Mini 2G (A1491)";
    
    if ([machine isEqualToString:@"i386"]) return @"iPhone Simulator";
    
    if ([machine isEqualToString:@"x86_64"]) return @"iPhone Simulator";
    
    
    return machine;

}
@end
