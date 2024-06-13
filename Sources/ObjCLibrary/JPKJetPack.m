#import "JPKJetPack.h"

@implementation JPKJetPack

+ (void)jetPackConfiguration:(void (^)(void))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        completionHandler();
    });
}

@end
