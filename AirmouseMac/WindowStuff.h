//
//  WindowStuff.h
//  AirmouseMac
//
//  Created by anthony on 1/21/16.
//  Copyright © 2016 Topper Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface WindowStuff : NSObject
-(NSString *) getFrontWindowID;
-(BOOL) openWithID:(NSString *) ID;
@end
