//
//  NeckExternalController.m
//  BLEController
//
//  Created by 赵鸿博 on 15-4-26.
//  Copyright (c) 2015年 RedBearLab. All rights reserved.
//

#import "NeckExternalController.h"

@interface NeckExternalController ()

@end

@implementation NeckExternalController

UILabel *timeView;
UIImageView *view;
UILabel *description;
UIButton *previous;
UIButton *next;
UIButton *start;

int position;
NSArray *picArray;

@synthesize ble;

- (void)viewDidLoad {
    [super viewDidLoad];
    dispathQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    self.title = @"Neck External";
    // Do any additional setup after loading the view.
    
    picArray = [[NSArray alloc] initWithObjects:@"stretch1", @"stretch2", @"stretch1", nil];
    // Do any additional setup after loading the view.
    
    view = [[UIImageView alloc] initWithFrame:CGRectMake(50, 170, 210, 210)];
    view.image = [UIImage imageNamed:[picArray objectAtIndex:position]];
    
    timeView = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 200, 30)];
    timeView.text = @"20 seconds to next.";
    timeView.textAlignment = NSTextAlignmentCenter;
    
    description = [[UILabel alloc] initWithFrame:CGRectMake(50, 400, 200, 30)];
    description.text = [NSString stringWithFormat:@"%@ %d %@ %lu", @"Posture:", position + 1, @"/", (unsigned long)[picArray count]];
    description.textAlignment = NSTextAlignmentCenter;
    
    previous = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    previous.frame = CGRectMake(50, 450, 70, 30);
    [previous setTitle:@"Previous" forState:UIControlStateNormal];
    [previous setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [previous addTarget:self
                 action:@selector(previousPosture:)
       forControlEvents:UIControlEventTouchUpInside];
    if(position <= 0){
        [previous setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        previous.userInteractionEnabled = NO;
    }
    else
    {
        [previous setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        previous.userInteractionEnabled = YES;
    }
    
    next = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    next.frame = CGRectMake(200, 450, 70, 30);
    [next setTitle:@"Next" forState:UIControlStateNormal];
    [next addTarget:self
             action:@selector(nextPosture:)
   forControlEvents:UIControlEventTouchUpInside];
    if(position + 1 < [picArray count]){
        [next setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        next.userInteractionEnabled = YES;
    }
    else
    {
        [next setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        next.userInteractionEnabled = NO;
    }
    
    start = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    start.frame = CGRectMake(125, 450, 70, 30);
    [start setTitle:@"Start" forState:UIControlStateNormal];
    [start addTarget:self
              action:@selector(startPosture:)
    forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:view];
    [self.view addSubview:timeView];
    [self.view addSubview:description];
    [self.view addSubview:previous];
    [self.view addSubview:start];
    [self.view addSubview:next];
}

- (void) startPosture:(UIButton *)sender
{
    
    
}

- (void) nextPosture:(UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        if(position + 1 < [picArray count])
        {
            position++;
            dispatch_async(dispatch_get_main_queue(), ^(void){
                view.image = [UIImage imageNamed:[picArray objectAtIndex:position]];
                description.text = [NSString stringWithFormat:@"%@ %d %@ %lu", @"Posture:", position + 1, @"/", (unsigned long)[picArray count]];
                [previous setTitleColor:self.view.tintColor forState:UIControlStateNormal];
                previous.userInteractionEnabled = YES;
                if(position + 1 >= [picArray count])
                {
                    [next setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
                    next.userInteractionEnabled = NO;
                }
            });
        }
        else
        {
            [next setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [previous setTitleColor:self.view.tintColor forState:UIControlStateNormal];
            next.userInteractionEnabled = NO;
            previous.userInteractionEnabled = YES;
        }
    });
}

- (void) previousPosture:(UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        if(position - 1 >= 0)
        {
            position--;
            dispatch_async(dispatch_get_main_queue(), ^(void){
                view.image = [UIImage imageNamed:[picArray objectAtIndex:position]];
                description.text = [NSString stringWithFormat:@"%@ %d %@ %lu", @"Posture:", position + 1, @"/", (unsigned long)[picArray count]];
                [next setTitleColor:self.view.tintColor forState:UIControlStateNormal];
                next.userInteractionEnabled = YES;
                if(position - 1 < 0)
                {
                    [previous setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
                    previous.userInteractionEnabled = NO;
                }
            });
        }
        else
        {
            [previous setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [next setTitleColor:self.view.tintColor forState:UIControlStateNormal];
            previous.userInteractionEnabled = NO;
            next.userInteractionEnabled = YES;
        }
    });
}

- (void) sendMessage
{
    NSString *input = @"SEND NECK EXTERNAL";
    if([input length] > 0)
    {
        dispatch_async(dispathQueue, ^{
            
            //uint8_t *data;
            //NSUInteger length = [input length];
            //NSData *output = [NSData dataWithBytes:data length:length];
            NSData *output2 = [input dataUsingEncoding:NSUTF8StringEncoding];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [ble write:output2];
            });
        });
    }
}

-(void) processData:(uint8_t *) data length:(uint8_t) length
{
    
    //NSLog(@"StrengthenView: processData");
    //NSLog(@"Length: %d", length);
    
    NSData *d = [NSData dataWithBytes:data length:length];
    //_myData = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    //NSLog(@"Datos en String %@",s);
    
    [self readMessage:s];
    //[self sendMessage];
    //[protocol parseData:data length:length];
    
    //send message to BLE
    //UInt8 buf[] = {0x04, 0x00, 0x00};
    //NSData *output = [NSData dataWithBytes:data length:length];
    //[ble write:output];
}

- (void) readMessage:(NSString *) s
{
    dispatch_async(dispathQueue, ^{
        
        NSDate * date = [NSDate date];
        NSTimeInterval sec = [date timeIntervalSinceNow];
        NSDate * currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
        
        //设置时间输出格式：
        NSDateFormatter * df = [[NSDateFormatter alloc] init ];
        [df setDateFormat:@"HH:mm:ss:SSS"];
        NSString * na = [df stringFromDate:currentDate];
        
        //NSLog(@"系统当前时间为：%@",na);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [timeView setText:[s stringByAppendingString:na]];
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        NSLog(@"back pressed!!!");
        ble = nil;
        position = 0;
    }
    [super viewWillDisappear:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
