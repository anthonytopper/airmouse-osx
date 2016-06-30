//
//  ViewController.h
//  AirmouseMac
//
//  Created by anthony on 1/15/16.
//  Copyright © 2016 Topper Studios. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BTManager.h"

@interface ViewController : NSViewController {
    double d;
    double x0;
    double z0;
    double thetaX0;
    double thetaZ0;
    
    double p11;
    double p12;
    double p13;
    double p21;
    double p22;
    double p23;
    double s11;
    double s21;
    double vx1;
    double vy1;
    double vz1;
    double s12;
    double s22;
    double vx2;
    double vy2;
    double vz2;
    double s13;
    double s23;
    double vx3;
    double vy3;
    double vz3;
    
    BOOL mouseDown;
    BOOL isCalibrating;
    BOOL isReleased;
    int calibrationCount;
    NSMutableArray *dPoints;
    NSMutableArray *sPoints;
    
    NSTimeInterval lastDown;
}
@property (weak) IBOutlet NSTextField *xLabel;
@property (weak) IBOutlet NSTextField *zLabel;
@property (nonatomic,retain) BTManager* manager;

@end

