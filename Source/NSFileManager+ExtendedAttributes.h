//
//  NSFileManager+ExtendedAttributes.h
//
//  Created by Jesús A. Álvarez on 2008-12-17.
//  Updated by Stuart Carnie on 2020-12-31.
//  Copyright 2008-2009 namedfork.net. All rights reserved.
//

@import Foundation;
#import <sys/xattr.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const XAFinderInfo;
extern NSString * const XAFinderComment;
extern NSString * const XAResourceFork;

/// Specifies the semantics for setting an attribute value.
typedef NS_ENUM(NSInteger, XAMode) {
    /// Set the value, whether it exists or not.
    XAModeAny = 0,
    
    /// Set the value and fail if the attribute exists.
    XAModeCreate = XATTR_CREATE,
    
    /// Set the value and fail if the attribute does not exist.
    XAModeReplace = XATTR_REPLACE,
};

@interface NSFileManager (ExtendedAttributes)

/// Returns the extended attribute names for the item at the given path.
/// @param path The path of a file or directory.
/// @param follow Specify `true` to follow symbolic links.
/// @param err On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
/// @returns An array containing the names of the extended attributes at the given path.
- (nullable NSArray<NSString *> *)extendedAttributeNamesOfItemAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err;


/// Returns a boolean value that indicates whether the given path has an extended attribute of the given name.
/// @param name The name of the extended attribute.
/// @param path The path of a file or directory.
/// @param follow Specify `true` to follow symbolic links.
/// @param result A value indicating whether the given path has the extended attribute.
/// @param err On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
- (BOOL)hasExtendedAttribute:(NSString *)name atPath:(NSString *)path traverseLink:(BOOL)follow result:(out BOOL *)result error:(NSError **)err NS_REFINED_FOR_SWIFT;

/// Returns the data for the extended attribute at the given path.
/// @param name The name of the extended attribute.
/// @param path The path of a file or directory.
/// @param follow Specify `true` to follow symbolic links.
/// @param err On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
/// @returns The value of the extended attribute.
- (nullable NSData *)extendedAttribute:(NSString *)name atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err;

/// Returns the extended attributes for the item at the given path.
/// @param path The path of a file or directory.
/// @param follow Specify `true` to follow symbolic links.
/// @param err On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
- (nullable NSDictionary<NSString *, NSData *> *)extendedAttributesOfItemAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err;

/// Sets the extended attributes for the given file or directory.
/// @param name The name of the extended attribute.
/// @param value The value of the extended attribute.
/// @param path The path of a file or directory.
/// @param follow Specify `true` to follow symbolic links.
/// @param mode The behavior for creating or updating the extended attribute.
/// @param err On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
- (BOOL)setExtendedAttribute:(NSString *)name value:(NSData *)value atPath:(NSString *)path traverseLink:(BOOL)follow mode:(XAMode)mode error:(NSError **)err;

/// Removes the extended attribute for the given file or directory.
/// @param name The name of the extended attribute.
/// @param path The path of a file or directory.
/// @param follow Specify `true` to follow symbolic links.
/// @param err On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
- (BOOL)removeExtendedAttribute:(NSString *)name atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)err;

/// Replace the extended attributes of the specified file or directory.
/// @param attrs A dictionary containing the names as keys and corresponding value as values.
/// @param path The path of a file or directory.
/// @param follow Specify `true` to follow symbolic links.
/// @param replace Delete attributes not in dictionary, except resource fork.
/// @param err On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
- (BOOL)setExtendedAttributes:(NSDictionary<NSString *, NSData *> *)attrs atPath:(NSString *)path traverseLink:(BOOL)follow replace:(BOOL)replace error:(NSError **)err;

@end

NS_ASSUME_NONNULL_END
