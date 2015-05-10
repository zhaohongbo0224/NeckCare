
/*
 
 Copyright (c) 2013-2014 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "RBLControlViewController.h"
#import "CellPin.h"
#import "NeckExternalController.h"
#import "NeckStrengthenController.h"
#import "NeckStretchController.h"
#import "ChartViewController.h"
#import "Util.h"
#import <AVFoundation/AVFoundation.h>

uint8_t total_pin_count  = 0;
uint8_t pin_mode[128]    = {0};
uint8_t pin_cap[128]     = {0};
uint8_t pin_digital[128] = {0};
uint16_t pin_analog[128]  = {0};
uint8_t pin_pwm[128]     = {0};
uint8_t pin_servo[128]   = {0};

uint8_t init_done = 0;

@interface RBLControlViewController ()<UIGestureRecognizerDelegate>

@end

@implementation RBLControlViewController

UILabel *label;
UITextField *output;
UIButton *button;
UIButton *neckStretch;
UIButton *neckStengthen;
UIButton *neckExternal;
UIButton *showData;
UIButton *adjustData;

UIAlertView *alert;

NeckStrengthenController *neckStrengthController;
NeckStretchController *neckStretchController;
NeckExternalController *neckExternalController;
ChartViewController *chartViewController;

//NSNotificationCenter *center;

int alertCount = 0;
int alertCountThreshold = 2;
bool isNotified = false;

AVAudioPlayer *audioPlayer;

@synthesize ble;
@synthesize protocol;

//@synthesize soundFileURLRef;
//@synthesize soundFileObject;

/*
- (void)awakeFromNib
{
    [super awakeFromNib];
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    //[self sendMessage];
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    alertCount = 0;
    alertCountThreshold = 2;
    x_minY = 100000.0f;
    x_maxY = -100000.0f;
    y_minY = 100000.0f;
    y_maxY = -100000.0f;
    z_minY = 100000.0f;
    z_maxY = -100000.0f;
    dispathQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dataArrayX = [[NSMutableArray alloc] init];
    dataArrayY = [[NSMutableArray alloc] init];
    dataArrayZ = [[NSMutableArray alloc] init];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    view.backgroundColor = [UIColor whiteColor];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, self.view.bounds.size.width - 80, 30)];
    label.text = @"Read Text";
    
    output = [[UITextField alloc] initWithFrame:CGRectMake(50, 200, 100, 30)];
    [output setBorderStyle:UITextBorderStyleRoundedRect];
    [output setReturnKeyType:UIReturnKeyDone];
    output.delegate = self;
    output.text = @"";
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self
               action:@selector(sendMessageToBLE:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Send" forState:UIControlStateNormal];
    button.frame = CGRectMake(180.0, 200.0, 50.0, 30.0);
    
    NSLog(@"%f, %f", self.view.bounds.size.width, self.view.bounds.size.height);
    
    UITapGestureRecognizer *neckStretchRec = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleNeckStretchRec:)];
    neckStretch = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    neckStretch.frame = CGRectMake(50, 230, 120, 120);
    [neckStretch setBackgroundImage:[UIImage imageNamed:@"head1_on"] forState:UIControlStateNormal];
    //[neckStretch setBackgroundImage:[UIImage imageNamed:@"head1_on"] forState:UIControlStateHighlighted];
    neckStretchRec.numberOfTouchesRequired = 1; //手指数
    neckStretchRec.numberOfTapsRequired = 1; //tap次数
    neckStretchRec.delegate= self;
    neckStretch.userInteractionEnabled = YES;
    [neckStretch addGestureRecognizer:neckStretchRec];
    
    UITapGestureRecognizer *neckStengthenRec = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handleNeckStengthenRec:)];
    neckStengthen = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    neckStengthen.frame = CGRectMake(180, 230, 120, 120);
    [neckStengthen setBackgroundImage:[UIImage imageNamed:@"head2_on"] forState:UIControlStateNormal];
    //[neckStengthen setBackgroundImage:[UIImage imageNamed:@"head2_on"] forState:UIControlStateHighlighted];
    neckStengthenRec.numberOfTouchesRequired = 1; //手指数
    neckStengthenRec.numberOfTapsRequired = 1; //tap次数
    neckStengthenRec.delegate= self;
    neckStengthen.userInteractionEnabled = YES;
    [neckStengthen addGestureRecognizer:neckStengthenRec];
    
    UITapGestureRecognizer *neckExternalRec = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(handleNeckExternalRec:)];
    neckExternal = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    neckExternal.frame = CGRectMake(50, 370, 120, 120);
    [neckExternal setBackgroundImage:[UIImage imageNamed:@"head3_on"] forState:UIControlStateNormal];
    //[neckExternal setBackgroundImage:[UIImage imageNamed:@"head3_on"] forState:UIControlStateHighlighted];
    neckExternalRec.numberOfTouchesRequired = 1; //手指数
    neckExternalRec.numberOfTapsRequired = 1; //tap次数
    neckExternalRec.delegate= self;
    neckExternal.userInteractionEnabled = YES;
    [neckExternal addGestureRecognizer:neckExternalRec];
    
    UITapGestureRecognizer *showDataRec = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleShowDataRec:)];
    showData = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //showData.frame = CGRectMake(190, 370, 100, 30);
    showData.frame = CGRectMake(0, 400, self.view.bounds.size.width, 30);
    [showData setTitle:@"Show Data" forState:UIControlStateNormal];
    showDataRec.numberOfTouchesRequired = 1; //手指数
    showDataRec.numberOfTapsRequired = 1; //tap次数
    showDataRec.delegate= self;
    showData.userInteractionEnabled = YES;
    [showData addGestureRecognizer:showDataRec];
    
    UITapGestureRecognizer *adjustDataRec = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handleAdjustDataRec:)];
    adjustData = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    adjustData.frame = CGRectMake(0, 130, self.view.bounds.size.width, 30);
    [adjustData setTitle:@"Adjust Data" forState:UIControlStateNormal];
    adjustDataRec.numberOfTouchesRequired = 1; //手指数
    adjustDataRec.numberOfTapsRequired = 1; //tap次数
    adjustDataRec.delegate= self;
    adjustData.userInteractionEnabled = YES;
    [adjustData addGestureRecognizer:adjustDataRec];
    
    [self.view addSubview: view];
    //[self.view addSubview:label];
    //[self.view addSubview:output];
    //[self.view addSubview:button];
    [self.view addSubview:neckStretch];
    [self.view addSubview:neckStengthen];
    //[self.view addSubview:neckExternal];
    [self.view addSubview:showData];
    [self.view addSubview:adjustData];
    
    //center = [NSNotificationCenter defaultCenter];
    //[center addObserver:self selector:@selector(GetInfo:) name:@"logInfo" object:nil];
    
    /*
    UIImage *temp = [[UIImage imageNamed:@"title.png"] imageWithRenderingMode: UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithImage:temp style:UIBarButtonItemStyleBordered target:self action:@selector(action)];
    self.navigationItem.leftBarButtonItem = barButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    */
    
    protocol = [[RBLProtocol alloc] init];
    protocol.delegate = self;
    protocol.ble = ble;
    
    NSLog(@"ControlView: viewDidLoad");
    
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"hello" ofType:@"aiff"];
    NSError* error = nil;
    NSURL *url = [[NSURL alloc] initWithString:soundPath];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
}

