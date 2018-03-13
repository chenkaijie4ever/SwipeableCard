
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "AKNetworkReachability"
#pragma clang diagnostic pop

/*
 
 File: Reachability.m
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 
 Version: 2.0.4ddg
 */

/*
 Significant additions made by Andrew W. Donoho, August 11, 2009.
 This is a derived work of Apple's Reachability v2.0 class.
 
 The below license is the new BSD license with the OSI recommended personalizations.
 <http://www.opensource.org/licenses/bsd-license.php>
 
 Extensions Copyright (C) 2009 Donoho Design Group, LLC. All Rights Reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of Andrew W. Donoho nor Donoho Design Group, L.L.C.
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY DONOHO DESIGN GROUP, L.L.C. "AS IS" AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */


/*
 
 Apple's Original License on Reachability v2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

/*
 Each reachability object now has a copy of the key used to store it in a dictionary.
 This allows each observer to quickly determine if the event is important to them.
 */

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>
#import "FFNetworkReachability.h"


#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>


NSString *const kFFSDKInternetConnection  = @"AKSDKInternetConnection";
NSString *const kFFSDKLocalWiFiConnection = @"AKSDKLocalWiFiConnection";
NSString *const kFFSDKReachabilityChangedNotification = @"AKSDKReachabilityChangedNotification";
NSString *const kFFSDKPublicReachabilityChangedNotification = @"AKSDKPublicReachabilityChangedNotification";


static FFNetworkReachability* s_FFNetworkReachability = nil;
static NetworkStatus s_FFnetworkStatus = NotReachable;


@interface FFNetworkReachability (private)

- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags;

@end



@implementation FFNetworkReachability

@synthesize key = key_;

// Preclude direct access to ivars.
+ (BOOL) accessInstanceVariablesDirectly {
	
	return NO;
    
} // accessInstanceVariablesDirectly


- (void) dealloc {
	
	[self stopNotifier];
	if(reachabilityRef) {
		
		CFRelease(reachabilityRef); reachabilityRef = NULL;
	}
	
	self.key = nil;
} // dealloc

+ (NetworkStatus)networkStatus
{
    if (s_FFNetworkReachability == nil)
    {
		s_FFNetworkReachability = [FFNetworkReachability reachabilityForInternetConnection];
        [s_FFNetworkReachability startNotifier];
		s_FFnetworkStatus = [s_FFNetworkReachability currentReachabilityStatus];
	}
	
	return s_FFnetworkStatus;
}

