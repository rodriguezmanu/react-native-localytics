//
//  CLLocation+LocalyticsHelper.m
//  LLLocalytics
//
//  Created by Anand Bashyam on 2/26/18.
//  Copyright © 2018 Localytics. All rights reserved.
//

#import "CLLocation+LocalyticsHelper.h"

@implementation CLLocation (LocalyticsHelper)
- (NSDictionary *)toLocalyticsDictionary {
    NSMutableDictionary* dict = [NSMutableDictionary new];
    
    dict[@"latitude"] = @(self.coordinate.latitude);
    dict[@"longitude"] = @(self.coordinate.longitude);
    dict[@"altitude"] = @(self.altitude);
    dict[@"time"] = @(self.timestamp.timeIntervalSince1970);
    dict[@"horizontalAccuracy"] = @(self.horizontalAccuracy);
    dict[@"verticalAccuracy"] = @(self.verticalAccuracy);
    dict[@"direction"] = @(self.course);
    dict[@"speed"] = @(self.speed);
    return dict;
}

+ (instancetype)fromLocalyticsDictionary:(NSDictionary*)dict {
    NSNumber* lat = dict[@"latitude"];
    NSNumber* lon = dict[@"longitude"];
    if (!lat || !lon) {
        return nil;
    }
    CLLocationCoordinate2D coordinate;
    coordinate.longitude = [lon doubleValue];
    coordinate.latitude = [lat doubleValue];
    NSNumber* alt = dict[@"altitude"];
    NSNumber* hAccuracy = dict[@"horizontalAccuracy"];
    NSNumber* vAccuracy = dict[@"verticalAccuracy"];
    NSNumber* direction = dict[@"direction"];
    NSNumber* speed = dict[@"speed"];
    
    NSDate* timestamp = dict[@"time"];
    
    if (alt != nil && hAccuracy != nil && vAccuracy != nil && timestamp != nil ) {
        if (direction != nil && speed != nil) {
            return [[CLLocation alloc] initWithCoordinate:coordinate altitude:alt.doubleValue horizontalAccuracy:hAccuracy.doubleValue verticalAccuracy:vAccuracy.doubleValue course:direction.doubleValue speed:speed.doubleValue timestamp:timestamp];
        } else {
            return [[CLLocation alloc] initWithCoordinate:coordinate altitude:alt.doubleValue horizontalAccuracy:hAccuracy.doubleValue verticalAccuracy:vAccuracy.doubleValue timestamp:timestamp];
        }
    } else {
        return [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lon.doubleValue];
    }
}
@end