- (void)handleAdjustDataRec:(UITapGestureRecognizer *)sender
{
    int pos = 6;
    NSString *input = [NSString stringWithFormat:@"%d", pos];
    if([input length] > 0)
    {
        dispatch_async(dispathQueue, ^{
            
            //uint8_t *data;
            //NSUInteger length = [input length];
            //NSData *output = [NSData dataWithBytes:data length:length];
            NSData *output2 = [input dataUsingEncoding:NSUTF8StringEncoding];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [ble write:output2];
                
                alert = [[UIAlertView alloc] initWithTitle:@"Start Adjustment"
                                                   message:nil
                                                  delegate:nil
                                         cancelButtonTitle:nil//@"OK"
                                         otherButtonTitles:nil];
                [alert show];
            });
        });
    }
}

- (void)handleShowDataRec:(UITapGestureRecognizer *)sender
{
    chartViewController = [[ChartViewController alloc] init];
    chartViewController.view.backgroundColor = [UIColor whiteColor];
    chartViewController.ble = ble;
    [self.navigationController pushViewController:chartViewController animated:YES];
}

- (void)handleNeckStretchRec:(UITapGestureRecognizer *)sender
{
    NSLog(@"CLICK!!!!!");
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NeckStretch"
                                                    message:@"NeckStretch"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    //neckStretch.image = [UIImage imageNamed:@"head1_on"];
    neckStretch.highlighted = YES;
    neckStretchController = [[NeckStretchController alloc] init];
    neckStretchController.view.backgroundColor = [UIColor whiteColor];
    neckStretchController.ble = ble;
    [self.navigationController pushViewController:neckStretchController animated:YES];
}

