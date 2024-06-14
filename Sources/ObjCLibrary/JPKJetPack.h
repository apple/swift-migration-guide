#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JPKJetPack : NSObject

/// Disable async to show how completion handlers work explicitly.
+ (void)jetPackConfiguration:(void (NS_SWIFT_SENDABLE ^)(void))completionHandler NS_SWIFT_DISABLE_ASYNC;

@end

NS_ASSUME_NONNULL_END
