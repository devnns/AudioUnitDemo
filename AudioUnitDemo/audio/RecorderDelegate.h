//
//  RecorderDelegate.h
//  AudioUnitDemo
//
//  Created by m103002161 on 2023/3/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RecorderDelegate <NSObject>
-(void)recorderDidStart;
-(void)recorderDidStop;
@end

@protocol AECRecorderDelegate <NSObject>
-(void)aecRecorderDidStart;
-(void)aecRecorderDidStop;
@end

NS_ASSUME_NONNULL_END