- (void)handleNeckStengthenRec:(UITapGestureRecognizer *)sender
{
    NSLog(@"CLICK!!!!!");
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NeckStengthen"
                                                    message:@"NeckStengthen"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    //neckStengthen.image = [UIImage imageNamed:@"head2_on"];
    neckStrengthController = [[NeckStrengthenController alloc] init];
    neckStrengthController.view.backgroundColor = [UIColor whiteColor];
    neckStrengthController.ble = ble;
    [self.navigationController pushViewController:neckStrengthController animated:YES];
}

- (void)handleNeckExternalRec:(UITapGestureRecognizer *)sender
{
    NSLog(@"CLICK!!!!!");
    /*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"NeckExternal"
                                                    message:@"NeckExternal"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
     */
    //neckExternal.image = [UIImage imageNamed:@"head3_on"];
    neckExternalController = [[NeckExternalController alloc] init];
    neckExternalController.view.backgroundColor = [UIColor whiteColor];
    neckExternalController.ble = ble;
    [self.navigationController pushViewController:neckExternalController animated:YES];
}


- (void) sendMessage
{
    NSString *input = output.text;
    if([input length] > 0)
    {
        dispatch_async(dispathQueue, ^{
            
            //uint8_t *data;
            //NSUInteger length = [input length];
            //NSData *output = [NSData dataWithBytes:data length:length];
            NSData *output2 = [input dataUsingEncoding:NSUTF8StringEncoding];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [ble write:output2];
                output.text = @"";
            });
        });
    }
}

- (void) sendMessageToBLE:(UIButton *)sender
{
    [self sendMessage];
}

NSTimer *syncTimer;

-(void) syncTimeout:(NSTimer *)timer
{
    /*
    NSLog(@"Timeout: no response");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"No response from the BLE Controller sketch."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    // disconnect it
    [ble.CM cancelPeripheralConnection:ble.activePeripheral];
     */
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"ControlView: viewDidAppear");
    
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(syncTimeout:) userInfo:nil repeats:NO];

    [protocol queryProtocolVersion];
}

-(void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"ControlView: viewDidDisappear");

    total_pin_count = 0;
    //[tv reloadData];
    
    init_done = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStopClicked:(id)sender
{
    NSLog(@"Button Stop Clicked");
    
    [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
}

-(void) GetInfo:(NSNotification *) notificaion{
    //取得接受数据并打印
    NSString *data = [notificaion object];
    NSLog(@">> %@",data);
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
            //[label setText:[s stringByAppendingString:na]];
            //count++;
        });
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [alertView cancelButtonIndex]){
        //cancel clicked ...do your action
        alertCount = 0;
        NSLog(@"CANCEL");
        [alert dismissWithClickedButtonIndex:alert.cancelButtonIndex animated:YES];
    }else{
        //reset clicked
    }
}

- (void) notify
{
    dispatch_async(dispathQueue, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = @"Bad Posture Detected...";
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            
            [audioPlayer play];
        });
    });
}

- (void) notifyExercise
{
    dispatch_async(dispathQueue, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = @"Please Do Exercise...";
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            
            alert = [[UIAlertView alloc] initWithTitle:@"Please Do Exercise"
                                                            message:@"Please Do Exercise."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        });
    });
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    /*
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"51huapao"
                              message:@"推送测试信息－－didReceiveLocalNotification"
                              delegate:self
                              cancelButtonTitle:@"关闭"
                              otherButtonTitles:nil, nil];
    [alertView show];
     */
}

