//
//  FileFromPID.m
//  AirmouseMac
//
//  Created by Aniruddh Iyengar on 2/28/16.
//  Copyright © 2016 Topper Studios. All rights reserved.
//

#import "FileFromPID.h"

@implementation FileFromPID

- (NSString *)fileNameFromPID:(int)pid {
    
    NSTask *task1 = [NSTask new];
    [task1 setLaunchPath:@"/usr/bin/whoami"];
    
    NSPipe *outputPipe1 = [NSPipe pipe];
    [task1 setStandardOutput:outputPipe1];
    
    [task1 launch];
    [task1 waitUntilExit];
    
    NSData *outputData1 = [[outputPipe1 fileHandleForReading] readDataToEndOfFile];
    NSString *username = [[[NSString alloc] initWithData:outputData1 encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/usr/sbin/lsof"];
    [task setArguments:@[@"-p", [NSString stringWithFormat:@"%i", pid]]];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    
    [task launch];
    [task waitUntilExit];
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    NSArray *lines = [outputString componentsSeparatedByString:@"\n"];
    NSLog(@"%@", lines);
    
    NSString *fileName = @"NO";
    
    for (NSString *line in lines) {
        if ([line containsString:[NSString stringWithFormat:@"/Users/%@/", username]]) {

            if (![line containsString:[NSString stringWithFormat:@"/Users/%@/Library/", username]]) {
                
                int index = (int)[line rangeOfString:@"/Users"].location;
                fileName = [line substringFromIndex:(unsigned)index];
            }
        }
    }
    
    if ([fileName isEqualTo:@"NO"]) {
        NSLog(@"FUCKED UP");
        exit(1); //Something fucked up (or you dragged te wrong app)
    }
    else {
        return fileName;
    }
}

@end
