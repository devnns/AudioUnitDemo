//
//  AudioUnitPlayer.m
//  AudioUnitDemo
//
//  Created by devnn on 2023/3/26.
//

#import "AudioUnitPlayer.h"
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#define kInputBus 1
#define kOutputBus 0



typedef enum {
    STATE_INIT = 0,
    STATE_START,
    STATE_STOP
}AudioUnitPlayState;

@interface AudioUnitPlayer(){
    AVAudioSession *audioSession;
    AudioUnit remoteIOUnit;
    AURenderCallbackStruct inputProc;
    
}

@property (nonatomic, copy) NSString *filePath;
@property (atomic, assign)AudioUnitPlayState state;
@property (nonatomic, assign)FILE *pcmFile;;
@property (nonatomic, assign)int type;
@property (nonatomic, assign)BOOL loop;
@end

@implementation AudioUnitPlayer
- (instancetype)initWithType:(int)type{
    self=[super init];
    if(self){
        self.type=type;
    }
    return self;
}

#pragma mark - CallBack
static OSStatus PlayCallBack(
                             void                        *inRefCon,
                             AudioUnitRenderActionFlags     *ioActionFlags,
                             const AudioTimeStamp         *inTimeStamp,
                             UInt32                         inBusNumber,
                             UInt32                         inNumberFrames,
                             AudioBufferList             *ioData)
{
    AudioUnitPlayer *THIS=(__bridge AudioUnitPlayer*)inRefCon;
    
    NSInteger realLength = [THIS readPCMData:ioData->mBuffers[0].mData size:ioData->mBuffers[0].mDataByteSize];
    NSLog(@"PlayCallBack,realLength=%ld",realLength);
    
    if (realLength <= 0) {
        NSLog(@"PlayCallBack,播放完毕");
        if(THIS.loop){
            fclose(THIS.pcmFile);
            THIS.pcmFile=NULL;
        }else{
            [THIS stopPlay];//如果要循环播放，将此行注释，同时加上将以下两行
        }
       
    }
    return noErr;
    
}


- (void)startPlay:(NSString *)filePath loop:(BOOL)loop{
    self.filePath=filePath;
    self.loop = loop;
    [self InitUnitFlow];
    
}
- (void)stopPlay{
    [self audioUnitStop];
}


- (NSInteger)readPCMData:(char *)buffer size:(int)size {
    if (!self.pcmFile) {
        self.pcmFile = fopen(self.filePath.UTF8String, "r");
        //fread(buffer, 44, 1, pcmFile);//如果是wav文件需要加上这个
    }
    return fread(buffer, size, 1, self.pcmFile);
}


- (void)audioUnitStop{
    CheckError(AudioOutputUnitStop(remoteIOUnit),"couldn't AudioOutputUnitStop");
    //    CheckError(AudioUnitUninitialize(remoteIOUnit),"couldn't AudioUnitUninitialize");
    //    fclose(pcmFile);
    self.pcmFile=NULL;
    self.state = STATE_STOP;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playerDelegate playerDidStop:self.type];
    });
    
}
-(BOOL)isStarted{
    return self.state == STATE_START;
}

- (void)InitUnitFlow
{
    NSLog(@"InitUnitFlow");
    [self initAudioSession];
    [self initAudioUnit];
    [self setAudioFormat];
    [self setAudioCallBack];
    [self AudioUnitInitialize];
    [self audioUnitStart];
}

#pragma mark - AudioUnitInitMethod
- (void)initAudioSession {
    
}

-(void)initAudioUnit{
    //初始化audioUnit
    AudioComponentDescription outputDesc;
    outputDesc.componentType = kAudioUnitType_Output;
    outputDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDesc.componentFlags = 0;
    outputDesc.componentFlagsMask = 0;
    AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputDesc);
    AudioComponentInstanceNew(outputComponent, &remoteIOUnit);
    
    // Enable IO for playing（kAudioUnitScope_Input ==> recording）
    //     uint32_t flag = 1;
    //    OSStatus status = AudioUnitSetProperty(remoteIOUnit,
    //                                   kAudioOutputUnitProperty_EnableIO,
    //                                   kAudioUnitScope_Output, //【播放必定选kAudioUnitScope_Output!!!】
    //                                   0,
    //                                   &flag,
    //                                   sizeof(flag));
    //     CheckError(status,"kAudioOutputUnitProperty_EnableIO error");//若是负值则不通过；
    
    
}
-(void)setAudioFormat{
    
    
    //    size_t bytesPerSample = sizeof(AudioUnitSampleType);
    //    NSLog(@"bytesPerSample=%d",bytesPerSample);
    AudioStreamBasicDescription mAudioFormat;
    mAudioFormat.mSampleRate         = 16000;//采样率,要设置成音频文件的采样率
    mAudioFormat.mFormatID           = kAudioFormatLinearPCM;//PCM采样
    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mReserved           = 0;
    mAudioFormat.mChannelsPerFrame   = 1;//1单声道，2立体声，但是改为2也并不是立体声
    //    mAudioFormat.mBitsPerChannel     = 24;//语音每采样点占用位数
    mAudioFormat.mBitsPerChannel     = 16;//语音每采样点占用位数
    mAudioFormat.mFramesPerPacket    = 1;//每个数据包多少帧
    mAudioFormat.mBytesPerFrame      = (mAudioFormat.mBitsPerChannel / 8) * mAudioFormat.mChannelsPerFrame; // 每帧的bytes数
    mAudioFormat.mBytesPerPacket     = mAudioFormat.mFramesPerPacket*mAudioFormat.mBytesPerFrame;//每个数据包的bytes总数，每帧的bytes数＊每个数据包的帧数
    
    UInt32 size = sizeof(mAudioFormat);
    
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &mAudioFormat,
                                    size), "SetProperty StreamFormat failure");
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &mAudioFormat,
                                    size), "SetProperty StreamFormat failure");
    
}

-(void)setAudioCallBack{
    
    AURenderCallbackStruct outputCallBackStruct;
    outputCallBackStruct.inputProc = PlayCallBack;
    outputCallBackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    OSStatus status = AudioUnitSetProperty(remoteIOUnit,
                                           kAudioUnitProperty_SetRenderCallback,
                                           kAudioUnitScope_Input,
                                           kOutputBus,
                                           &outputCallBackStruct,
                                           sizeof(outputCallBackStruct));
    CheckError(status, "SetProperty EnableIO failure");
    
}



-(void)AudioUnitInitialize{
    CheckError(AudioUnitInitialize(remoteIOUnit),"AudioUnitInitialize error");
}

- (void)audioUnitStart {
    //    CheckError(AudioUnitInitialize(remoteIOUnit),"AudioUnitInitialize error");
    OSStatus status = AudioOutputUnitStart(remoteIOUnit);
    CheckError(status,"AudioOutputUnitStart error");
    self.state = STATE_START;
    [self.playerDelegate playerDidStart:self.type];
}


static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char str[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    exit(1);
    
}
@end