-(void) processData:(uint8_t *) data length:(uint8_t) length
{

    NSLog(@"ControlView: processData");
    //NSLog(@"Length: %d", length);
    
    NSData *d = [NSData dataWithBytes:data length:length];
    //_myData = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"Datos en String %@",s);
    
    if([s compare:@"a"] == 0) {
        alertCount++;
        
        [self notify];
        
        if(alertCount == alertCountThreshold) {
            [self notifyExercise];
            //alertCount = 0;
        }
    }
    else if([s compare:@"f"] == 0) {
        [dataArrayX removeAllObjects];
        [dataArrayY removeAllObjects];
        [dataArrayZ removeAllObjects];
        
        x_minY = 100000.0f;
        x_maxY = -100000.0f;
        y_minY = 100000.0f;
        y_maxY = -100000.0f;
        z_minY = 100000.0f;
        z_maxY = -100000.0f;
        
        [alert setTitle:@"Adjustment Complete"];
        //[alert setMessage:@"Please press OK to continue."];
        //sleep(1);
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    }
    else
    {
        [self readMessage:s];
        
        NSString *firstValue = [s substringToIndex:1];
        NSString *valueString = [s substringFromIndex:1];
        
        if([firstValue compare:@"x"] == 0) {
            [dataArrayX addObject:valueString];
            float val = [valueString floatValue];
            x_maxY = MAX(x_maxY, val);
            x_minY = MIN(x_minY, val);
        }
        else if([firstValue compare:@"y"] == 0) {
            [dataArrayY addObject:valueString];
            float val = [valueString floatValue];
            y_maxY = MAX(y_maxY, val);
            y_minY = MIN(y_minY, val);
        }
        else if([firstValue compare:@"z"] == 0){
            [dataArrayZ addObject:valueString];
            float val = [valueString floatValue];
            z_maxY = MAX(z_maxY, val);
            z_minY = MIN(z_minY, val);
        }
        
        //NSLog(@"DATA LEN: %lu", (unsigned long)[dataArray count]);
        
        if(neckStrengthController.ble != nil){
            [neckStrengthController processData:data length:length];
        }
        if(neckStretchController.ble != nil){
            [neckStretchController processData:data length:length];
        }
        if(neckExternalController.ble != nil){
            [neckExternalController processData:data length:length];
        }
        if(chartViewController.ble != nil){
            [chartViewController processData:data length:length];
        }
    }
    //[protocol parseData:data length:length];
    
    //send message to BLE
    //UInt8 buf[] = {0x04, 0x00, 0x00};
    //NSData *output = [NSData dataWithBytes:data length:length];
    //[ble write:output];
}

-(void) protocolDidReceiveProtocolVersion:(uint8_t)major Minor:(uint8_t)minor Bugfix:(uint8_t)bugfix
{
    NSLog(@"protocolDidReceiveProtocolVersion: %d.%d.%d", major, minor, bugfix);
    
    // get response, so stop timer
    [syncTimer invalidate];
    
    uint8_t buf[] = {'B', 'L', 'E'};
    [protocol sendCustomData:buf Length:3];
    
    [protocol queryTotalPinCount];
}

-(void) protocolDidReceiveTotalPinCount:(UInt8) count
{
    NSLog(@"protocolDidReceiveTotalPinCount: %d", count);
    
    total_pin_count = count;
    [protocol queryPinAll];
}

-(void) protocolDidReceivePinCapability:(uint8_t)pin Value:(uint8_t)value
{
    NSLog(@"protocolDidReceivePinCapability");
    NSLog(@" Pin %d Capability: 0x%02X", pin, value);
    
    if (value == 0)
        NSLog(@" - Nothing");
    else
    {
        if (value & PIN_CAPABILITY_DIGITAL)
            NSLog(@" - DIGITAL (I/O)");
        if (value & PIN_CAPABILITY_ANALOG)
            NSLog(@" - ANALOG");
        if (value & PIN_CAPABILITY_PWM)
            NSLog(@" - PWM");
        if (value & PIN_CAPABILITY_SERVO)
            NSLog(@" - SERVO");
    }
    
    pin_cap[pin] = value;
}

