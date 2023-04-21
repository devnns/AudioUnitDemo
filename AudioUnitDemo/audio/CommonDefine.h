//
//  CommonDefine.h
//  AudioUnitDemo
//
//  Created by m103002161 on 2023/4/15.
//

#ifndef CommonDefine_h
#define CommonDefine_h
typedef enum {
    STATE_INIT = 0,
    STATE_START,
    STATE_STOP
}RecordState;

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

#endif /* CommonDefine_h */
