#define kName @"BubbleColor"
#import "global.h"

@interface IMChat : NSObject
@property(retain, nonatomic) NSMutableSet *_guids;
@end

@interface CKTranscriptController : UIViewController
- (IMChat *)chat;
@end

static CKTranscriptController *transcriptController;
%hook CKTranscriptController
- (id)initWithNavigationController:(id)arg1 {
	transcriptController = %orig;
	return transcriptController;
}
- (id)init {
	transcriptController = %orig;
	return transcriptController;
}
%end

// Prefs
static BOOL isEnabled = YES;
static NSString *imcolor, *smscolor;
static NSArray *colorsArray;

typedef enum {
	BCChatTypeIMessage,
	BCChatTypeSMS,
	BCChatTypeNil
} BCChatType;

static BCChatType getChatType() {
	if(![transcriptController chat]) return BCChatTypeNil;
	for(NSString *i in [[transcriptController chat]._guids allObjects]) {
		if([i rangeOfString:@"iMessage"].location == 0)
			return BCChatTypeIMessage;
	}
	return BCChatTypeSMS;
}

// Get color
static NSArray *getColorsArray() {
	BCChatType chatType = getChatType();
	if(chatType == BCChatTypeNil) return nil;
	BOOL isIMessage = getChatType() == BCChatTypeIMessage;
	//XLog(Xstr(@"%@", isIMessage ? @"iMessage" : @"SMS"));
	NSString *file = Xstr(@"/User/Library/BubbleColor/%@", (isIMessage ? imcolor : smscolor));
	XLog(Xstr(@"File: '%@'", file));
	NSArray *lines = [[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSMutableArray *colors = [[NSMutableArray alloc] init];
	for(NSString *line in lines) {
		XLog(Xstr(@"Line: '%@'", line));
		NSArray *rgbs = [line componentsSeparatedByString:@","];
		if(rgbs.count != 3) continue;
		BOOL shouldSkip = NO;
		for(NSString *val in rgbs) {
			XLog(Xstr(@"Val: %@", val));
			NSScanner *scanner = [NSScanner scannerWithString:val];
			if(![scanner scanFloat:nil] || ![scanner isAtEnd]) {
				shouldSkip = YES;
				break;
			}
		}
		if(shouldSkip) continue;
		XLog(@"Adding color...");
		[colors addObject:[UIColor colorWithRed:[rgbs[0] floatValue] green:[rgbs[1] floatValue] blue:[rgbs[2] floatValue] alpha:1]];
		XLog(Xstr(@"Added %@", colors[colors.count - 1]));
	}
	for(UIColor *color in colors) {
		XLog(Xstr(@"Color 1: %@", color));
	}
	return [colors copy];
}

static void reloadPrefs() {
	NSDictionary* prefs = nil;
	CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.sassoty.bubblecolor"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if(keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, CFSTR("com.sassoty.bubblecolor"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if(!prefs) prefs = [NSDictionary new];
		CFRelease(keyList);
	}
	isEnabled = !prefs[@"Enabled"] ? YES : [prefs[@"Enabled"] boolValue];
	imcolor = !prefs[@"IMColor"] ? @"ORIGINAL" : [prefs[@"IMColor"] copy];
	smscolor = !prefs[@"SMSColor"] ? @"ORIGINAL" : [prefs[@"SMSColor"] copy];
	colorsArray = [NSArray arrayWithArray:getColorsArray()];
}

%hook CKGradientView

- (void)setColors:(id)arg1 {
	NSArray *colorsArray = getColorsArray();
	for(UIColor *color in colorsArray) {
		XLog(Xstr(@"Color 2: %@", color));
	}
	if(!isEnabled || !colorsArray) {
		%orig;
		return;
	}
	%orig(colorsArray);
}

%end

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
        (CFNotificationCallback)reloadPrefs,
        CFSTR("com.sassoty.bubblecolor/preferencechanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