+ (NSDictionary *)detailedNetworkStatus
{
    //status could be 0:NotReachable, 1:Wifi, 2:WWAN
    NSString *radioAccessTech = @"";
    int status = [FFNetworkReachability networkStatus];
    if (status == ReachableViaWWAN) {
        
        static CTTelephonyNetworkInfo * telephonyNetworkInfo = nil;
        static dispatch_once_t creatTelephonyNetworkInfoOnceToken;//保证多线程访问情况下，此对象仍然只生成一次
        
        dispatch_once(& creatTelephonyNetworkInfoOnceToken, ^{
            
            telephonyNetworkInfo = [CTTelephonyNetworkInfo new];
            
        });
        
        
        if ([telephonyNetworkInfo respondsToSelector:@selector(currentRadioAccessTechnology)])
        {
            radioAccessTech = telephonyNetworkInfo.currentRadioAccessTechnology;
            if ([radioAccessTech isEqualToString:@"CTRadioAccessTechnologyEdge"] ||
                [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
                status = 2; //2G
            }
            else if ([radioAccessTech isEqualToString:@"CTRadioAccessTechnologyWCDMA"] ||
                     [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyCDMA1x"] ||
                     [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"] ||
                     [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"] ||
                     [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"] ||
                     [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyHSDPA"] ||
                     [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyHSUPA"]) {
                status = 3; //3G
            }
            else if ([radioAccessTech isEqualToString:@"CTRadioAccessTechnologyLTE"] ||
                     [radioAccessTech isEqualToString:@"CTRadioAccessTechnologyeHRPD"]) {
                status = 4; //4G
            }
        }
    }
    
    //buf fix
    radioAccessTech = radioAccessTech == nil?@"":radioAccessTech;
    
    return @{@"type": @(status),
             @"radio": radioAccessTech};
}


#pragma mark -

- (FFNetworkReachability *) initWithReachabilityRef: (SCNetworkReachabilityRef) ref
{
    self = [super init];
	if (self != nil)
    {
		reachabilityRef = ref;
	}
	
	return self;
	
} // initWithReachabilityRef:


#pragma mark -
#pragma mark Notification Management Methods


//Start listening for reachability notifications on the current run loop
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    
#pragma unused (target, flags)
	//We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
	// in case someone uses the Reachablity object in a different thread.
    
    FFNetworkReachability * reach = (__bridge FFNetworkReachability *)info;
    if(reach == s_FFNetworkReachability)
    {
        //记下状态
        s_FFnetworkStatus = [reach networkStatusForFlags:flags];
        
        // Post a notification to notify the client that the network reachability changed.
        [[NSNotificationCenter defaultCenter] postNotificationName:kFFSDKPublicReachabilityChangedNotification object:(__bridge FFNetworkReachability*)info];
    }
	else
    {
        // Post a notification to notify the client that the network reachability changed.
        [[NSNotificationCenter defaultCenter] postNotificationName:kFFSDKPublicReachabilityChangedNotification object:(__bridge FFNetworkReachability*)info];
    }
    
} // ReachabilityCallback()


- (BOOL) startNotifier {
	
	SCNetworkReachabilityContext	context = {0, (__bridge void*)self, NULL, NULL, NULL};
	
	if(SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context)) {
		
		if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
            
			return YES;
			
		}
		
	}
	
	return NO;
    
} // startNotifier


- (void) stopNotifier {
	
	if(reachabilityRef) {
		
		SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        
	}
    
} // stopNotifier


- (BOOL) isEqual: (FFNetworkReachability *) r {
	
	return [r.key isEqualToString:self.key];
	
} // isEqual:


#pragma mark -
#pragma mark Reachability Allocation Methods


+ (FFNetworkReachability *) reachabilityWithHostName: (NSString *) hostName {
	
	SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
	
	if (ref) {
		
		FFNetworkReachability *r = [[self alloc] initWithReachabilityRef: ref];
		
		r.key = hostName;
        
		return r;
		
	}
	
	return nil;
	
} // reachabilityWithHostName


+ (NSString *) makeAddressKey: (in_addr_t) addr {
	// addr is assumed to be in network byte order.
	
	static const int       highShift    = 24;
	static const int       highMidShift = 16;
	static const int       lowMidShift  =  8;
	static const in_addr_t mask         = 0x000000ff;
	
	addr = ntohl(addr);
	
	return  [NSString stringWithFormat:@"%zd.%zd.%zd.%zd",
			(addr >> highShift)    & mask,
			(addr >> highMidShift) & mask,
			(addr >> lowMidShift)  & mask,
            addr                  & mask];
	
} // makeAddressKey:


+ (FFNetworkReachability *) reachabilityWithAddress: (const struct sockaddr_in *) hostAddress {
	
	SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    
	if (ref) {
		
		FFNetworkReachability *r = [[self alloc] initWithReachabilityRef: ref];
		
		r.key = [self makeAddressKey: hostAddress->sin_addr.s_addr];
		
		return r;
		
	}
	
	return nil;
    
} // reachabilityWithAddress


+ (FFNetworkReachability *) reachabilityForInternetConnection {
	
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
    
	FFNetworkReachability *r = [self reachabilityWithAddress: &zeroAddress];
    
	r.key = kFFSDKInternetConnection;
	
	return r;
    
} // reachabilityForInternetConnection

/*
+ (AKNetworkReachability *) reachabilityForLocalWiFi {
	
	struct sockaddr_in localWifiAddress;
	bzero(&localWifiAddress, sizeof(localWifiAddress));
	localWifiAddress.sin_len = sizeof(localWifiAddress);
	localWifiAddress.sin_family = AF_INET;
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    
	AKNetworkReachability *r = [self reachabilityWithAddress: &localWifiAddress];
    
	r.key = kAKSDKLocalWiFiConnection;
    
	return r;
    
} // reachabilityForLocalWiFi
*/

#pragma mark -
#pragma mark Network Flag Handling Methods


#if USE_DDG_EXTENSIONS_AKSDK
//
// iPhone condition codes as reported by a 3GS running iPhone OS v3.0.
// Airplane Mode turned on:  Reachability Flag Status: -- -------
// WWAN Active:              Reachability Flag Status: WR -t-----
// WWAN Connection required: Reachability Flag Status: WR ct-----
//         WiFi turned on:   Reachability Flag Status: -R ------- Reachable.
// Local   WiFi turned on:   Reachability Flag Status: -R xxxxxxd Reachable.
//         WiFi turned on:   Reachability Flag Status: -R ct----- Connection down. (Non-intuitive, empirically determined answer.)
static const SCNetworkReachabilityFlags kConnectionDown =  kSCNetworkReachabilityFlagsConnectionRequired |
kSCNetworkReachabilityFlagsTransientConnection;
//         WiFi turned on:   Reachability Flag Status: -R ct-i--- Reachable but it will require user intervention (e.g. enter a WiFi password).
//         WiFi turned on:   Reachability Flag Status: -R -t----- Reachable via VPN.
//
// In the below method, an 'x' in the flag status means I don't care about its value.
//
// This method differs from Apple's by testing explicitly for empirically observed values.
// This gives me more confidence in it's correct behavior. Apple's code covers more cases
// than mine. My code covers the cases that occur.
//
- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags {
	
	if (flags & kSCNetworkReachabilityFlagsReachable) {
		
		// Local WiFi -- Test derived from Apple's code: -localWiFiStatusForFlags:.
		if (self.key == kFFSDKLocalWiFiConnection) {
            
			// Reachability Flag Status: xR xxxxxxd Reachable.
			return (flags & kSCNetworkReachabilityFlagsIsDirect) ? ReachableViaWiFi : NotReachable;
            
		}
		
		// Observed WWAN Values:
		// WWAN Active:              Reachability Flag Status: WR -t-----
		// WWAN Connection required: Reachability Flag Status: WR ct-----
		//
		// Test Value: Reachability Flag Status: WR xxxxxxx
		if (flags & kSCNetworkReachabilityFlagsIsWWAN) { return ReachableViaWWAN; }
		
		// Clear moot bits.
		flags &= ~kSCNetworkReachabilityFlagsReachable;
		flags &= ~kSCNetworkReachabilityFlagsIsDirect;
		flags &= ~kSCNetworkReachabilityFlagsIsLocalAddress; // kAKSDKInternetConnection is local.
		
		// Reachability Flag Status: -R ct---xx Connection down.
		if (flags == kConnectionDown) { return NotReachable; }
		
		// Reachability Flag Status: -R -t---xx Reachable. WiFi + VPN(is up) (Thank you Ling Wang)
		if (flags & kSCNetworkReachabilityFlagsTransientConnection)  { return ReachableViaWiFi; }
        
		// Reachability Flag Status: -R -----xx Reachable.
		if (flags == 0) { return ReachableViaWiFi; }
		
		// Apple's code tests for dynamic connection types here. I don't.
		// If a connection is required, regardless of whether it is on demand or not, it is a WiFi connection.
		// If you care whether a connection needs to be brought up,   use -isConnectionRequired.
		// If you care about whether user intervention is necessary,  use -isInterventionRequired.
		// If you care about dynamically establishing the connection, use -isConnectionIsOnDemand.
        
		// Reachability Flag Status: -R cxxxxxx Reachable.
		if (flags & kSCNetworkReachabilityFlagsConnectionRequired) { return ReachableViaWiFi; }
		
		// Required by the compiler. Should never get here. Default to not connected.
		return NotReachable;
        
    }
	
	// Reachability Flag Status: x- xxxxxxx
	return NotReachable;
	
} // networkStatusForFlags:

/*
 *注意该接口可能会比较耗时，如果涉及UI操作，请考虑性能问题（缓存状态，有网络变化的时候再更新缓存）,建议使用[AKNetworkReachability networkStatus]
 */
- (NetworkStatus) currentReachabilityStatus {
	
	NSAssert(reachabilityRef, @"currentReachabilityStatus called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = NotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
        //		logReachabilityFlags(flags);
		
		status = [self networkStatusForFlags: flags];
		
		return status;
		
	}
	
	return NotReachable;
	
} // currentReachabilityStatus


- (BOOL) isReachable {
	
	NSAssert(reachabilityRef, @"isReachable called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = NotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
        //		logReachabilityFlags(flags);
        
		status = [self networkStatusForFlags: flags];
        
        //		logNetworkStatus(status);
		
		return (NotReachable != status);
		
	}
	
	return NO;
	
} // isReachable


- (BOOL) isConnectionRequired {
	
	NSAssert(reachabilityRef, @"isConnectionRequired called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		//logReachabilityFlags(flags);
		
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
        
	}
	
	return NO;
	
} // isConnectionRequired


- (BOOL) connectionRequired {
	
	return [self isConnectionRequired];
	
} // connectionRequired
#endif


#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 30000)
static const SCNetworkReachabilityFlags kOnDemandConnection = kSCNetworkReachabilityFlagsConnectionOnTraffic |
kSCNetworkReachabilityFlagsConnectionOnDemand;
#else
static const SCNetworkReachabilityFlags kOnDemandConnection = kSCNetworkReachabilityFlagsConnectionAutomatic;
#endif

/*
- (BOOL)
{
	
	NSAssert(reachabilityRef, @"isConnectionIsOnDemand called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
				(flags & kOnDemandConnection));
		
	}
	
	return NO;
	
} // isConnectionOnDemand
*/

- (BOOL) isInterventionRequired {
	
	NSAssert(reachabilityRef, @"isInterventionRequired called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		//logReachabilityFlags(flags);
		
		return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
				(flags & kSCNetworkReachabilityFlagsInterventionRequired));
		
	}
	
	return NO;
	
} // isInterventionRequired


- (BOOL) isReachableViaWWAN {
	
	NSAssert(reachabilityRef, @"isReachableViaWWAN called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = NotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		//logReachabilityFlags(flags);
		
		status = [self networkStatusForFlags: flags];
		
		return  (ReachableViaWWAN == status);
        
	}
	
	return NO;
	
} // isReachableViaWWAN


- (BOOL) isReachableViaWiFi {
	
	NSAssert(reachabilityRef, @"isReachableViaWiFi called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = NotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		//logReachabilityFlags(flags);
		
		status = [self networkStatusForFlags: flags];
		
		return  (ReachableViaWiFi == status);
		
	}
	
	return NO;
	
} // isReachableViaWiFi


- (SCNetworkReachabilityFlags) reachabilityFlags {
	
	NSAssert(reachabilityRef, @"reachabilityFlags called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		//logReachabilityFlags(flags);
		
		return flags;
		
	}
	
	return 0;
	
} // reachabilityFlags


#pragma mark -
#pragma mark Apple's Network Flag Handling Methods


#if !USE_DDG_EXTENSIONS_AKSDK
/*
 *
 *  Apple's Network Status testing code.
 *  The only changes that have been made are to use the new logReachabilityFlags macro and
 *  test for local WiFi via the key instead of Apple's boolean. Also, Apple's code was for v3.0 only
 *  iPhone OS. v2.2.1 and earlier conditional compiling is turned on. Hence, to mirror Apple's behavior,
 *  set your Base SDK to v3.0 or higher.
 *
 */

- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags
{
	logReachabilityFlags(flags);
	
	BOOL retVal = NotReachable;
	if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect))
	{
		retVal = ReachableViaWiFi;
	}
	return retVal;
}


- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags
{
	logReachabilityFlags(flags);
	if (!(flags & kSCNetworkReachabilityFlagsReachable))
	{
		// if target host is not reachable
		return NotReachable;
	}
	
	BOOL retVal = NotReachable;
	
	if (!(flags & kSCNetworkReachabilityFlagsConnectionRequired))
	{
		// if target host is reachable and no connection is required
		//  then we'll assume (for now) that your on Wi-Fi
		retVal = ReachableViaWiFi;
	}
	
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 30000) // Apple advises you to use the magic number instead of a symbol.
	if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ||
		(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic))
