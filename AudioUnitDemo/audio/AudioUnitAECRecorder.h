//
//  AudioUnitRecorder.h
//  AudioUnitDemo
//
//  Created by m103002161 on 2023/3/26.
//

#import <Foundation/Foundation.h>
#import "RecorderDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioUnitAECRecorder : NSObject

@property(nonatomic,strong) id<AECRecorderDelegate> aecRecorderDelegate;
-(void)startRecord:(NSString *)filePath aecOn:(BOOL)aecOn;
-(void)stopRecord;
-(BOOL)isStated;
@end

NS_ASSUME_NONNULL_END
