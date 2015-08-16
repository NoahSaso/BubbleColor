#import <Preferences/Preferences.h>

#define kName @"BubbleColor"
#import "../global.h"

#import <notify.h>

#define BCBundlePath @"/Library/PreferenceBundles/BubbleColor.bundle"

#define appID CFSTR("com.sassoty.bubblecolor")

@interface PSSpecifier (BubbleColor)
- (void)setValues:(NSArray *)values titles:(NSArray *)titles shortTitles:(NSArray *)shortTitles;
@end

@interface BubbleColorListController: PSListController {
}
@end

@implementation BubbleColorListController

- (id)specifiers {
	if(_specifiers == nil) {
		NSMutableArray *tempArray = [[self loadSpecifiersFromPlistName:@"BubbleColor" target:self] mutableCopy];
		NSMutableArray *colors = [NSMutableArray new];
		for(NSString *i in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/BubbleColor/" error:nil])
			[colors addObject:i];
		// IM Color
		PSSpecifier *imColorSpecifier = [PSSpecifier preferenceSpecifierNamed:@"iMessage Color" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:PSListItemsController.class cell:PSLinkListCell edit:nil];
		[imColorSpecifier setProperty:@(YES) forKey:@"enabled"];
		[imColorSpecifier setValues:colors titles:colors shortTitles:colors];
		[imColorSpecifier setIdentifier:@"IMColor"];
		// SMS Color
		PSSpecifier *smsColorSpecifier = [PSSpecifier preferenceSpecifierNamed:@"SMS Color" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:PSListItemsController.class cell:PSLinkListCell edit:nil];
		[smsColorSpecifier setProperty:@(YES) forKey:@"enabled"];
		[smsColorSpecifier setValues:colors titles:colors shortTitles:colors];
		[smsColorSpecifier setIdentifier:@"SMSColor"];
		// Insert into array
		[tempArray insertObject:imColorSpecifier atIndex:4];
		[tempArray insertObject:smsColorSpecifier atIndex:5];
		_specifiers = [tempArray copy];
	}
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	NSMutableArray *colors = [NSMutableArray new];
	for(NSString *i in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/User/Library/BubbleColor/" error:nil])
		[colors addObject:i];
	PSSpecifier* imColorSpecifier = [self specifierAtIndex:4];
	[imColorSpecifier setValues:colors titles:colors shortTitles:colors];
	[self reloadSpecifierAtIndex:4];
	PSSpecifier* smsColorSpecifier = [self specifierAtIndex:5];
	[smsColorSpecifier setValues:colors titles:colors shortTitles:colors];
	[self reloadSpecifierAtIndex:5];
}

- (id)getValueForSpecifier:(PSSpecifier *)specifier {
    return (__bridge NSString *)CFPreferencesCopyAppValue((__bridge CFStringRef)specifier.identifier, appID) ?: nil;
}

- (void)setValue:(id)value forSpecifier:(PSSpecifier *)specifier {
	// Remove value
	CFPreferencesSetValue((__bridge CFStringRef)specifier.identifier, NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    // Set value
	CFPreferencesSetValue((__bridge CFStringRef)specifier.identifier, (__bridge CFPropertyListRef)value, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    // Reload stuff
    notify_post("com.sassoty.bubblecolor/preferencechanged");
    [self.navigationController popViewControllerAnimated:YES];
    [self reloadSpecifier:specifier];
}

@end
