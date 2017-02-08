//
//  CrashReporter.m
//  CrashReporter-plcrashreporter
//
//  Created by 谈Xx on 17/2/8.
//  Copyright © 2017年 谈Xx. All rights reserved.
//

#import "CrashReporter.h"

#import <CrashReporter/PLCrashReporter.h>
#import <CrashReporter/PLCrashReport.h>
#import <CrashReporter/PLCrashReportTextFormatter.h>

#import <sys/types.h>
#import <sys/sysctl.h>

@implementation CrashReporter

/*
 * On iOS 6.x, when using Xcode 4, returning *immediately* from main()
 * while a debugger is attached will cause an immediate launchd respawn of the
 * application without the debugger enabled.
 *
 * This is not documented anywhere, and certainly occurs entirely by accident.
 * That said, it's enormously useful when performing integration tests on signal/exception
 * handlers, as it means we can use the standard Xcode build+run functionality without having
 * the debugger catch our signals (thus requiring that we manually relaunch the app after it has
 * installed).
 *
 * This may break at any point in the future, in which case we can remove it and go back
 * to the old, annoying, and slow approach of manually relaunching the application. Or,
 * perhaps Apple will bless us with the ability to run applications without the debugger
 * enabled.
 */
static bool debugger_should_exit (void) {
#if !TARGET_OS_IPHONE
    return false;
#endif
    
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    int name[4];
    
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
        NSLog(@"sysctl() failed: %s", strerror(errno));
        return false;
    }
    
    if ((info.kp_proc.p_flag & P_TRACED) != 0)
    return true;
    
    return false;
}

// APP启动将crash日志保存到新目录，并设置为iTunes共享
static void save_crash_report (PLCrashReporter *reporter) {
    if (![reporter hasPendingCrashReport])
        return;
    
#if TARGET_OS_IPHONE
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (![fm createDirectoryAtPath: documentsDirectory withIntermediateDirectories: YES attributes:nil error: &error]) {
        NSLog(@"Could not create documents directory: %@", error);
        return;
    }
    
    
    NSData *data = [reporter loadPendingCrashReportDataAndReturnError: &error];
    if (data == nil) {
        NSLog(@"Failed to load crash report data: %@", error);
        return;
    }
    
    NSString *outputPath = [documentsDirectory stringByAppendingPathComponent: @"demo.plcrash"];
    if (![data writeToFile: outputPath atomically: YES]) {
        NSLog(@"Failed to write crash report");
    }
    
    NSLog(@"Saved crash report to: %@", outputPath);
#endif
}

// 将plcrash格式的日志解析成log
static void analysis_crashTolog (PLCrashReporter *reporter) {
    NSError *outError;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *outputPath = [documentsDirectory stringByAppendingPathComponent: @"demo.plcrash"];
    NSData *data = [reporter loadPendingCrashReportDataAndReturnError: &outError];
    if (data == nil) {
        NSLog(@"Failed to load crash report data: %@", outError);
        return;
    }
//    NSData *data = [NSData dataWithContentsOfFile:outputPath];
    PLCrashReport *report = [[PLCrashReport alloc] initWithData: data error: &outError];
    if (report){
        NSString *text = [PLCrashReportTextFormatter stringValueForCrashReport: report
                                                                withTextFormat: PLCrashReportTextFormatiOS];
        NSString *logPath = [documentsDirectory stringByAppendingString:@"/crash.log"];
        [text writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }

}

void enable_crash_reporter_service ()
{
    NSError *error = nil;
    
    if (!debugger_should_exit()) {
        /* Configure our reporter */
        PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType: PLCrashReporterSignalHandlerTypeMach
                                                                           symbolicationStrategy: PLCrashReporterSymbolicationStrategyAll];
        PLCrashReporter *reporter = [[PLCrashReporter alloc] initWithConfiguration: config];
        
        // APP启动将crash日志保存到新目录，并设置为iTunes共享
        // 如果做了解析 这步觉得可以省略
        save_crash_report(reporter);
        
        // 解析
        analysis_crashTolog(reporter);
        
        // TODO 发送。。
        
        /* Enable the crash reporter */
        if (![reporter enableCrashReporterAndReturnError: &error]) {
            NSLog(@"Could not enable crash reporter: %@", error);
        }
        
    }

}



@end