-(void) protocolDidReceivePinData:(uint8_t)pin Mode:(uint8_t)mode Value:(uint8_t)value
{
//    NSLog(@"protocolDidReceiveDigitalData");
//    NSLog(@" Pin: %d, mode: %d, value: %d", pin, mode, value);
    
    uint8_t _mode = mode & 0x0F;
    
    pin_mode[pin] = _mode;
    if ((_mode == INPUT) || (_mode == OUTPUT))
        pin_digital[pin] = value;
    else if (_mode == ANALOG)
        pin_analog[pin] = ((mode >> 4) << 8) + value;
    else if (_mode == PWM)
        pin_pwm[pin] = value;
    else if (_mode == SERVO)
        pin_servo[pin] = value;
    
    //[tv reloadData];
}

-(void) protocolDidReceivePinMode:(uint8_t)pin Mode:(uint8_t)mode
{
    NSLog(@"protocolDidReceivePinMode");
    
    if (mode == INPUT)
        NSLog(@" Pin %d Mode: INPUT", pin);
    else if (mode == OUTPUT)
        NSLog(@" Pin %d Mode: OUTPUT", pin);
    else if (mode == PWM)
        NSLog(@" Pin %d Mode: PWM", pin);
    else if (mode == SERVO)
        NSLog(@" Pin %d Mode: SERVO", pin);
    
    pin_mode[pin] = mode;
    //[tv reloadData];
}

-(void) protocolDidReceiveCustomData:(UInt8 *)data length:(UInt8)length
{
    // Handle your customer data here.
    for (int i = 0; i< length; i++)
    {
        printf("0x%2X ", data[i]);
    }
    printf("\n");
}

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    uint8_t pin = indexPath.row;
    
    if (pin_cap[pin] == PIN_CAPABILITY_NONE)
        return 0;
    
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return total_pin_count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"cell_pin";
    uint8_t pin = indexPath.row;
    
    CellPin *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell.lblPin setText:[NSString stringWithFormat:@"%d", pin]];
    [cell.btnMode setTag:pin];
    [cell.sgmHL setTag:pin];
    [cell.sldPWM setTag:pin];
    
    // Pin availability
    if (pin_cap[pin] == 0x00)
        [cell setHidden:TRUE];
    
    // Pin mode
    if (pin_mode[pin] == INPUT)
    {
        [cell.btnMode setTitle:@"Input" forState:UIControlStateNormal];
        [cell.sgmHL setHidden:FALSE];
        [cell.sgmHL setEnabled:FALSE];
        [cell.sgmHL setSelectedSegmentIndex:pin_digital[pin]];
        [cell.lblAnalog setHidden:TRUE];
        [cell.sldPWM setHidden:TRUE];
    }
    else if (pin_mode[pin] == OUTPUT)
    {
        [cell.btnMode setTitle:@"Output" forState:UIControlStateNormal];
        [cell.sgmHL setHidden:FALSE];
        [cell.sgmHL setEnabled:TRUE];
        [cell.sgmHL setSelectedSegmentIndex:pin_digital[pin]];
        [cell.lblAnalog setHidden:TRUE];
        [cell.sgmHL setHidden:FALSE];
        [cell.sldPWM setHidden:TRUE];
    }
    else if (pin_mode[pin] == ANALOG)
    {
        [cell.btnMode setTitle:@"Analog" forState:UIControlStateNormal];
        [cell.lblAnalog setText:[NSString stringWithFormat:@"%d", pin_analog[pin]]];
        [cell.lblAnalog setHidden:FALSE];
        [cell.sgmHL setHidden:TRUE];
        [cell.sldPWM setHidden:TRUE];
    }
    else if (pin_mode[pin] == PWM)
    {
        [cell.btnMode setTitle:@"PWM" forState:UIControlStateNormal];
        [cell.lblAnalog setText:[NSString stringWithFormat:@"%d", pin_analog[pin]]];
        [cell.sldPWM setHidden:FALSE];
        [cell.lblAnalog setHidden:TRUE];
        [cell.sgmHL setHidden:TRUE];
        [cell.sldPWM setMinimumValue:0];
        [cell.sldPWM setMaximumValue:255];
        [cell.sldPWM setValue:pin_pwm[pin]];
    }
    else if (pin_mode[pin] == SERVO)
    {
        [cell.btnMode setTitle:@"Servo" forState:UIControlStateNormal];
        [cell.lblAnalog setText:[NSString stringWithFormat:@"%d", pin_analog[pin]]];
        [cell.sldPWM setHidden:FALSE];
        [cell.lblAnalog setHidden:TRUE];
        [cell.sgmHL setHidden:TRUE];
        [cell.sldPWM setMinimumValue:0];
        [cell.sldPWM setMaximumValue:180];
        [cell.sldPWM setValue:pin_servo[pin]];
    }
    
    return cell;
}

