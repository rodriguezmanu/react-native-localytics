//
//  CLLocation+LocalyticsHelper.h
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/26/18.
//  Copyright © 2018 Localytics. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (LocalyticsHelper)
- (nonnull NSDictionary *)toLocalyticsDictionary;
+ (nullable instancetype)fromLocalyticsDictionary:(nonnull NSDictionary*)dict;
@end

