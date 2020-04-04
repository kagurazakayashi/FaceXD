//
//  XDDlibModelParameterConfiguration.m
//  FaceXD
//
//  Created by CmST0us on 2020/3/28.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDDlibModelParameterConfiguration.h"
#import "XDFaceAnchor.h"
@interface XDDlibModelParameterConfiguration ()
@property (nonatomic, assign) CFTimeInterval lastUpdateTime;
@property (nonatomic, copy) XDModelParameter *lastParameter;
@end

@implementation XDDlibModelParameterConfiguration
- (instancetype)initWithModel:(LAppModel *)model {
    self = [super initWithModel:model];
    if (self) {
        _interpolation = YES;
        _frameInterval = 1.0 / 30.0;
        _lastUpdateTime = -1;
    }
    return self;
}

- (void)updateParameterWithFaceAnchor:(XDFaceAnchor *)anchor {
    self.lastParameter = self.parameter;
    CGFloat pitch = anchor.headPitch.floatValue;
    CGFloat pitchSig = pitch > 0 ? 1 : -1;
    pitch = pitchSig * (M_PI - fabs(pitch));
    pitch = 180.0 / M_PI * pitch;
    pitch -= 12;
    if (pitch < -19) {
        pitch = -19;
    } else if (pitch > 32) {
        pitch = 32;
    }
    self.parameter.headPitch = @(pitch * 2);
    self.parameter.headRoll = @(180.0 / M_PI * anchor.headRoll.floatValue * 2);
    self.parameter.headYaw = @(-180.0 / M_PI * anchor.headYaw.floatValue * 1.2);
    
    self.parameter.eyeLOpen = @(anchor.leftEyeOpen.floatValue * 30);
    self.parameter.eyeROpen = @(anchor.leftEyeOpen.floatValue * 30);
    self.parameter.mouthOpenY = @(anchor.mouthOpenY.floatValue * 8);
    self.parameter.mouthForm = @(anchor.mouthOpenX.floatValue);
    
    self.lastUpdateTime = CACurrentMediaTime();
}

#pragma mark - Interpolation;
- (CGFloat)interpolateFrom:(CGFloat)from to:(CGFloat)to percent:(CGFloat)percent {
    return from + (to - from) * percent;
}

- (void)commit {
    CGFloat persent = 1;
    if (self.lastUpdateTime > 0) {
        CFTimeInterval currentInterpolationTime = CACurrentMediaTime() - self.lastUpdateTime;
        persent = currentInterpolationTime / self.frameInterval;
        if (persent > 1) {
            persent = 1;
        }
    }
    [self.parameterKeyMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *targetValue = [self.parameter valueForKey:obj];
        NSNumber *fromValue = [self.lastParameter valueForKey:obj];
        CGFloat v = self.interpolation ? [self interpolateFrom:fromValue.floatValue to:targetValue.floatValue percent:persent] : targetValue.floatValue;
        if (v) {
            [self.model setParam:key forValue:@(v)];
        } else {
            [self.model setParam:key forValue:@(0)];
        }
    }];
}
@end
