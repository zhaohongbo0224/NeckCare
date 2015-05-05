//
//  ChartViewController.h
//  ios-linechart
//
//  Created by Marcel Ruegenberg on 02.08.13.
//  Copyright (c) 2013 Marcel Ruegenberg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"
#import "RBLProtocol.h"

@interface ChartViewController : UIViewController
{
    //IBOutlet UIView *tv;
    dispatch_queue_t dispathQueue;
}

@property (strong, nonatomic) BLE *ble;
@property (strong, nonatomic) RBLProtocol *protocol;

-(void) processData:(uint8_t *) data length:(uint8_t) length;

@end