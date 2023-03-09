//
//  DLog.h
//  FERN
//
//  Added by Hopp, Dan on 3/9/23.
//  From EosEADataEnt development kit.

#ifndef DLog_h // added from file creation
#define DLog_h // added from file creation

#ifndef GPS_Demo_DLog_h
#define GPS_Demo_DLog_h

#ifdef DEBUG
    #warning Log enabled !
    #define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
    #define DLog(fmt, ...)
#endif

#endif /* DLog_h */ // added from file creation
