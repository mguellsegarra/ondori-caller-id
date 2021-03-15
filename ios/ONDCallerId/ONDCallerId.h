
#import <React/RCTBridgeModule.h>
#import <CallKit/CallKit.h>
#import <React/RCTLog.h>

@interface ONDCallerId : NSObject <RCTBridgeModule>

@property (strong, nonatomic) NSString* appGroup;
@property (strong, nonatomic) NSString* dataKey;
@property (strong, nonatomic) NSString* extensionId;

@end
  
