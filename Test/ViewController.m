//
//  ViewController.m
//  Test
//
//  Created by fulldev on 2/10/22.
//

#import "ViewController.h"
#import "AppDelegate.h"

@implementation ViewController {
    AppDelegate *delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self->delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSLog(@"%u", (unsigned int)self->delegate.outAggregateDevice);
    // Do any additional setup after loading the view.
}

- (IBAction)onClickStart:(id)sender {
    CFStringRef deviceUID = (__bridge CFStringRef)@"CrestronDevice";

    CFMutableArrayRef subDevicesArray = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);

    CFArrayAppendValue(subDevicesArray, deviceUID);
    
    
    AudioObjectPropertyAddress pluginAOPA;
    UInt32 outDataSize;

    pluginAOPA.mSelector = kAudioAggregateDevicePropertyFullSubDeviceList;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    outDataSize = sizeof(CFMutableArrayRef);
    OSStatus status = AudioObjectSetPropertyData(self->delegate.outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &subDevicesArray);

    assertStatusSuccess(status);

    pluginAOPA.mSelector = kAudioAggregateDevicePropertyMasterSubDevice;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    outDataSize = sizeof(deviceUID);
    status = AudioObjectSetPropertyData(self->delegate.outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &deviceUID);

    assertStatusSuccess(status);

    CFRelease(subDevicesArray);
    CFRelease(deviceUID);
}

- (IBAction)onClickStop:(id)sender {
    NSString* uid = getStringProperty(self->delegate.defaultDevice, kAudioDevicePropertyDeviceUID);
    CFStringRef deviceUID = (__bridge CFStringRef)uid;

    CFMutableArrayRef subDevicesArray = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);

    CFArrayAppendValue(subDevicesArray, deviceUID);
    
    
    AudioObjectPropertyAddress pluginAOPA;
    UInt32 outDataSize;

    pluginAOPA.mSelector = kAudioAggregateDevicePropertyFullSubDeviceList;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    outDataSize = sizeof(CFMutableArrayRef);
    OSStatus status = AudioObjectSetPropertyData(self->delegate.outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &subDevicesArray);

    assertStatusSuccess(status);

    pluginAOPA.mSelector = kAudioAggregateDevicePropertyMasterSubDevice;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    outDataSize = sizeof(deviceUID);
    status = AudioObjectSetPropertyData(self->delegate.outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &deviceUID);

    assertStatusSuccess(status);

    CFRelease(subDevicesArray);
    CFRelease(deviceUID);
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
