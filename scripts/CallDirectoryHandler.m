#import "CallDirectoryHandler.h"

#define DATA_KEY @"CALLER_LIST"
#define APP_GROUP @"group.mguellsegarra_callerid"

@interface CallDirectoryHandler () <CXCallDirectoryExtensionContextDelegate>

@end

@implementation CallDirectoryHandler

- (void)beginRequestWithExtensionContext:(CXCallDirectoryExtensionContext *)context {
    context.delegate = self;
    if (context.isIncremental) {
        [context removeAllIdentificationEntries];
    }
    
    [self addAllIdentificationPhoneNumbersToContext:context];
    
    [context completeRequestWithCompletionHandler:nil];
}

- (NSArray*)getCallerList {
    @try {
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
        NSArray* callerList = [userDefaults arrayForKey:DATA_KEY];
        if (callerList) {
            return callerList;
        }

        return [[NSArray alloc] init];
    }
    @catch(NSException* e) {
        NSLog(@"CallerId: Failed to get caller list: %@", e.description);
    }
}

- (void)addAllIdentificationPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    @try {
      NSArray* callerList = [self getCallerList];
      NSUInteger callersCount = [callerList count];

      NSMutableDictionary<NSNumber*, NSString*>* labelsKeyedByPhoneNumber = [[NSMutableDictionary alloc] init];
    
      if(callersCount > 0) {
          for (NSUInteger i = 0; i < callersCount; i += 1) {
            NSDictionary* entry = [callerList objectAtIndex: i];
            [labelsKeyedByPhoneNumber setValue:[entry valueForKey:@"name"] forKey:[entry valueForKey:@"number"]];
          }
      }

      NSArray *sorted = [[[labelsKeyedByPhoneNumber.allKeys sortedArrayUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects];
      
      for (NSNumber *phoneNumber in sorted) {
        NSString *label = labelsKeyedByPhoneNumber[phoneNumber];
        CXCallDirectoryPhoneNumber auxNumber = (CXCallDirectoryPhoneNumber)[phoneNumber longLongValue];
        [context addIdentificationEntryWithNextSequentialPhoneNumber:auxNumber label:label];
      }
    } @catch (NSException* e) {
        NSLog(@"CallerId: Failed to get caller list: %@", e.description);
    }
    
}

- (void)requestFailedForExtensionContext:(nonnull CXCallDirectoryExtensionContext *)extensionContext withError:(nonnull NSError *)error {
    NSLog(@"CallerId: Request failed: %@", error.localizedDescription);
}

@end


