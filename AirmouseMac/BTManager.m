//
//  BTManager.m
//  Airmouse
//
//  Created by anthony on 1/15/16.
//  Copyright © 2016 Topper Studios. All rights reserved.
//

#import "BTManager.h"

@implementation BTManager

static NSString *BL_UUID = @"63cebf9f-421d-47e4-ad6e-9a66aa0b341c";
static NSString *BL_CHAR_UUID = @"abfa3eec-92ad-4e28-bce4-976bab515044";

#define SERVICE_TYPE @"abcdef"
#define DOUBLE_SIZE (sizeof(double))
#define INT_SIZE (sizeof(int))

//-(void) start {
//    NSArray *s = @[[CBUUID UUIDWithString:BL_UUID]];
//    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
//    [self.manager scanForPeripheralsWithServices:s options:nil];
//}
//
//-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
//    // 2
//    
//    [peripheral setDelegate:self];
//    [peripheral discoverServices:@[[CBUUID UUIDWithString:BL_UUID]]];
//}
//
//-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
//    
//    // 1
//    [self.manager connectPeripheral:peripheral options:nil];
//    [self.manager stopScan];
//    self.peripheral = peripheral;
//    self.peripheral.delegate = self;
//    
//    NSLog(@"didDiscoverPeripheral %@",self.peripheral);
//    
//}
//
//-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
//    NSLog(@"centralManagerDidUpdateState %d",central.state);
//}
//
//-(void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
//    NSLog(@"ERROR?? %@",error);
//}
//
//
//
//-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
//    for (CBService *s in peripheral.services) {
//        [peripheral discoverCharacteristics:nil forService:s];
//    }
//}
//-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
//    if (![service.UUID isEqual:[CBUUID UUIDWithString:BL_UUID]]) return;
//    for (CBCharacteristic *c in service.characteristics) {
//        if ([c.UUID isEqual:[CBUUID UUIDWithString:BL_CHAR_UUID]]) {
//            [self.peripheral setNotifyValue:YES forCharacteristic:c];
//        }
//    }
//}
//-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    
//    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:BL_CHAR_UUID]]) return;
//    
//    double x;
//    double z;
//    
//    NSData *data = characteristic.value;
//    [data getBytes:&x range:NSMakeRange(0, 4)];
//    [data getBytes:&z range:NSMakeRange(4, 4)];
//    
//    NSLog(@"BLT: %f, %f",x,z);
//    
//    if (callback != NULL) callback(x,z);
//}


-(void) setCallback:(BTManagerCallback) cb {
    callback = cb;
}

-(MCBrowserViewController *) start {
    ID = [[NSUUID UUID] UUIDString];
    
    peers = @[].mutableCopy;
    
    self.peer = [[MCPeerID alloc] initWithDisplayName:@"3D Mouse Connector"];
    self.session = [[MCSession alloc] initWithPeer:self.peer securityIdentity:nil encryptionPreference:MCEncryptionNone];
    self.session.delegate = self;
    
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peer serviceType:SERVICE_TYPE];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];

    NSLog(@"Started");
    
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peer discoveryInfo:nil serviceType:SERVICE_TYPE];
    [self.advertiser startAdvertisingPeer];
    self.advertiser.delegate = self;
    

    
    return nil;
}

-(void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"didNotStartAdvertisingPeer %@",error);
}

-(void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nonnull))invitationHandler {
//    self.session = [[MCSession alloc] initWithPeer:[[MCPeerID alloc] initWithDisplayName:@"Arab the sat"]];
//    self.session.delegate = self;
    invitationHandler(YES,self.session);
    NSLog(@"didReceiveInvitationFromPeer %@ %@",peerID,self.session);
    [self.advertiser stopAdvertisingPeer];
}

-(void) browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissController:browserViewController];
}
-(void) browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [browserViewController dismissController:browserViewController];
}

-(void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info {
    NSLog(@"foundPeer %@",peerID);
    [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:-1]; // IMPORTANT
    [peers addObject:peerID];
}

-(void) browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"lostPeer %@",peerID);
}

