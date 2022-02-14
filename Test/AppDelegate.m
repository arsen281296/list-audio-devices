//
//  AppDelegate.m
//  Test
//
//  Created by fulldev on 2/10/22.
//

#import "AppDelegate.h"
#import <CoreFoundation/CoreFoundation.h>
#import <CoreAudio/CoreAudio.h>

@interface AppDelegate ()


@end

@implementation AppDelegate {
    AudioDeviceID outAggregateDevice;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    OSStatus status = [self CreateAggregateDevice];
    NSLog(@"%d", (int)status);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    OSStatus status = [self DestroyAggregateDevice];
    NSLog(@"%d", (int)status);
}

- (OSStatus)CreateAggregateDevice {
    OSStatus osErr = noErr;
    UInt32 outSize;
    Boolean outWritable;

    //-----------------------
    // Start to create a new aggregate by getting the base audio hardware plugin
    //-----------------------

    osErr = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyPlugInForBundleID, &outSize, &outWritable);
    if (osErr != noErr) return osErr;

    AudioValueTranslation pluginAVT;

    CFStringRef inBundleRef = CFSTR("com.apple.audio.CoreAudio");
    AudioObjectID pluginID;

    pluginAVT.mInputData = &inBundleRef;
    pluginAVT.mInputDataSize = sizeof(inBundleRef);
    pluginAVT.mOutputData = &pluginID;
    pluginAVT.mOutputDataSize = sizeof(pluginID);

    osErr = AudioHardwareGetProperty(kAudioHardwarePropertyPlugInForBundleID, &outSize, &pluginAVT);
    if (osErr != noErr) return osErr;

    AudioObjectPropertyAddress pluginDevices;
    pluginDevices.mSelector = kAudioHardwarePropertyDevices;
    pluginDevices.mScope = kAudioObjectPropertyScopeGlobal;
    pluginDevices.mElement = kAudioObjectPropertyElementMaster;

    UInt32 propsize;

    osErr = AudioObjectGetPropertyDataSize((AudioObjectID)(kAudioObjectSystemObject), &pluginDevices, 0, NULL, &propsize);
    if (osErr != noErr) return osErr;
    
    UInt32 numDevices = (UInt32)(propsize / sizeof(AudioObjectID));
    AudioObjectID devids[numDevices];
    NSString* deviceUIDs[numDevices];
    osErr = AudioObjectGetPropertyData((AudioObjectID)(kAudioObjectSystemObject), &pluginDevices, 0, NULL, &propsize, &devids);
    if (osErr != noErr) return osErr;
    
    for (int i = 0; i < numDevices; i++) {
        NSLog(@"%u", (unsigned int)devids[i]);
        AudioObjectPropertyAddress address;
        address.mSelector = kAudioDevicePropertyDeviceUID;
        address.mScope = kAudioObjectPropertyScopeGlobal;
        address.mElement = kAudioObjectPropertyElementMaster;
        UInt32 propsize;
        NSString *uid, *name;

        osErr = AudioObjectGetPropertyData(devids[i], &address, 0, NULL, &propsize, &uid);
        deviceUIDs[i] = uid;

        address.mSelector = kAudioDevicePropertyDeviceNameCFString;
        address.mScope = kAudioObjectPropertyScopeGlobal;
        address.mElement = kAudioObjectPropertyElementMaster;

        osErr = AudioObjectGetPropertyData(devids[i], &address, 0, NULL, &propsize, &name);
        NSLog(@"%@, %@", uid, name);
        if (osErr != noErr) return osErr;
    }

    //-----------------------
    // Create a CFDictionary for our aggregate device
    //-----------------------

    CFMutableDictionaryRef aggDeviceDict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFStringRef AggregateDeviceNameRef = CFSTR("Crestron Wireless Conferencing Aggregate");
    CFStringRef AggregateDeviceUIDRef = CFSTR("com.Crestron.aggregate");

    // add the name of the device to the dictionary
    CFDictionaryAddValue(aggDeviceDict, CFSTR(kAudioAggregateDeviceNameKey), AggregateDeviceNameRef);

    // add our choice of UID for the aggregate device to the dictionary
    CFDictionaryAddValue(aggDeviceDict, CFSTR(kAudioAggregateDeviceUIDKey), AggregateDeviceUIDRef);

    //-----------------------
    // Create a CFMutableArray for our sub-device list
    //-----------------------

    // this example assumes that you already know the UID of the device to be added
    // you can find this for a given AudioDeviceID via AudioDeviceGetProperty for the kAudioDevicePropertyDeviceUID property
    // obviously the example deviceUID below won't actually work!
    CFStringRef deviceUID1 = (__bridge CFStringRef)deviceUIDs[0];
    CFStringRef deviceUID2 = (__bridge CFStringRef)deviceUIDs[3];

    // we need to append the UID for each device to a CFMutableArray, so create one here
    CFMutableArrayRef subDevicesArray = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);

    // just the one sub-device in this example, so append the sub-device's UID to the CFArray
    CFArrayAppendValue(subDevicesArray, deviceUID1);
    CFArrayAppendValue(subDevicesArray, deviceUID2);

    // if you need to add more than one sub-device, then keep calling CFArrayAppendValue here for the other sub-device UIDs

    //-----------------------
    // Feed the dictionary to the plugin, to create a blank aggregate device
    //-----------------------

    AudioObjectPropertyAddress pluginAOPA;
    pluginAOPA.mSelector = kAudioPlugInCreateAggregateDevice;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    UInt32 outDataSize;

    osErr = AudioObjectGetPropertyDataSize(pluginID, &pluginAOPA, 0, NULL, &outDataSize);
    if (osErr != noErr) return osErr;

    osErr = AudioObjectGetPropertyData(pluginID, &pluginAOPA, sizeof(aggDeviceDict), &aggDeviceDict, &outDataSize, &outAggregateDevice);
    if (osErr != noErr) return osErr;

    // pause for a bit to make sure that everything completed correctly
    // this is to work around a bug in the HAL where a new aggregate device seems to disappear briefly after it is created
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);

    //-----------------------
    // Set the sub-device list
    //-----------------------

    pluginAOPA.mSelector = kAudioAggregateDevicePropertyFullSubDeviceList;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    outDataSize = sizeof(CFMutableArrayRef);
    osErr = AudioObjectSetPropertyData(outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &subDevicesArray);
    if (osErr != noErr) return osErr;

    // pause again to give the changes time to take effect
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);

    //-----------------------
    // Set the master device
    //-----------------------

    // set the master device manually (this is the device which will act as the master clock for the aggregate device)
    // pass in the UID of the device you want to use
    pluginAOPA.mSelector = kAudioAggregateDevicePropertyMasterSubDevice;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    outDataSize = sizeof(deviceUID1);
    osErr = AudioObjectSetPropertyData(outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &deviceUID1);
    if (osErr != noErr) return osErr;

    // pause again to give the changes time to take effect
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);

    //-----------------------
    // Clean up
    //-----------------------

    // release the CF objects we have created - we don't need them any more
    CFRelease(aggDeviceDict);
    CFRelease(subDevicesArray);

    // release the device UID
    CFRelease(deviceUID1);
    CFRelease(deviceUID2);

    return noErr;

}

