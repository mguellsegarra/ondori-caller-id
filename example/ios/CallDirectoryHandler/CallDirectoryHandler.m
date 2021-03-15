#import "CallDirectoryHandler.h"

#define DATA_KEY @"CALLER_LIST"
#define APP_GROUP @"group.ondori_caller_id"

@interface CallDirectoryHandler () <CXCallDirectoryExtensionContextDelegate>

@end

@implementation CallDirectoryHandler

- (void)beginRequestWithExtensionContext:(CXCallDirectoryExtensionContext *)context {
  context.delegate = self;

  NSArray* removalsList = [self getRemovalsList];
  
  if ([removalsList count] > 0) {
    [self removeIdentificationPhoneNumbers:removalsList toContext:context];
    [self processRemovalsFromCallerList];
    [self clearRemovalsList];
  }
  
  if (context.isIncremental) {
    [self addIdentificationPhoneNumbers:[self getUnprocessedContacts] toContext:context];
  } else {
    [self addIdentificationPhoneNumbers:[self getCallerList] toContext:context];
  }
  
  NSLog(@"OND-Debug: Extension starts");
  
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
        NSLog(@"OND-Debug: Failed to get caller list: %@", e.description);
    }
}

- (NSArray*)getRemovalsList {
    @try {
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
        NSArray* removalsList = [userDefaults arrayForKey:[DATA_KEY stringByAppendingString:@"_TO_BE_REMOVED"]];
        if (removalsList) {
            return removalsList;
        }

        return [[NSArray alloc] init];
    }
    @catch(NSException* e) {
        NSLog(@"OND-Debug: Failed to get removals list: %@", e.description);
    }
}

- (void)clearRemovalsList {
  NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
  [userDefaults setObject:[[NSArray alloc] init] forKey:[DATA_KEY stringByAppendingString:@"_TO_BE_REMOVED"]];
}

- (BOOL)contactExistsInRemovals:(NSString *)phone {
  NSArray* removalList = [self getRemovalsList];
  BOOL result = false;
  
  for (int i = 0; i < [removalList count]; i++) {
    NSDictionary* entry = [removalList objectAtIndex:i];
    if ([[entry objectForKey:@"number"] isEqual:phone]) {
      result = true;
    }
  }
  
  return result;
}

- (void)processRemovalsFromCallerList {
  NSArray* callerList = [self getCallerList];
  NSMutableArray* newCallerList = [[NSMutableArray alloc] init];

  for (int i = 0; i < [callerList count]; i++) {
    NSMutableDictionary *contact = [callerList objectAtIndex:i];
    
    if (![self contactExistsInRemovals:[contact objectForKey:@"number"]]) {
      [newCallerList addObject:contact];
    }
  }
  
  NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
  [userDefaults setObject:[NSArray arrayWithArray:newCallerList] forKey:DATA_KEY];
}

- (NSArray*)getUnprocessedContacts {
  @try {
      NSArray* callerList = [self getCallerList];
      NSMutableArray* unprocessedContacts = [[NSMutableArray alloc] init];

      for (int i = 0; i < [callerList count]; i++) {
        
        NSMutableDictionary *contact = [callerList objectAtIndex:i];
          if ([[contact objectForKey:@"processed"]  isEqual: @NO]) {
          [unprocessedContacts addObject:contact];
        }
      }
      
    return [NSArray arrayWithArray:unprocessedContacts];
  }
  @catch (NSException* e) {
    NSLog(@"OND-Debug: Failed to updateContactsAsProcessed: %@", e.description);
  }
}

- (void)updateContactsAsProcessed {
  @try {
    NSArray* persistedList = [self getCallerList];
    NSMutableArray* mutableList = [[NSMutableArray alloc] init];

    for (int i = 0; i < [persistedList count]; i++) {
      NSDictionary* object = [persistedList objectAtIndex:i];
      NSMutableDictionary *mutableOjbect = [NSMutableDictionary dictionaryWithDictionary:object];
      [mutableOjbect setValue:@YES forKey:@"processed"];
      [mutableList addObject:[NSDictionary dictionaryWithDictionary:mutableOjbect]];
    }
    
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [userDefaults setObject:[NSArray arrayWithArray:mutableList] forKey:DATA_KEY];
  }
  @catch(NSException* e) {
      NSLog(@"OND-Debug: Failed to updateContactsAsProcessed: %@", e.description);
  }
}

- (void)addIdentificationPhoneNumbers:(NSArray*) callerList toContext:(CXCallDirectoryExtensionContext *)context {
    @try {
      NSUInteger callersCount = [callerList count];

      NSMutableDictionary<NSNumber*, NSString*>* labelsKeyedByPhoneNumber = [[NSMutableDictionary alloc] init];
    
      if(callersCount > 0) {
          for (NSUInteger i = 0; i < callersCount; i += 1) {
            NSDictionary* entry = [callerList objectAtIndex: i];
            [labelsKeyedByPhoneNumber setValue:[entry valueForKey:@"name"] forKey:[entry valueForKey:@"number"]];
          }
      }

      NSArray *sorted = [[[labelsKeyedByPhoneNumber.allKeys sortedArrayUsingSelector:@selector(compare:)] objectEnumerator] allObjects];
      
      for (NSNumber *phoneNumber in sorted) {
        NSString *label = labelsKeyedByPhoneNumber[phoneNumber];
        CXCallDirectoryPhoneNumber auxNumber = (CXCallDirectoryPhoneNumber)[phoneNumber longLongValue];
       NSLog(@"OND-Debug: addIdentificationPhoneNumbers: phone: %lld - label: %@", auxNumber, label);

        [context addIdentificationEntryWithNextSequentialPhoneNumber:auxNumber label:label];
      }
      
      [self updateContactsAsProcessed];
    } @catch (NSException* e) {
        NSLog(@"OND-Debug: Failed to addIdentificationPhoneNumbers: %@", e.description);
    }
}

- (void)removeIdentificationPhoneNumbers:(NSArray*) callerList toContext:(CXCallDirectoryExtensionContext *)context {
  
  @try {
    NSUInteger callersCount = [callerList count];

    NSMutableDictionary<NSNumber*, NSString*>* labelsKeyedByPhoneNumber = [[NSMutableDictionary alloc] init];
  
    if(callersCount > 0) {
        for (NSUInteger i = 0; i < callersCount; i += 1) {
          NSDictionary* entry = [callerList objectAtIndex: i];
          [labelsKeyedByPhoneNumber setValue:[entry valueForKey:@"name"] forKey:[entry valueForKey:@"number"]];
        }
    }

    NSArray *sorted = [[[labelsKeyedByPhoneNumber.allKeys sortedArrayUsingSelector:@selector(compare:)] objectEnumerator] allObjects];
    
    for (NSNumber *phoneNumber in sorted) {
      CXCallDirectoryPhoneNumber auxNumber = (CXCallDirectoryPhoneNumber)[phoneNumber longLongValue];
//        NSLog(@"OND-Debug: removeIdentificationPhoneNumbers: phone: %lld", auxNumber);

      [context removeIdentificationEntryWithPhoneNumber:auxNumber];
    }
    
    [self updateContactsAsProcessed];
  } @catch (NSException* e) {
      NSLog(@"OND-Debug: Failed to removeIdentificationPhoneNumbers: %@", e.description);
  }
}

- (void)requestFailedForExtensionContext:(nonnull CXCallDirectoryExtensionContext *)extensionContext withError:(nonnull NSError *)error {
    NSLog(@"OND-Debug: Request failed: %@", error);
}

@end