-(void) browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"didNotStartBrowsingForPeers %@",error);
    
}

-(void) openProcess:(NSString *)pName {
    
    NSMutableData *data = [NSMutableData data];
    
    int flag = 1;
    const char *pString = pName.cString;
    const int pStringLen = pName.cStringLength;
    
    [data appendData:[NSData dataWithBytes:&flag length:INT_SIZE]];
    [data appendData:[NSData dataWithBytes:&pStringLen length:INT_SIZE]];
    [data appendData:[NSData dataWithBytes:pString length:pStringLen]];
    
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
}

-(void) session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID   {
//    NSLog(@"didReceiveData %@",data);
    double x;
    double y;
    double z;
    int c;
    int r;
    int click;
    int action;
    
    int hasPath;
    
    int pathLength;
    char pathString [256];

    int idlen;
    char idString [128];
    
    [data getBytes:&x range:NSMakeRange(0, DOUBLE_SIZE)];
    [data getBytes:&y range:NSMakeRange(DOUBLE_SIZE, DOUBLE_SIZE)];
    [data getBytes:&z range:NSMakeRange(DOUBLE_SIZE * 2, DOUBLE_SIZE)];
    [data getBytes:&c range:NSMakeRange(DOUBLE_SIZE * 3, INT_SIZE)];
    [data getBytes:&r range:NSMakeRange(DOUBLE_SIZE * 3 + INT_SIZE, INT_SIZE)];
    [data getBytes:&click range:NSMakeRange(DOUBLE_SIZE * 3 + INT_SIZE * 2, INT_SIZE)];
    [data getBytes:&action range:NSMakeRange(DOUBLE_SIZE * 3 + INT_SIZE * 3, INT_SIZE)];
    [data getBytes:&hasPath range:NSMakeRange(DOUBLE_SIZE * 3 + INT_SIZE * 4, INT_SIZE)];

    if (hasPath) {
        [data getBytes:&pathLength range:NSMakeRange(DOUBLE_SIZE * 3 + INT_SIZE * 5, INT_SIZE)];
        [data getBytes:&pathString range:NSMakeRange(DOUBLE_SIZE * 3 + INT_SIZE * 6, pathLength)];
    }
    
    
    NSString *path;
    if (hasPath) path = [NSString stringWithCString:pathString encoding:NSUTF8StringEncoding];
    
//    NSLog(@"BLT: %f, %f",x,z);

    if (callback != NULL) callback(x,y,z,c? YES: NO,r?YES:NO,click,action,path);
}

-(void) session:(MCSession *)session didStartReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID withProgress:(nonnull NSProgress *)progress {
    NSLog(@"didStartReceivingResourceWithName %@ %@",resourceName,peerID);
}

-(void) session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"didChangeState %ldl",(long)state);
}
- (void) session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    NSLog(@"didReceiveCertificate %@, %@, %@",session, certificate, peerID);
    certificateHandler(YES);
}

-(void) session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    NSLog(@"didReceiveStream %@ %@ %@",stream,streamName,peerID);
}

-(void) session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

//-(void) start {
//    if (self.session == nil) {
//        //create peer picker and show picker of connections
//        GKPeerPickerController *peerPicker = [[GKPeerPickerController alloc] init];
//        peerPicker.delegate = self;
//        peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
//        [peerPicker show];
//    }
//}
//
//-(GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type {
//    GKSession *session = [[GKSession alloc] initWithSessionID:BL_UUID displayName:nil sessionMode:GKSessionModePeer];
//    return session;
//}
//
//-(void) peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
//    session.delegate = self;
//    self.session = session;
//    picker.delegate = nil;
//    [picker dismiss];
//}
//
//- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
//{
//    if (state == GKPeerStateConnected){
//        [session setDataReceiveHandler:self withContext:nil]; //set ViewController to receive data
//    }
//    else {
//        self.session.delegate = nil;
//        self.session = nil; //allow session to reconnect if it gets disconnected
//    }
//}


@end