- (OSStatus)DestroyAggregateDevice {
    
    OSStatus osErr = noErr;

    //-----------------------
    // Start by getting the base audio hardware plugin
    //-----------------------

    UInt32 outSize;
    Boolean outWritable;
    osErr = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyPlugInForBundleID, &outSize, &outWritable);
    if (osErr != noErr) return osErr;

    AudioValueTranslation pluginAVT;

    CFStringRef inBundleRef = CFSTR("com.apple.audio.CoreAudio");
    AudioObjectID pluginID;

    pluginAVT.mInputData = &inBundleRef;
    pluginAVT.mInputDataSize = sizeof(inBundleRef);
    pluginAVT.mOutputData = &pluginID;
    pluginAVT.mOutputDataSize = sizeof(pluginID);

    osErr = AudioHardwareGetProperty(kAudioHardwarePropertyPlugInForBundleID, &outSize, &pluginAVT);
    if (osErr != noErr) return osErr;

    //-----------------------
    // Feed the AudioDeviceID to the plugin, to destroy the aggregate device
    //-----------------------

    AudioObjectPropertyAddress pluginAOPA;
    pluginAOPA.mSelector = kAudioPlugInDestroyAggregateDevice;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    UInt32 outDataSize;

    osErr = AudioObjectGetPropertyDataSize(pluginID, &pluginAOPA, 0, NULL, &outDataSize);
    if (osErr != noErr) return osErr;

    osErr = AudioObjectGetPropertyData(pluginID, &pluginAOPA, 0, NULL, &outDataSize, &outAggregateDevice);
    if (osErr != noErr) return osErr;

    return noErr;

}

@end
