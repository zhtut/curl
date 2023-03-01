#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "stdcheaders.h"
#import "header.h"
#import "options.h"
#import "mprintf.h"
#import "easy.h"
#import "curl.h"
#import "websockets.h"
#import "curlver.h"
#import "system.h"
#import "typecheck-gcc.h"
#import "multi.h"
#import "urlapi.h"

FOUNDATION_EXPORT double curlVersionNumber;
FOUNDATION_EXPORT const unsigned char curlVersionString[];

