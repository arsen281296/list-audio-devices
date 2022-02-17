//
//  AppDelegate.h
//  Test
//
//  Created by fulldev on 2/10/22.
//

#import <Cocoa/Cocoa.h>
#import "Utils.h"
#import <CoreAudio/CoreAudio.h>
#import <CoreFoundation/CoreFoundation.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
    @property (nonatomic) AudioDeviceID outAggregateDevice;
    @property (nonatomic) AudioDeviceID defaultDevice;

@end

