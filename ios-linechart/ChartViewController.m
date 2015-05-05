//
//  ChartViewController.m
//  ios-linechart
//
//  Created by Marcel Ruegenberg on 02.08.13.
//  Copyright (c) 2013 Marcel Ruegenberg. All rights reserved.
//

#import "ChartViewController.h"
#import "LCLineChartView.h"
#import "Util.h"

int MODE = 0; //0: is the mode to show last items
int outputMODE = 1;

LCLineChartView *chartView;

@interface ChartViewController ()

@property (strong) NSDateFormatter *formatter;

@end

@implementation ChartViewController

#define SECS_PER_DAY (86400)

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispathQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    MODE = 0;
    outputMODE = 1;
    
    self.title = @"Show Curve";
    
    self.formatter = [[NSDateFormatter alloc] init];
    [self.formatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"yyyyMMMd" options:0 locale:[NSLocale currentLocale]]];
    
    chartView = [[LCLineChartView alloc] initWithFrame:CGRectMake(20, 150, self.view.bounds.size.width - 20 * 2, 200)];
    [self updateChart];
    
    UIButton *lastDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    lastDataButton.frame = CGRectMake(30, 400, 100, 30);
    //lastDataButton.titleLabel.text = @"Last Data";
    [lastDataButton setTitle:@"Last Data" forState:UIControlStateNormal];
    [lastDataButton addTarget:self
                   action:@selector(clickLastData:)
         forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *globalDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    globalDataButton.frame = CGRectMake(200, 400, 100, 30);
    //globalDataButton.titleLabel.text = @"Whole Data";
    [globalDataButton setTitle:@"Whole Data" forState:UIControlStateNormal];
    [globalDataButton addTarget:self
                       action:@selector(clickWholeData:)
             forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *xDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    xDataButton.frame = CGRectMake(30, 440, 100, 30);
    //lastDataButton.titleLabel.text = @"Last Data";
    [xDataButton setTitle:@"Show X" forState:UIControlStateNormal];
    [xDataButton addTarget:self
                       action:@selector(clickXData:)
             forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *yDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    yDataButton.frame = CGRectMake(115, 440, 100, 30);
    //lastDataButton.titleLabel.text = @"Last Data";
    [yDataButton setTitle:@"Show Y" forState:UIControlStateNormal];
    [yDataButton addTarget:self
                    action:@selector(clickYData:)
          forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *zDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    zDataButton.frame = CGRectMake(200, 440, 100, 30);
    //lastDataButton.titleLabel.text = @"Last Data";
    [zDataButton setTitle:@"Show Z" forState:UIControlStateNormal];
    [zDataButton addTarget:self
                    action:@selector(clickZData:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:chartView];
    [self.view addSubview:lastDataButton];
    [self.view addSubview:globalDataButton];
    [self.view addSubview:xDataButton];
    [self.view addSubview:yDataButton];
    [self.view addSubview:zDataButton];
}

- (void)clickXData: (UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        outputMODE = 0;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateChart];
        });
    });
}

- (void)clickYData: (UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        outputMODE = 1;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateChart];
        });
    });
}

- (void)clickZData: (UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        outputMODE = 2;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateChart];
        });
    });
}

- (void)clickLastData: (UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        MODE = 0;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateChart];
        });
    });
}

- (void)clickWholeData: (UIButton *)sender
{
    dispatch_async(dispathQueue, ^{
        MODE = 1;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateChart];
        });
    });
}

- (void)updateChart {
    LCLineChartData *d = [LCLineChartData new];
    d.xMin = 1;
    d.xMax = 31;
    d.title = @"The title for the legend";
    d.color = [UIColor redColor];
    
    int lastItem = 30;
    
    NSArray *dataArray;
    float minY;
    float maxY;
    
    if(outputMODE == 0) {
        dataArray = dataArrayX;
        minY = x_minY;
        maxY = x_maxY;
    }
    else if(outputMODE == 1) {
        dataArray = dataArrayY;
        minY = y_minY;
        maxY = y_maxY;
    }
    else {
        dataArray = dataArrayZ;
        minY = z_minY;
        maxY = z_maxY;
    }
    
    NSRange theRange;
    if([dataArray count] >= lastItem && MODE == 0)
    {
        theRange.location = [dataArray count] - lastItem;
        theRange.length = lastItem;
    }
    else
    {
        theRange.location = 0;
        theRange.length = [dataArray count];
    }
    NSArray *vals = [dataArray subarrayWithRange:theRange];
    
    if(MODE == 0)
    {
        float temp_min = 10000.0f;
        float temp_max = -10000.0f;
        for(int i = 0; i < [vals count]; i++)
        {
            temp_max = MAX(temp_max, [vals[i] floatValue]);
            temp_min = MIN(temp_min, [vals[i] floatValue]);
        }
        chartView.yMin = temp_min;
        chartView.yMax = temp_max;
    }
    else
    {
        chartView.yMin = minY;
        chartView.yMax = maxY;//powf(2, 31 / 7) + 0.5;
    }
    
    //NSMutableArray *vals = result;//[NSMutableArray new];
    d.itemCount = [vals count];
    //NSLog(@"COUNT: !!!!! %d", d.itemCount);
    /*
     for(NSUInteger i = 0; i < d.itemCount; ++i)
     [vals addObject:@(i)];
     [vals sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
     return [obj1 compare:obj2];
     }];
     */
    d.getData = ^(NSUInteger item) {
        float x = (d.xMax) * 1.0f / d.itemCount * item * 1.0f;
        float y = [vals[item] floatValue];//powf(2, x / 7);
        NSString *label1 = [NSString stringWithFormat:@"%lu", (unsigned long)item];
        NSString *label2 = [NSString stringWithFormat:@"%f", y];
        return [LCLineChartDataItem dataItemWithX:x y:y xLabel:label1 dataLabel:label2];
    };
    
    chartView.ySteps = @[[NSString stringWithFormat:@"%.02f", chartView.yMin],
                         [NSString stringWithFormat:@"%.02f", chartView.yMin + (chartView.yMax - chartView.yMin) / 5],
                         [NSString stringWithFormat:@"%.02f", chartView.yMin + (chartView.yMax - chartView.yMin) *2 / 5],
                         [NSString stringWithFormat:@"%.02f", chartView.yMin + (chartView.yMax - chartView.yMin) *3 / 5],
                         [NSString stringWithFormat:@"%.02f", chartView.yMin + (chartView.yMax - chartView.yMin) *4 / 5],
                         [NSString stringWithFormat:@"%.02f", chartView.yMax]];
    chartView.xStepsCount = 5;
    chartView.data = @[d];
    
    chartView.axisLabelColor = [UIColor blueColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self updateChart];
        });
    });
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        NSLog(@"back pressed!!!");
    }
    [super viewWillDisappear:animated];
}

@end