- (IBAction)toggleHL:(id)sender
{
    NSLog(@"High/Low clicked, pin id: %d", [sender tag]);
    
    uint8_t pin = [sender tag];
    UISegmentedControl *sgmControl = (UISegmentedControl *) sender;
    if ([sgmControl selectedSegmentIndex] == LOW)
    {
        [protocol digitalWrite:pin Value:LOW];
        pin_digital[pin] = LOW;
    }
    else
    {
        [protocol digitalWrite:pin Value:HIGH];
        pin_digital[pin] = HIGH;
    }
}
*/

uint8_t current_pin = 0;

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"actionSheet button clicked, pin id: %d", buttonIndex);
    NSLog(@"title: %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
    
    NSString *mode_str = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([mode_str isEqualToString:@"Input"])
    {
        [protocol setPinMode:current_pin Mode:INPUT];
    }
    else if ([mode_str isEqualToString:@"Output"])
    {
        [protocol setPinMode:current_pin Mode:OUTPUT];
    }
    else if ([mode_str isEqualToString:@"Analog"])
    {
        [protocol setPinMode:current_pin Mode:ANALOG];
    }
    else if ([mode_str isEqualToString:@"PWM"])
    {
        [protocol setPinMode:current_pin Mode:PWM];
    }
    else if ([mode_str isEqualToString:@"Servo"])
    {
        [protocol setPinMode:current_pin Mode:SERVO];
    }
}
/*
- (IBAction)modeChange:(id)sender
{
    uint8_t pin = [sender tag];
    NSLog(@"Mode button clicked, pin id: %d", pin);
    
    NSString *title = [NSString stringWithFormat:@"Select Pin %d Mode", pin];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:title
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    
    if (pin_cap[pin] & PIN_CAPABILITY_DIGITAL)
    {
        [sheet addButtonWithTitle:@"Input"];
        [sheet addButtonWithTitle:@"Output"];
    }
    
    if (pin_cap[pin] & PIN_CAPABILITY_PWM)
        [sheet addButtonWithTitle:@"PWM"];
    
    if (pin_cap[pin] & PIN_CAPABILITY_SERVO)
        [sheet addButtonWithTitle:@"Servo"];
    
    if (pin_cap[pin] & PIN_CAPABILITY_ANALOG)
        [sheet addButtonWithTitle:@"Analog"];
    
    sheet.cancelButtonIndex = [sheet addButtonWithTitle: @"Cancel"];
    
    current_pin = pin;
    
    // Show the sheet
    [sheet showInView:self.view];
}

- (IBAction)sliderChange:(id)sender
{
    uint8_t pin = [sender tag];
    UISlider *sld = (UISlider *) sender;
    uint8_t value = sld.value;
    
    if (pin_mode[pin] == PWM)
        pin_pwm[pin] = value; // for updating the GUI
    else
        pin_servo[pin] = value;
}

- (IBAction)sliderTouchUp:(id)sender
{
    uint8_t pin = [sender tag];
    UISlider *sld = (UISlider *) sender;
    uint8_t value = sld.value;
    NSLog(@"Slider, pin id: %d, value: %d", pin, value);
    
    if (pin_mode[pin] == PWM)
    {
        pin_pwm[pin] = value;
        [protocol analogWrite:pin Value:value];
    }
    else
    {
        pin_servo[pin] = value;
        [protocol servoWrite:pin Value:value];
    }
}
*/
@end
