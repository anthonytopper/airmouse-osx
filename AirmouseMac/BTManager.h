//
//  BTManager.h
//  Airmouse
//
//  Created by anthony on 1/15/16.
//  Copyright © 2016 Topper Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <CoreBluetooth/CoreBluetooth.h>
//#import <GameKit/GameKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef void(^BTManagerCallback)(double,double,double,BOOL,BOOL,int,int,NSString*);

@interface BTManager : NSObject<MCBrowserViewControllerDelegate,MCNearbyServiceBrowserDelegate,MCNearbyServiceAdvertiserDelegate,MCSessionDelegate> {
    BTManagerCallback callback;
    NSMutableArray *peers;
    NSString *ID;
}
@property (nonatomic,retain) MCPeerID *peer;
@property (nonatomic,retain) MCSession *session;
@property (nonatomic,retain) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic,retain) MCNearbyServiceBrowser *browser;
//@property (nonatomic,retain) CBCentralManager *manager;
//@property (nonatomic,retain) CBPeripheral *peripheral;

-(MCBrowserViewController *) start;
-(void) setCallback:(BTManagerCallback) cb;
-(void) openProcess:(NSString *) pName;
@end
