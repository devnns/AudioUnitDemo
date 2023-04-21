//
//  AudioUnitRecorder.h
//  AudioUnitDemo
//
//  Created by m103002161 on 2023/3/26.
//

#import <Foundation/Foundation.h>
#import "RecorderDelegate.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * 不带AEC的录音
 */
@interface AudioUnitRecorder : NSObject

@property(nonatomic,strong) id<RecorderDelegate> recorderDelegate;
-(void)startRecord:(NSString *)filePath;
-(void)stopRecord;
-(BOOL)isStated;
@end

NS_ASSUME_NONNULL_END
