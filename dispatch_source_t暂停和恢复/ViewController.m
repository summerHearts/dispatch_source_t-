//
//  ViewController.m
//  dispatch_source_t暂停和恢复
//
//  Created by 佐毅 on 16/1/27.
//  Copyright © 2016年 上海乐住信息技术有限公司. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    
    dispatch_source_t _processingQueueSource;
}

@property(assign,nonatomic) NSInteger timeInterval;
@property (atomic, assign, getter=isRunning) BOOL running;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UISwitch *switchBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.slider.maximumValue = 50.0f;
    self.slider.minimumValue = 0.0f;
    
    self.timeInterval = 50.0f;
    NSInteger totalTime =  self.timeInterval;
    
    //根据分派源数据在主线程中更新UI
//    _processingQueueSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0,
//                                                    dispatch_get_main_queue());
    
    //因为不是在主线程中创建，所以不要在此更新UI操作。（此种效果不会更新UI效果），如果需要更新，则必须在主线程中
    _processingQueueSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0,
                                                    dispatch_get_global_queue(0, 0));
    __block NSUInteger totalComplete = 0;
    dispatch_source_set_event_handler(_processingQueueSource, ^{
        
        NSUInteger value = dispatch_source_get_data(_processingQueueSource);
        totalComplete += value;
        if (self.timeInterval<=0) {
            _processingQueueSource = nil;
        }else{
            self.timeInterval --;
        }
         dispatch_async(dispatch_get_main_queue(), ^{
             //回调或者说是通知主线程刷新（如果监视某些类型事件的对象创建在主线程，那么不必再主线程中写，否则更新必须在主线程操作）
             _slider.value = totalComplete;
         });
        
    });
    
    
    //分派源创建时默认处于暂停状态，在分派源分派处理程序之前必须先恢复。
    [self resume];
    
    //恢复源后，就可以通过dispatch_source_merge_data向Dispatch Source(分派源)发送事件:
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        for (NSUInteger index = 0; index <totalTime; index++) {
            dispatch_source_merge_data(_processingQueueSource, 1);
            usleep(1000000);//1秒
        }
    });
    
    [self.switchBtn addTarget:self action:@selector(switchBtnAction:) forControlEvents:UIControlEventValueChanged];
    
}

- (void)switchBtnAction:(UISwitch *)switchBtn{
    if (switchBtn.on) {
        [self resume];
    }else{
        [self pause];
    }
}


- (void)resume {
    if (self.running) {
        return;
    }
    self.running = YES;
    dispatch_resume(_processingQueueSource);
}

- (void)pause {
    if (!self.running) {
        return;
    }
    self.running = NO;
    dispatch_suspend(_processingQueueSource);
}

@end