//
//  ViewController.m
//  AirmouseMac
//
//  Created by anthony on 1/15/16.
//  Copyright © 2016 Topper Studios. All rights reserved.
//

#import "ViewController.h"
#import "FileFromPID.h"

@interface MMPoint : NSObject
@property (nonatomic) double x;
@property (nonatomic) double z;
@end
@implementation MMPoint
@end



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dPoints = [NSMutableArray array];
    sPoints = [NSMutableArray array];
    
    s11 = 0;
    s21 = 0;
    
    s12 = 500;
    s22 = 0;
    
    s13 = 500;
    s23 = 500;
    
    
    
    // Do any additional setup after loading the view.
}

-(void) viewDidAppear {
    NSLog(@"viewDidAppear");
    self.manager = [[BTManager alloc] init];
    [self.manager start];
    
    NSLog(@"self.manaer: %@",self.manager);
//    [self presentViewController:[manager start] asPopoverRelativeToRect:NSMakeRect(0, 0, 200, 200) ofView:self.view preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorSemitransient];

    // click = -1 if not clicking
    [self.manager setCallback:^(double x, double y, double z, BOOL c , BOOL r, int click, int action, NSString *path){
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.xLabel setStringValue:[NSString stringWithFormat:@"%.3f",x]];

            if (r) isReleased = !isReleased;
            
            if (isReleased) return;
            
            if (c) {
                if (!isCalibrating) {
                    isCalibrating = YES;
                    calibrationCount = 0;
                }
                [self nextCalibrationWithDX:x DY:y DZ:z];
            }
            
            if (isCalibrating) return;
            
            // TODO FIX THE BULL
//            double screenX = tanh(asinh(x) - thetaX0) * d + x0;
//            double screenZ = tanh(asinh(z) - thetaZ0) * d + z0;
            
            double screenX = p11*x + p12*y + p13*z + 3200;
            double screenZ = p21*x + p22*y + p23*z;
            
            [self.zLabel setStringValue:[NSString stringWithFormat:@"%.3f, %.3f, %d, %d",screenX,screenZ,click,action]];
            
            [self setX:screenX Z:screenZ];
            
            if (click >= 0 && action >= 0) {
                [self clickAtX:screenX Z:screenZ type:click action:action];
            }
            if (mouseDown && ([NSDate dateWithTimeIntervalSinceNow:0].timeIntervalSince1970 - lastDown) > 0.35f) {
                [self clickAtX:screenX Z:screenZ type:click action:kCGEventLeftMouseDragged];
            }
            
            if (path && ![path isEqualToString:[self topAppPath]]) { // ?
                [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:path options:0 additionalEventParamDescriptor:nil launchIdentifier:nil];
            }
            
        });
    }];
}

-(NSString *) topAppPath {
    return [[NSWorkspace sharedWorkspace] frontmostApplication].bundleIdentifier;
}
-(int) topAppID {
    return [[NSWorkspace sharedWorkspace] frontmostApplication].processIdentifier;
}

-(void) setX:(double) x Z:(double) z {
    self.xLabel.frame = CGRectMake(x,z,self.xLabel.frame.size.width,self.xLabel.frame.size.height);
//    NSLog(@"CGError: %d",e);
    
    
    
    NSScreen *screen = [NSScreen mainScreen];
    NSDictionary *description = [screen deviceDescription];
    NSSize displayPixelSize = [[description objectForKey:NSDeviceSize] sizeValue];
    
    if ((x < 0 || (x > displayPixelSize.width)) && mouseDown) {
        [self.manager openProcess:[self topAppPath]];
        FileFromPID *file = [FileFromPID new];
        NSString *path = [file fileNameFromPID:[self topAppID]];
    } else {
        CGError e = CGDisplayMoveCursorToPoint(CGMainDisplayID(),CGPointMake(x, 1000.0f-z));
    }
    
}

-(void) clickAtX:(double) x Z:(double) z type:(CGMouseButton) type action:(CGEventType) action {
    NSLog(@"%d,%d",type,action);
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, action, CGPointMake(x,1000.0f-z), type);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
    if (action == kCGEventLeftMouseDown || action == kCGEventRightMouseDown) {
        mouseDown = YES;
        lastDown = [NSDate dateWithTimeIntervalSinceNow:0].timeIntervalSince1970;
    }
    if (action == kCGEventLeftMouseUp || action == kCGEventRightMouseUp) mouseDown = NO;
    
    
    
}

