//
//  ViewController.m
//  CrashReporter-singleException
//
//  Created by 谈Xx on 17/2/8.
//  Copyright © 2017年 谈Xx. All rights reserved.
//

#import "ViewController.h"

typedef struct Test
{
    int a;
    int b;
}Test;

@interface ViewController ()
    
    @end

@implementation ViewController
    
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self singleCrash];
//    [self OCExceptionCrash];
}

- (void)singleCrash
{
    //1.信号量
    Test *pTest = {1,2};
    free(pTest);
    pTest->a = 5;
    
}
    
- (void)OCExceptionCrash
{
    //2.ios崩溃
    NSArray *array= @[@"tom",@"xxx",@"ooo"];
    [array objectAtIndex:5];
}
  
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
    
    @end
