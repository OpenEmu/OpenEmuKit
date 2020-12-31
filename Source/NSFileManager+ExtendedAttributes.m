//
//  NSFileManager+ExtendedAttributes.m
//
//  Created by Jesús A. Álvarez on 2008-12-17.
//  Updated by Stuart Carnie on 2020-12-31.
//  Copyright 2008-2009 namedfork.net. All rights reserved.
//

#import "NSFileManager+ExtendedAttributes.h"
#import <string.h>

NSString * const XAFinderInfo = @XATTR_FINDERINFO_NAME;
NSString * const XAFinderComment = @"com.apple.metadata:kMDItemFinderComment";
NSString * const XAResourceFork = @XATTR_RESOURCEFORK_NAME;

@implementation NSFileManager (ExtendedAttributes)

- (NSArray<NSString *> *)extendedAttributeNamesOfItemAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err
{
    int flags = follow ? 0 : XATTR_NOFOLLOW;
    
    // get size of name list
    ssize_t nameBuffLen = listxattr([path fileSystemRepresentation], NULL, 0, flags);
    if (nameBuffLen == -1)
    {
        if (err) {
            NSDictionary *userInfo = @{
                @"error": [NSString stringWithUTF8String:strerror(errno)],
                @"function": @"listxattr",
                @":path": path,
                @":traverseLink": @(follow),
            };
            *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
        }
        return nil;
    }
    else if (nameBuffLen == 0)
    {
        return [NSArray array];
    }
    
    // get name list
    NSMutableData *nameBuff = [NSMutableData dataWithLength:nameBuffLen];
    listxattr([path fileSystemRepresentation], [nameBuff mutableBytes], nameBuffLen, flags);
    
    // convert to array
    NSMutableArray * names = [NSMutableArray arrayWithCapacity:5];
    char *nextName, *endOfNames = [nameBuff mutableBytes] + nameBuffLen;
    for(nextName = [nameBuff mutableBytes]; nextName < endOfNames; nextName += 1+strlen(nextName))
    [names addObject:[NSString stringWithUTF8String:nextName]];
    return [NSArray arrayWithArray:names];
}

- (BOOL)hasExtendedAttribute:(NSString *)name atPath:(NSString *)path traverseLink:(BOOL)follow result:(BOOL *)result error:(NSError **)err
{
    int flags = follow ? 0 : XATTR_NOFOLLOW;
    ssize_t attrLen = getxattr([path fileSystemRepresentation], [name UTF8String], NULL, 0, 0, flags);
    if (attrLen == -1)
    {
        switch (errno)
        {
        case ENOATTR:
            *result = NO;
            return YES;
            
        default:
            if (err) {
                NSDictionary *userInfo = @{
                    @"error": [NSString stringWithUTF8String:strerror(errno)],
                    @"function": @"getxattr",
                    @":path": path,
                    @":traverseLink": @(follow),
                };
                *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
            }
            return NO;
        }
    }
    
    *result = YES;
    
    return YES;
}

- (NSData *)extendedAttribute:(NSString *)name atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err
{
    int flags = follow ? 0 : XATTR_NOFOLLOW;
    ssize_t attrLen = getxattr([path fileSystemRepresentation], [name UTF8String], NULL, 0, 0, flags);
    if (attrLen == -1)
    {
        if (err)
        {
            NSDictionary *userInfo = @{
                @"error": [NSString stringWithUTF8String:strerror(errno)],
                @"function": @"getxattr",
                @":name": name,
                @":path": path,
                @":traverseLink": @(follow),
            };
            *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
        }
        return nil;
    }
    
    NSMutableData *attrData = [NSMutableData dataWithLength:attrLen];
    getxattr([path fileSystemRepresentation], [name UTF8String], [attrData mutableBytes], attrLen, 0, flags);
    return attrData;
}

- (NSDictionary <NSString *, NSData *> *)extendedAttributesOfItemAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err
{
    NSArray<NSString *> *names = [self extendedAttributeNamesOfItemAtPath:path traverseLink:follow error:err];
    if (names == nil)
    {
        return nil;
    }
    
    NSMutableDictionary<NSString *, NSData *> *attrs = [NSMutableDictionary dictionaryWithCapacity:[names count]];
    for(NSString *name in names) if (![name isEqualToString:XAResourceFork]) {
        NSData *attr = [self extendedAttribute:name atPath:path traverseLink:follow error:err];
        if (attr == nil)
        {
            return nil;
        }
        [attrs setObject:attr forKey:name];
    }
    
    return [NSDictionary dictionaryWithDictionary:attrs];
}

- (BOOL)setExtendedAttribute:(NSString *)name value:(NSData *)value atPath:(NSString *)path traverseLink:(BOOL)follow mode:(XAMode)mode error:(NSError **)err
{
    int flags = (follow ? 0 : XATTR_NOFOLLOW) | (int)mode;
    if (setxattr([path fileSystemRepresentation], [name UTF8String], [value bytes], [value length], 0, flags) == 0)
    {
        return YES;
    }
    
    if (err)
    {
        NSDictionary *userInfo = @{
            @"error": [NSString stringWithUTF8String:strerror(errno)],
            @"function": @"setxattr",
            @":value.length": @([value length]),
            @":path": path,
            @":traverseLink": @(follow),
            @":mode": @(mode),
        };
        *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
    }
    return NO;
}

- (BOOL)removeExtendedAttribute:(NSString *)name atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err {
    int flags = (follow ? 0 : XATTR_NOFOLLOW);
    if (removexattr([path fileSystemRepresentation], [name UTF8String], flags) == 0)
    {
        return YES;
    }
    
    if (err)
    {
        NSDictionary *userInfo = @{
            @"error": [NSString stringWithUTF8String:strerror(errno)],
            @"function": @"removexattr",
            @":name": name,
            @":path": path,
            @":traverseLink": @(follow),
        };
        *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
    }
    return NO;
}

- (BOOL)setExtendedAttributes:(NSDictionary<NSString *, NSData *> *)attrs atPath:(NSString *)path traverseLink:(BOOL)follow replace:(BOOL)replace error:(NSError **)err
{
    NSArray<NSString *> *oldNames = [self extendedAttributeNamesOfItemAtPath:path traverseLink:follow error:err];
    if (oldNames == nil)
    {
        return NO;
    }
    NSArray<NSString *> *newNames = [attrs allKeys];
    BOOL success = YES;
    
    // remove attributes
    if (replace)
    {
        NSMutableSet *attrsToRemove = [NSMutableSet setWithArray:oldNames];
        [attrsToRemove minusSet:[NSSet setWithArray:newNames]];
        [attrsToRemove removeObject:XAResourceFork];
        for (NSString *name in attrsToRemove)
        {
            if ([self removeExtendedAttribute:name atPath:path traverseLink:follow error:err] == NO)
            {
                success = NO;
            }
        }
        
        if (success == NO)
        {
            return NO;
        }
    }
    
    // set attributes
    for (NSString * name in newNames)
    {
        if ([self setExtendedAttribute:name value:attrs[name] atPath:path traverseLink:follow mode:XAModeAny error:err] == NO)
        {
            success = NO;
        }
    }
    
    return success;
}

@end
