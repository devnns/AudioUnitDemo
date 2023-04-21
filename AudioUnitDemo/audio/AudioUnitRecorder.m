//
//  AudioUnitRecorder.m
//  AudioUnitDemo
//
//  Created by devnn on 2023/3/26.
//

#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIApplication.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioUnitRecorder.h"
#import "RecorderDelegate.h"
#import "CommonDefine.h"


@interface AudioUnitRecorder(){
    AUNode remoteIONode;
    AudioUnit remoteIOUnit;
    AudioStreamBasicDescription mAudioFormat;
}
@property(nonatomic,assign) RecordState state;
@property(nonatomic,copy) NSString *originAudioSessionCategory;
@property(nonatomic,copy) NSString *filePath;
@property(nonatomic,assign) FILE *file;
@end

@implementation AudioUnitRecorder

-(id)init{
    self = [super init];
    if(self){
        self.file = NULL;
       
    }
    return self;
}


/**
 录制回调
 */
OSStatus AudioInputCallback(void *inRefCon,
                            AudioUnitRenderActionFlags *ioActionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber,
                            UInt32 inNumberFrames,
                            AudioBufferList *__nullable ioData) {
//    NSLog(@"AudioInputCallback");
    AudioUnitRecorder *recorder = (__bridge AudioUnitRecorder *)inRefCon;
    
    AudioBuffer buffer;
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    UInt32 size = inNumberFrames * recorder->mAudioFormat.mBytesPerFrame;
    buffer.mDataByteSize = size; // sample size
    buffer.mNumberChannels = 1; // one channel
    buffer.mData = malloc(size); // buffer size
    
    // we put our buffer into a bufferlist array for rendering
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status = noErr;
    
    status = AudioUnitRender(recorder->remoteIOUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList);

    if (status != noErr) {
        printf("AudioUnitRender %d \n", (int)status);
        return status;
    }

    [recorder writePCMData:buffer.mData size:buffer.mDataByteSize];
    free(buffer.mData);
    return status;
}


- (void)startRecord:(NSString *)filePath{
    self.filePath = filePath;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL allow){
            if(allow){
                NSLog(@"已经拥有麦克风权限");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self realStart];
                });
            }else{
                // no permission
                NSLog(@"没有麦克风权限");
            }
        }];
    }
  
}

-(void)realStart{
    [self initAudioSession];
    [self initAudioUnit];
    [self initFormat];
    [self initInputCallBack];
    [self startRecord];
}




- (void)writePCMData:(char *)buffer size:(int)size {
    if (!self.file) {
        self.file = fopen(self.filePath.UTF8String, "w");
    }
    fwrite(buffer, size, 1, self.file);
}


-(void)initAudioSession{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    self.originAudioSessionCategory = audioSession.category;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setPreferredIOBufferDuration:0.02 error:nil];
    [audioSession setActive:YES error:nil];

}


/**
 初始化AudioUnit
 */
-(void)initAudioUnit{
    AudioComponentDescription componentDesc;
    componentDesc.componentType = kAudioUnitType_Output;
    componentDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0;
    
    AudioComponent audioCompnent = AudioComponentFindNext(NULL, &componentDesc);
    OSStatus status = AudioComponentInstanceNew(audioCompnent, &remoteIOUnit);
    CheckError(status, "创建unit失败");
    
    UInt32 enableFlag = 1;
    UInt32 unableFlag = 0;
    
    //关闭音频输出(默认是开启的)
    //    CheckError(AudioUnitSetProperty(remoteIOUnit,
    //                                    kAudioOutputUnitProperty_EnableIO,
    //                                    kAudioUnitScope_Output,
    //                                    0,
    //                                    &unableFlag,
//                                        sizeof(unableFlag)),
    //               "Open output of bus 0 failed");
    //    CheckError(AudioUnitSetProperty(remoteIOUnit,
    //                                        kAudioOutputUnitProperty_EnableIO,
    //                                        kAudioUnitScope_Output,
    //                                        0,
    //                                        &enableFlag,
    //                                        sizeof(enableFlag)),
    //                   "Open output of bus 0 failed");
    //开启麦克风
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    1,
                                    &enableFlag,
                                    sizeof(enableFlag)),
               "Open input of bus 1 failed");
    
}

/**
 音频参数
 */
-(void)initFormat{
    
    //Set up stream format for input and output
    //AudioStreamBasicDescription
    
    mAudioFormat.mSampleRate = 16000;
    mAudioFormat.mFormatID = kAudioFormatLinearPCM;
    mAudioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mReserved = 0;
    mAudioFormat.mChannelsPerFrame = 1;
    mAudioFormat.mBitsPerChannel = 16;
    mAudioFormat.mFramesPerPacket = 1;
    mAudioFormat.mBytesPerFrame = (mAudioFormat.mBitsPerChannel / 8) * mAudioFormat.mChannelsPerFrame; // 每帧的bytes数2
    mAudioFormat.mBytesPerPacket =  mAudioFormat.mFramesPerPacket*mAudioFormat.mBytesPerFrame;//每个包的字节数2
    
    UInt32 size = sizeof(mAudioFormat);
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    1,
                                    &mAudioFormat,
                                    size),
               "kAudioUnitProperty_StreamFormat of bus 1 failed");
    
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &mAudioFormat,
                                    size),
               "kAudioUnitProperty_StreamFormat of bus 0 failed");
    //    UInt32 turnOff = 0;
    //    CheckError(AudioUnitSetProperty(remoteIOUnit,
    //                                    kAUVoiceIOProperty_VoiceProcessingEnableAGC,
    //                                    kAudioUnitScope_Global,
    //                                    1,
    //                                    &turnOff,sizeof(turnOff)),"VoiceProcessingEnableAGC error");
    
}


/**
 音频输入回调:录音
 */
- (void)initInputCallBack {
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = AudioInputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    OSStatus status = AudioUnitSetProperty(remoteIOUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Output, 0, &callbackStruct, sizeof(callbackStruct));
    CheckError(status, "设置采集回调失败");
}



-(void)startRecord{
    CheckError(AudioUnitInitialize(remoteIOUnit),"AudioUnitInitialize error");
    OSStatus status = AudioOutputUnitStart(remoteIOUnit);
    CheckError(status,"AudioOutputUnitStart error");
    if(status==0){
        self.state=STATE_START;
        [self.recorderDelegate recorderDidStart];
    }
}

- (void)stopRecord{
    NSLog(@"audio,record stop");
    if(self.state == STATE_STOP){
        NSLog(@"audio,in recorder stop, state has stopped!");
        return;
    }
    
    AudioOutputUnitStop(remoteIOUnit);
    
//    AudioUnitUninitialize(remoteIOUnit);
    
    AudioComponentInstanceDispose(remoteIOUnit);
    
    
    [[AVAudioSession sharedInstance] setCategory:self.originAudioSessionCategory error:nil];
    
    self.state = STATE_STOP;
    
    self.file=NULL;
    
    [self.recorderDelegate recorderDidStop];
    
    //    [self audioUnitStopPlay];
}


-(void)dealloc{
//    [self _unregisterForBackgroundNotifications];
    
//    [self stop:NO];
    
//    self.originCategory=nil;
    
}

- (NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

-(BOOL)isStated{
    return self.state==STATE_START;
}


@end
