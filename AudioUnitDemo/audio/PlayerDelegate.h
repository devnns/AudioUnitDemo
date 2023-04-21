//
//  PlayerDelegate.h
//  AudioUnitDemo
//
//  Created by m103002161 on 2023/3/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PlayerDelegate <NSObject>
-(void)playerDidStart:(int)type;
-(void)playerDidStop:(int)type;
@end

NS_ASSUME_NONNULL_END