#else
        if (flags & kSCNetworkReachabilityFlagsConnectionAutomatic)
#endif
		{
			// ... and the connection is on-demand (or on-traffic) if the
			//     calling application is using the CFSocketStream or higher APIs
			
			if (!(flags & kSCNetworkReachabilityFlagsInterventionRequired))
			{
				// ... and no [user] intervention is needed
				retVal = ReachableViaWiFi;
			}
		}
	
	if (flags & kSCNetworkReachabilityFlagsIsWWAN)
	{
		// ... but WWAN connections are OK if the calling application
		//     is using the CFNetwork (CFSocketStream?) APIs.
		retVal = ReachableViaWWAN;
	}
	return retVal;
}


- (NetworkStatus) currentReachabilityStatus
{
	NSAssert(reachabilityRef, @"currentReachabilityStatus called with NULL reachabilityRef");
	
	NetworkStatus retVal = NotReachable;
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
	{
		if(self.key == kAKSDKLocalWiFiConnection)
		{
			retVal = [self localWiFiStatusForFlags: flags];
		}
		else
		{
			retVal = [self networkStatusForFlags: flags];
		}
	}
	return retVal;
}


- (BOOL) isReachable {
	
	NSAssert(reachabilityRef, @"isReachable called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = NotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		if(self.key == kAKSDKLocalWiFiConnection) {
			
			status = [self localWiFiStatusForFlags: flags];
			
		} else {
			
			status = [self networkStatusForFlags: flags];
			
		}
		
		return (NotReachable != status);
		
	}
	
	return NO;
	
} // isReachable


- (BOOL) isConnectionRequired {
	
	return [self connectionRequired];
	
} // isConnectionRequired


- (BOOL) connectionRequired {
	
	NSAssert(reachabilityRef, @"connectionRequired called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
		
	}
	
	return NO;
	
} // connectionRequired
#endif
@end




