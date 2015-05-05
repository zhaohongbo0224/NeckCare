//
//  NeckStretchController.h
//  BLEController
//
//  Created by 赵鸿博 on 15-4-26.
//  Copyright (c) 2015年 RedBearLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBLProtocol.h"
#import "BLE.h"

@interface NeckStretchController : UIViewController
{
    dispatch_queue_t dispathQueue;
}

@property (strong, nonatomic) BLE *ble;
@property (strong, nonatomic) RBLProtocol *protocol;

-(void) processData:(uint8_t *) data length:(uint8_t) length;

@end
