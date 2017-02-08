//
//  SignalHandler.h
//  UncaughtExceptionDemo
//
//  Created by 谈Xx on 17/2/8.
//  Copyright (c) 2017年  谈Xx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignalHandler : NSObject

+(void)saveCreash:(NSString *)exceptionInfo;

@end

void InstallSignalHandler(void);
