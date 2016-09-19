//
//  GSOutgoingCall.m
//  Gossip
//
//  Created by Chakrit Wichian on 7/12/12.
//

#import "GSOutgoingCall.h"
#import "GSCall+Private.h"
#import "PJSIP.h"
#import "Util.h"
#import "GSUserAgent.h"

pj_status_t capturecb(pjmedia_vid_dev_stream *stream,
                      void *user_data,
                      pjmedia_frame *frame);

pj_status_t rendercb(pjmedia_vid_dev_stream *stream,
                     void *user_data,
                     pjmedia_frame *frame);


@implementation GSOutgoingCall {
    
}

@synthesize remoteUri = _remoteUri;

- (GSOutgoingCall *)initWithRemoteUri:(NSString *)remoteUri fromAccount:(GSAccount *)account {
    if (self = [super initWithAccount:account]) {
        _remoteUri = [remoteUri copy];
    }
    return self;
}

- (void)dealloc {
    _remoteUri = nil;
}

- (BOOL)begin {
    if (![_remoteUri hasPrefix:@"sip:"])
        _remoteUri = [@"sip:" stringByAppendingString:_remoteUri];
    
    pj_str_t remoteUri = [GSPJUtil PJStringWithString:_remoteUri];
    pjsua_call_setting callSetting;
    pjsua_call_setting_default(&callSetting);
    callSetting.aud_cnt = 1;
    callSetting.vid_cnt = 0;
    
    pjsua_call_id callId;
    
    NSDictionary *info=[NSDictionary dictionaryWithObjectsAndKeys:@"hechen",@"phone",@"25",@"area", nil];
    
    GSReturnNoIfFails(pjsua_call_make_call(self.account.accountId, &remoteUri, &callSetting, NULL, NULL, &callId));
    [self setCallId:callId];
    
    return YES;
}

- (BOOL)beginVoice:(NSString *)phoneNumber withArea:(NSString *)area {
    if (![_remoteUri hasPrefix:@"sip:"])
        _remoteUri = [@"sip:" stringByAppendingString:_remoteUri];
    
    pj_str_t remoteUri = [GSPJUtil PJStringWithString:_remoteUri];
    pjsua_call_setting callSetting;
    pjsua_call_setting_default(&callSetting);
    callSetting.aud_cnt = 1;
    callSetting.vid_cnt = 0;
    
    pjsua_call_id callId;
    
    NSDictionary *info=[NSDictionary dictionaryWithObjectsAndKeys:phoneNumber,@"phoneNumber",area,@"area", nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:nil];
    NSString *strJson = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"strJson: %@", strJson);
    GSReturnNoIfFails(pjsua_call_make_call(self.account.accountId, &remoteUri, &callSetting, NULL, NULL, &callId));
    [self setCallId:callId];
    
    return YES;
}

- (BOOL)end {
    NSAssert(self.callId != PJSUA_INVALID_ID, @"Call has not begun yet.");
    GSReturnNoIfFails(pjsua_call_hangup(self.callId, 0, NULL, NULL));
    [self setStatus:GSCallStatusDisconnected];
    [self setCallId:PJSUA_INVALID_ID];
    return YES;
}

pj_status_t capturecb(pjmedia_vid_dev_stream *stream,
                      void *user_data,
                      pjmedia_frame *frame) {
    return PJ_SUCCESS;
}

pj_status_t rendercb(pjmedia_vid_dev_stream *stream,
                     void *user_data,
                     pjmedia_frame *frame) {
    return PJ_SUCCESS;
}

@end
