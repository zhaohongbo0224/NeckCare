//
//  NeckStrengthenController.m
//  BLEController
//
//  Created by 赵鸿博 on 15-4-26.
//  Copyright (c) 2015年 RedBearLab. All rights reserved.
//

#import "NeckStrengthenController.h"

@interface NeckStrengthenController ()

@end

@implementation NeckStrengthenController

UILabel *timeView;
UIImageView *view;
UILabel *description;
UIButton *previous;
UIButton *next;
UIButton *start;
UILabel *techPoint;

int position;
NSArray *picArray;
NSArray *textArray;
float timeThreshold2 = 5.0;

@synthesize ble;

- (void)viewDidLoad {
    [super viewDidLoad];
    dispathQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    position = 0;
    
    self.title = @"Neck Strengthen";
    // Do any additional setup after loading the view.
    
    picArray = [[NSArray alloc] initWithObjects:@"strengthen1", nil];
    textArray = [[NSArray alloc] initWithObjects:@"Start facing straight forwards and with your arms relaxed\n\nBring your chin down to meet your chest and up to meet your back\n\nRepeat the above action for five times", nil];
    // Do any additional setup after loading the view.
    
    view = [[UIImageView alloc] initWithFrame:CGRectMake(50, 100, 210, 210)];
    view.image = [UIImage imageNamed:[picArray objectAtIndex:position]];
    
    timeView = [[UILabel alloc] initWithFrame:CGRectMake(50, 70, 200, 30)];
    timeView.text = [NSString stringWithFormat:@"%.0f %@", timeThreshold2, @" times to next."];
    timeView.textAlignment = NSTextAlignmentCenter;
    
    techPoint = [[UILabel alloc] initWithFrame:CGRectMake(30, 310, 260, 170)];
    techPoint.text = textArray[position];
    techPoint.font = [UIFont systemFontOfSize:15];
    techPoint.numberOfLines = 0;
    
    description = [[UILabel alloc] initWithFrame:CGRectMake(50, 480, 200, 30)];
    description.text = [NSString stringWithFormat:@"%@ %d %@ %lu", @"Posture:", position + 1, @"/", (unsigned long)[picArray count]];
    description.textAlignment = NSTextAlignmentCenter;
    
    previous = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    previous.frame = CGRectMake(50, 510, 70, 30);
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
    next.frame = CGRectMake(200, 510, 70, 30);
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
    start.frame = CGRectMake(125, 510, 70, 30);
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
    [self.view addSubview:techPoint];
}

- (void) startPosture:(UIButton *)sender
{
    [self sendMessage];
}

- (void) nextPosture:(UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        if(position + 1 < [picArray count])
        {
            position++;
            dispatch_async(dispatch_get_main_queue(), ^(void){
                view.image = [UIImage imageNamed:[picArray objectAtIndex:position]];
                timeView.text = [NSString stringWithFormat:@"%.0f %@", timeThreshold2, @" times to next."];
                description.text = [NSString stringWithFormat:@"%@ %d %@ %lu", @"Posture:", position + 1, @"/", (unsigned long)[picArray count]];
                techPoint.text = textArray[position];
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
                techPoint.text = textArray[position];
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
    NSString *input = @"1";
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
    
    NSString *firstValue = [s substringToIndex:1];
    NSString *valueString = [s substringFromIndex:1];
    
    if([s compare:@"o"] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Movement Complete"
                                                        message:@"Movement Complete."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else if([firstValue compare:@"s"] == 0) {
        [self readMessage:valueString];
    }
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
        
        /*
        NSDate * date = [NSDate date];
        NSTimeInterval sec = [date timeIntervalSinceNow];
        NSDate * currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
        
        //设置时间输出格式：
        NSDateFormatter * df = [[NSDateFormatter alloc] init ];
        [df setDateFormat:@"HH:mm:ss:SSS"];
        NSString * na = [df stringFromDate:currentDate];
        */
        //NSLog(@"系统当前时间为：%@",na);
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [timeView setText:[NSString stringWithFormat:@"%.0f %@", timeThreshold2 - [s floatValue], @" times to next."]];
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
