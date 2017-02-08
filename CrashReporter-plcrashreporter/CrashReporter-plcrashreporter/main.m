//
//  main.m
//  CrashReporter-plcrashreporter
//
//  Created by 谈Xx on 17/2/8.
//  Copyright © 2017年 谈Xx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CrashReporter.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
    
        enable_crash_reporter_service();
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
