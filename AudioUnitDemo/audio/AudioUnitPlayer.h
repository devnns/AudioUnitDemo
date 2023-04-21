//
//  AudioUnitPlayer.h
//  AudioUnitDemo
//
//  Created by m103002161 on 2023/3/26.
//

#import <Foundation/Foundation.h>
#import "PlayerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioUnitPlayer : NSObject

@property(nonatomic,strong) id<PlayerDelegate> playerDelegate;
-(instancetype)initWithType:(int)type;
-(void)startPlay:(NSString *)filePath loop:(BOOL)loop;
-(void)stopPlay;
-(BOOL)isStarted;
@end

NS_ASSUME_NONNULL_END
