//
//  ViewController.m
//  AudioUnitDemo
//
//  Created by m103002161 on 2023/3/26.
//

#import "ViewController.h"
#import "AudioUnitRecorder.h"
#import "AudioUnitPlayer.h"
#import "RecorderDelegate.h"
#import "PlayerDelegate.h"
#import "AudioUnitAECRecorder.h"
@interface ViewController ()<RecorderDelegate,AECRecorderDelegate,PlayerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnRecord;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnAECRecord;
@property (weak, nonatomic) IBOutlet UIButton *btnAECPlay;

@property(nonatomic,strong)AudioUnitRecorder *audioUnitRecorder;
@property(nonatomic,strong)AudioUnitAECRecorder *audioUnitAECRecorder;
@property(nonatomic,strong)AudioUnitPlayer *audioUnitPlayer;//播放没有原始录音
@property(nonatomic,strong)AudioUnitPlayer *audioUnitAECPlayer;//播放经过AEC的声音
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.audioUnitRecorder=[[AudioUnitRecorder alloc] init];
    self.audioUnitRecorder.recorderDelegate=self;
    self.audioUnitAECRecorder=[[AudioUnitAECRecorder alloc] init];
    self.audioUnitAECRecorder.aecRecorderDelegate=self;
    self.audioUnitPlayer = [[AudioUnitPlayer alloc] initWithType:1];
    self.audioUnitAECPlayer = [[AudioUnitPlayer alloc] initWithType:2];
    self.audioUnitPlayer.playerDelegate=self;
    self.audioUnitAECPlayer.playerDelegate=self;
}

//1.开始录音
- (IBAction)startRecord:(id)sender {
    if([self.audioUnitRecorder isStated]){
        [self.audioUnitRecorder stopRecord];
    }else{
        NSString *filePath = [self getVoiceFilePath];
        [self.audioUnitRecorder startRecord:filePath];
    }
    
}

//2.开始播放
- (IBAction)play:(id)sender {
    if(self.audioUnitPlayer.isStarted){
        [self.audioUnitPlayer stopPlay];
    }else{
        NSString *filePath = [self getVoiceFilePath];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if(fileExists){
            [self.audioUnitPlayer startPlay:filePath loop:true];
        }
       
    }
}

//3.播放+录制(开启AEC过滤人声)
- (IBAction)aecRecord:(id)sender {
    if([self.audioUnitRecorder isStated]){
        return;
    }
    if([self.audioUnitAECRecorder isStated]){
        [self.audioUnitAECRecorder stopRecord];
    }else{
        NSString *filePath = [self getAECVoiceFilePath];
        [self.audioUnitAECRecorder startRecord:filePath aecOn:true];
    }
}


//4.播放AEC之后的录音
- (IBAction)playAEC:(id)sender {
        if(self.audioUnitAECPlayer.isStarted){
            [self.audioUnitAECPlayer stopPlay];
        }else{
            NSString *filePath = [self getAECVoiceFilePath];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
            if(fileExists){
                [self.audioUnitAECPlayer startPlay:filePath loop:false];
            }
        }
}

- (void)recorderDidStart{
    [self.btnRecord setTitle:@"停止录音" forState:UIControlStateNormal];
}

- (void)recorderDidStop{
    [self.btnRecord setTitle:@"开始录音" forState:UIControlStateNormal];
}

//AEC录音已开始
- (void)aecRecorderDidStart{
    [self.btnAECRecord setTitle:@"停止" forState:UIControlStateNormal];
}

//AEC录音已停止
- (void)aecRecorderDidStop{
    [self.btnAECRecord setTitle:@"AEC录音" forState:UIControlStateNormal];
    
    if(self.audioUnitPlayer.isStarted){
        [self.audioUnitPlayer stopPlay];
    }
}

- (void)playerDidStart:(int)type{
    if(type==1){
        [self.btnPlay setTitle:@"停止播放" forState:UIControlStateNormal];
    }else if(type==2){
        [self.btnAECPlay setTitle:@"停止播放" forState:UIControlStateNormal];
    }
}

-(void)playerDidStop:(int)type{
    if(type==1){
        [self.btnPlay setTitle:@"开始播放" forState:UIControlStateNormal];
    }else if(type==2){
        [self.btnAECPlay setTitle:@"AEC播放" forState:UIControlStateNormal];
    }
}

-(NSString *)getVoiceFilePath{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"voice_record.pcm"];
}

-(NSString *)getAECVoiceFilePath{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"voice_record_aec.pcm"];
}

@end
