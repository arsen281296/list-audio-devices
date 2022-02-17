//
//  Utils.h
//  Test
//
//  Created by fulldev on 2/17/22.
//

#ifndef Utils_h
#define Utils_h
#import <CoreAudio/CoreAudio.h>
#import <CoreFoundation/CoreFoundation.h>

static char *codeToString(UInt32 code)
{
    static char str[5] = { '\0' };
    UInt32 swapped = CFSwapInt32HostToBig(code);
    memcpy(str, &swapped, sizeof(swapped));
    return str;
}

static void assertStatusSuccess(OSStatus status)
{
    if (status != noErr)
    {
        NSLog(@"Got error %u: '%s'\n", status, codeToString(status));
        abort();
    }
}

static UInt32 getChannelCount(AudioDeviceID deviceID, AudioObjectPropertyScope scope) {
    AudioObjectPropertyAddress address;
    address.mSelector = kAudioDevicePropertyDeviceUID;
    address.mScope = scope;
    address.mElement = kAudioObjectPropertyElementMaster;
    AudioBufferList streamConfiguration;
    UInt32 propsize = sizeof(streamConfiguration);

    OSStatus status = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &propsize, &streamConfiguration);
    assertStatusSuccess(status);

    UInt32 channelCount = 0;
    NSLog(@"mNumberBuffers %u", (unsigned int)streamConfiguration.mNumberBuffers);
    for (NSUInteger  i = 0; i < 1; i++)
    {
        NSLog(@"%u", (unsigned int)streamConfiguration.mBuffers[i].mNumberChannels);
        channelCount += streamConfiguration.mBuffers[i].mNumberChannels;
    }
    
    return channelCount;
}

static NSString *getStringProperty(AudioDeviceID deviceID, AudioObjectPropertySelector selector) {
    AudioObjectPropertyAddress address;
    address.mSelector = selector;
    address.mScope = kAudioObjectPropertyScopeGlobal;
    address.mElement = kAudioObjectPropertyElementMaster;

    CFStringRef prop;
    UInt32 propSize = sizeof(prop);
    OSStatus status = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &propSize, &prop);

    assertStatusSuccess(status);

    return (__bridge_transfer NSString *)prop;
}

#endif /* Utils_h */