-(void) nextCalibrationWithDX:(double) dx DY:(double) dy DZ:(double) dz {
    
    if (calibrationCount > 3) {
        isCalibrating = NO;
        return;
    }
    
    switch (calibrationCount) {
        case 0:
//            thetaX0 = asinh(dx);
//            thetaZ0 = asinh(dz);
            [self setX:s11 Z:s21];
            break;
            
        case 1:
            [self setX:s12 Z:s22];
            vx1 = dx;
            vy1 = dy;
            vz1 = dz;
            break;
            
        case 2:
            [self setX:s13 Z:s23];
            vx2 = dx;
            vy2 = dy;
            vz2 = dz;
            break;
            
        case 3:
            vx3 = dx;
            vy3 = dy;
            vz3 = dz;
            [self completeCalibration];
            
        default:
            break;
    }
    
    calibrationCount++;
    
    return;
    
    MMPoint *sp = [MMPoint new];
    sp.x = self.xLabel.frame.origin.x;
    sp.z = self.xLabel.frame.origin.y;
    [sPoints addObject:sp];
    
    MMPoint *dp = [MMPoint new];
    dp.x = dx;
    dp.z = dz;
    [dPoints addObject:dp];
    
    
    [self calibrate];
    
    
}

-(void) completeCalibration {
    p11 = (s11*(vy3*vz2-vy2*vz3)+vy1*(s12*vz3-s13*vz2) +(s13*vy2-s12*vy3)*vz1) /(vx1*(vy3*vz2-vy2*vz3)+vy1*(vx2*vz3-vx3*vz2) +(vx3*vy2-vx2*vy3)*vz1);
    p12 = -(s11*(vx3*vz2-vx2*vz3)+vx1*(s12*vz3-s13*vz2) +(s13*vx2-s12*vx3)*vz1) /(vx1*(vy3*vz2-vy2*vz3)+vy1*(vx2*vz3-vx3*vz2) +(vx3*vy2-vx2*vy3)*vz1);
    p13 = (s11*(vx3* vy2-vx2* vy3)+vx1*(s12 *vy3-s13* vy2) +(s13* vx2-s12* vx3)* vy1) /(vx1*(vy3 *vz2-vy2 *vz3)+vy1*(vx2 *vz3-vx3 *vz2) +(vx3 *vy2-vx2 *vy3) *vz1);
    p21 = (s21*(vy3* vz2-vy2* vz3)+vy1*(s22 *vz3-s23* vz2) +(s23* vy2-s22* vy3)* vz1) /(vx1*(vy3 *vz2-vy2 *vz3)+vy1*(vx2 *vz3-vx3 *vz2) +(vx3 *vy2-vx2 *vy3) *vz1);
    p22 = -(s21*(vx3* vz2-vx2* vz3)+vx1*(s22 *vz3-s23* vz2) +(s23* vx2-s22* vx3)* vz1) /(vx1*(vy3 *vz2-vy2 *vz3)+vy1*(vx2 *vz3-vx3 *vz2) +(vx3 *vy2-vx2 *vy3) *vz1);
    p23 = (s21*(vx3* vy2-vx2* vy3)+vx1*(s22 *vy3-s23* vy2) +(s23* vx2-s22* vx3)* vy1) /(vx1*(vy3 *vz2-vy2 *vz3)+vy1*(vx2 *vz3-vx3 *vz2) +(vx3 *vy2-vx2 *vy3) *vz1);
}

-(void) calibrate {
    if (dPoints.count < 2 || sPoints.count < 2) return;
    
    d = [self distanceDeviceReading:dPoints[dPoints.count - 2] to:dPoints[dPoints.count - 1] screen:sPoints[sPoints.count - 2] to:sPoints[sPoints.count - 1]];
    
    MMPoint *offset = [self offsetDeviceReading:dPoints[dPoints.count - 2] screen:sPoints[sPoints.count - 2] distance:d];
    x0 = offset.x;
    z0 = offset.z;
    // ?????
    
    NSLog(@"%f, %f, %f",d,x0,z0);
    
}

-(double) distanceDeviceReading:(MMPoint *) from to:(MMPoint *) to screen:(MMPoint *) sfrom to:(MMPoint *) sto {
    double thetaX1 = asinh(from.x) - thetaX0;
    double thetaZ1 = asinh(from.z) - thetaZ0;
    
    double thetaX2 = asinh(to.x) - thetaX0;
    double thetaZ2 = asinh(to.z) - thetaZ0;
    
    double deltaHX = sto.x - sfrom.x;
    double deltaHZ = sto.z - sfrom.z;
    
    double dX = fabs(deltaHX / (tanh(thetaX2) - tanh(thetaX1)));
    double dZ = fabs(deltaHZ / (tanh(thetaZ2) - tanh(thetaZ1)));
    
    return (dX + dZ) / 2.0f;
}

-(MMPoint *) offsetDeviceReading:(MMPoint *) from screen:(MMPoint *) sfrom distance:(double) dist {
    double thetaX = asinh(from.x) - thetaX0;
    double thetaZ = asinh(from.z) - thetaZ0;
    
    double hX = dist * tanh(thetaX);
    double hZ = dist * tanh(thetaZ);
    
    MMPoint *result = [MMPoint new];
    result.x = sfrom.x - hX;
    result.z = sfrom.z - hZ;
    
    return result;
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
