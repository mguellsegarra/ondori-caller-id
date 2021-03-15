
#import "ONDCallerId.h"

@implementation ONDCallerId

RCT_EXPORT_MODULE()

-(NSError*) buildErrorFromException: (NSException*) exception withErrorCode: (NSInteger)errorCode {
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    [info setValue:exception.name forKey:@"Name"];
    [info setValue:exception.reason forKey:@"Reason"];
    [info setValue:exception.callStackReturnAddresses forKey:@"CallStack"];
    [info setValue:exception.callStackSymbols forKey:@"CallStackSymbols"];
    [info setValue:exception.userInfo forKey:@"UserInfo"];
    
    NSError *error = [[NSError alloc] initWithDomain:self.extensionId code:errorCode userInfo:info];
    return error;
}

RCT_EXPORT_METHOD(setDataKey: (NSString*) dataKey withResolver: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  self.dataKey = dataKey;
  resolve(@true);
}

RCT_EXPORT_METHOD(setAppGroup: (NSString*) appGroup withResolver: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  self.appGroup = appGroup;
  resolve(@true);
}

RCT_EXPORT_METHOD(setExtensionId: (NSString*) extensionId withResolver: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  self.extensionId = extensionId;
  resolve(@true);
}

- (NSArray*)getCallerList {
    @try {
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.appGroup];
        NSArray* callerList = [userDefaults arrayForKey:self.dataKey];
        if (callerList) {
            return callerList;
        }

        return [[NSArray alloc] init];
    }
    @catch(NSException* e) {
        NSLog(@"CallerId: Failed to getCallerList: %@", e.description);
    }
}

RCT_EXPORT_METHOD(getCallerList: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSArray* callerList = [NSArray arrayWithArray:[self getCallerList]];
        resolve(callerList);
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"getCallerList", @"Failed to getCallerList bridge:", error);
    }
}

- (NSArray*)getRemovalsList {
    @try {
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.appGroup];
        NSArray* callerList = [userDefaults arrayForKey:[self.dataKey stringByAppendingString:@"_TO_BE_REMOVED"]];
        if (callerList) {
            return callerList;
        }

        return [[NSArray alloc] init];
    }
    @catch(NSException* e) {
        NSLog(@"CallerId: Failed to getRemovalsList: %@", e.description);
    }
}

RCT_EXPORT_METHOD(getRemovalsList: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSArray* callerList = [NSArray arrayWithArray:[self getRemovalsList]];
        resolve(callerList);
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"getRemovalsList", @"Failed to getRemovalsList bridge:", error);
    }
}

RCT_EXPORT_METHOD(removeContactsFromCallerList: (NSArray*) listOfIds withResolver: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.appGroup];
        [userDefaults setObject:listOfIds forKey:[self.dataKey stringByAppendingString:@"_TO_BE_REMOVED"]];
        resolve(nil);
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"removeContactsFromCallerList", @"Failed to removeContactsFromCallerList", error);
    }
}

RCT_EXPORT_METHOD(setCallerList:(NSArray*)callerList withResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.appGroup];
        [userDefaults setObject:callerList forKey:self.dataKey];
        resolve(nil);
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"setCallerList", @"Failed to setCallerList:", error);
    }
}

RCT_EXPORT_METHOD(getUnprocessedContacts: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSArray* callerList = [self getCallerList];
        NSMutableArray* unprocessedContacts = [[NSMutableArray alloc] init];

        for (int i = 0; i < [callerList count]; i++) {
          
          NSMutableDictionary *contact = [callerList objectAtIndex:i];
            if ([[contact objectForKey:@"processed"]  isEqual: @NO]) {
            [unprocessedContacts addObject:contact];
          }
        }
        
        resolve([NSArray arrayWithArray:unprocessedContacts]);
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"getUnprocessedContacts", @"Failed to getUnprocessedContacts:", error);
    }
}

RCT_EXPORT_METHOD(getLastAddedContact: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSArray* callerList = [self getCallerList];
    
        NSArray *sortedCallerList = [callerList sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            NSString* aFetchedAt = [a valueForKey:@"fetched_at"];
            NSString* bFetchedAt = [b valueForKey:@"fetched_at"];

            return [aFetchedAt compare:bFetchedAt];
        }];
        
        resolve([sortedCallerList lastObject]);
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"getLastAddedContact", @"Failed to getUnprocessedContacts:", error);
    }
}

RCT_EXPORT_METHOD(addContactsToCallerList: (NSArray*) callerList withResolver: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSMutableArray* mutableList = [NSMutableArray arrayWithArray:[self getCallerList]];

        for (int i = 0; i < [callerList count]; i++) {
            NSDictionary* object = [callerList objectAtIndex:i];
            NSMutableDictionary *mutableOjbect = [NSMutableDictionary dictionaryWithDictionary:object];
            [mutableOjbect setValue:@NO forKey:@"processed"];
            [mutableList addObject:mutableOjbect];
        }
        
        NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:self.appGroup];
        [userDefaults setObject:[NSArray arrayWithArray:mutableList] forKey:self.dataKey];
        resolve(nil);
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"addContactsToCallerList", @"Failed to addContactsToCallerList", error);
    }
}

RCT_EXPORT_METHOD(reloadExtension: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  @try {
      [CXCallDirectoryManager.sharedInstance reloadExtensionWithIdentifier:self.extensionId completionHandler:^(NSError * _Nullable error) {
          if(error) {
              reject(@"reloadExtension", @"Failed to reload extension", error);
          } else {
              resolve(@true);
          }
      }];
  }
  @catch (NSException* e) {
      NSError* error = [self buildErrorFromException:e withErrorCode: 100];
      reject(@"reloadExtension", @"Failed to reload extension", error);
  }
}

RCT_EXPORT_METHOD(openSettings: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        [CXCallDirectoryManager.sharedInstance openSettingsWithCompletionHandler:^(NSError * _Nullable error) {
            if(error) {
                reject(@"openSettingsWithCompletionHandler", @"Failed to openSettingsWithCompletionHandler", error);
            } else {
                resolve(@true);
            }
        }];
    }
    @catch (NSException* e) {
        NSError* error = [self buildErrorFromException:e withErrorCode: 100];
        reject(@"openSettingsWithCompletionHandler", @"Failed toopenSettingsWithCompletionHandler", error);
    }
}

RCT_EXPORT_METHOD(getExtensionEnabledStatus: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    // The completionHandler is called twice. This is a workaround
    __block BOOL hasResult = false;
    __block int realResult = 0;
    [CXCallDirectoryManager.sharedInstance getEnabledStatusForExtensionWithIdentifier:self.extensionId completionHandler:^(CXCallDirectoryEnabledStatus enabledStatus, NSError * _Nullable error) {
        // TODO: Remove these conditions when you find a way to return the correct result or Apple just fix their bug.
        if (hasResult == false) {
            hasResult = true;
            realResult = (int)enabledStatus;
        }
        if(error) {
            NSString *strFromInt = [NSString stringWithFormat:@"%ld", (long)error.code];
            NSString *description = [NSString stringWithFormat:@"Failed to reload extension: %@", [error localizedDescription]];
            reject(strFromInt, description, error);
        } else if (realResult == 2) {
            resolve(@true);
        } else {
          resolve(@false);
        }
    }];
}

@end

