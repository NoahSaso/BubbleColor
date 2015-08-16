#import <Preferences/PSViewController.h>

#define kName @"BubbleColor"
#import "../global.h"

#define BCSliderRed 673
#define BCSliderGreen 674
#define BCSliderBlue 675

#define BCAlertViewTagSave 673
#define BCAlertViewTagLoad 674
#define BCAlertViewTagDelete 675
#define BCAlertViewTagConfirmDelete 676

#define BCColorPath @"/User/Library/BubbleColor/"

@interface CustomColorListController: PSViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
	UITableView* table;
	int colorSections;
	NSMutableArray* colors;
	NSString* fileName;
	NSString* deleteFileName;
}
@end

@implementation CustomColorListController

- (void)viewDidLoad {

	[super viewDidLoad];

	if(![[NSFileManager defaultManager] fileExistsAtPath:BCColorPath]) {
		NSError* error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:BCColorPath withIntermediateDirectories:NO attributes:nil error:&error];
		if(error) {
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:Xstr(@"Error creating folder: '%@'. Please either fix this error or manually create the directory. Error: '%@'.", BCColorPath, [error description]) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
		}
	}

	table = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
	table.delegate = self;
	table.dataSource = self;

	colorSections = 0;
	fileName = @"";
	colors = [NSMutableArray new];

	[self.view addSubview:table];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.section == 0) {
		switch(indexPath.row) {
			case 0:
				[self savePreset];
				break;
			case 1:
				[self loadPreset];
				break;
			case 2:
				[self viewPresets];
				break;
			case 3:
				[self deletePreset];
				break;
			default:
				break;
		}
	}else if(indexPath.section == 1) {
		switch(indexPath.row) {
			case 0:
				[self newColor];
				break;
			case 1:
				[self clearColors];
				break;
			default:
				break;
		}
	}else {
		if(indexPath.row == 3)
			[self removeColor:indexPath.section];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return colorSections + 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0) return 4;
	if(section == 1) return 3;
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0) return @"Presets";
	if(section == 1) return @"Colors";
	return [NSString stringWithFormat:@"Color %d", (int)section - 1];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if(!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	}

	for(UIView* view in [cell subviews]) {
		if([view isKindOfClass:[UISlider class]])
			[view removeFromSuperview];
	}
	cell.backgroundView = nil;
	cell.textLabel.text = nil;

	if(indexPath.section == 0) {
		if(indexPath.row == 0) cell.textLabel.text = @"Save as Preset";
		if(indexPath.row == 1) cell.textLabel.text = @"Load Preset";
		if(indexPath.row == 2) cell.textLabel.text = @"View Presets";
		if(indexPath.row == 3) cell.textLabel.text = @"Delete Preset";
	}else if(indexPath.section == 1) {
		if(indexPath.row == 0) cell.textLabel.text = @"New Color";
		if(indexPath.row == 1) cell.textLabel.text = @"Clear Colors";
		if(indexPath.row == 2) {
			CAGradientLayer* maskLayer = [CAGradientLayer layer];
			maskLayer.frame = cell.bounds;
			NSMutableArray* cgColors = [NSMutableArray new];
			for(NSDictionary* dict in colors)
				[cgColors addObject:(id)[UIColor colorWithRed:[dict[@"red"] floatValue] green:[dict[@"green"] floatValue] blue:[dict[@"blue"] floatValue] alpha:1].CGColor];
			if(cgColors.count == 1) [cgColors addObject:cgColors[0]];
			maskLayer.colors = [cgColors copy];

			maskLayer.startPoint = CGPointMake(0.0, 0.5);
			maskLayer.endPoint = CGPointMake(1.0, 0.5);

			[cell setBackgroundView:[[UIView alloc] init]];
			[cell.backgroundView.layer insertSublayer:maskLayer atIndex:0];
		}
	}else {
		if(indexPath.row == 3) {
			cell.textLabel.text = @"Remove Color";
			return cell;
		}
		UISlider* slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width - 40, cell.bounds.size.height)];
		[slider addTarget:self action:@selector(updatedSlider:) forControlEvents:UIControlEventValueChanged];
		slider.minimumValue = 0.f;
		slider.maximumValue = 1.f;
		slider.continuous = YES;
		NSMutableDictionary* colorDictionary = colors[indexPath.section - 2];
		if(indexPath.row == 0) {
			slider.value = [colorDictionary[@"red"] floatValue];
			slider.minimumTrackTintColor = [UIColor redColor];
			slider.tag = BCSliderRed;
		}else if(indexPath.row == 1) {
			slider.value = [colorDictionary[@"green"] floatValue];
			slider.minimumTrackTintColor = [UIColor colorWithRed:0 green:0.7 blue:0 alpha:1];
			slider.tag = BCSliderGreen;
		}else if(indexPath.row == 2) {
			slider.value = [colorDictionary[@"blue"] floatValue];
			slider.minimumTrackTintColor = [UIColor blueColor];
			slider.tag = BCSliderBlue;
		}
		[cell addSubview:slider];
	}

	return cell;

}

- (void)updatedSlider:(UISlider *)slider {

	//XLog(Xstr(@"updated slider: %f", slider.value));

	int colorIndex = [table indexPathForCell:(UITableViewCell *)slider.superview].section - 2;
	if(colorIndex >= [colors count]) return;

	NSMutableDictionary* colorDictionary = colors[colorIndex];
	if(!colorDictionary) colorDictionary = [NSMutableDictionary new];

	NSString* key = (slider.tag == BCSliderRed ? @"red" : (slider.tag == BCSliderGreen ? @"green" : @"blue"));
	colorDictionary[key] = @(slider.value);

	colors[colorIndex] = colorDictionary;

	[table reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 0) return;
	NSString* filePath;
	if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
		fileName = [[alertView textFieldAtIndex:0].text copy];
		filePath = [BCColorPath stringByAppendingPathComponent:fileName];
	}
	if(alertView.tag == BCAlertViewTagSave) {
		if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
			if(buttonIndex == 1) {
				// Save (no overwrite)
				UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:Xstr(@"File exists at path: '%@'.", filePath) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[alert show];
			}else if(buttonIndex == 2) {
				// Save (and overwrite)
				[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
			}
		}
		NSString* finalText = @"";
		for(NSDictionary* dict in colors) {
			XLog(Xstr(@"Vals: %.01f %.01f %.01f", [dict[@"red"] floatValue], [dict[@"green"] floatValue], [dict[@"blue"] floatValue]));
			NSString* red = Xstr(@"%.01f", [dict[@"red"] floatValue]);
			NSString* green = Xstr(@"%.01f", [dict[@"green"] floatValue]);
			NSString* blue = Xstr(@"%.01f", [dict[@"blue"] floatValue]);
			NSString* line = Xstr(@"%@,%@,%@\n", red, green, blue);
			finalText = [finalText stringByAppendingString:line];
		}
		[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
		NSError* error = nil;
		if([finalText writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:Xstr(@"Saved to '%@'", filePath) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
		}else {
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:Xstr(@"Error saving to '%@'. Error: '%@'", filePath, [error description]) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
		}
	}else if(alertView.tag == BCAlertViewTagLoad) {
		if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:Xstr(@"File doesn't exist at path: '%@'", filePath) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
			return;
		}
		colorSections = 0;
		NSArray *lines = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
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
			NSMutableDictionary* colorDict = [NSMutableDictionary new];
			colorDict[@"red"] = @([rgbs[0] floatValue]);
			colorDict[@"green"] = @([rgbs[1] floatValue]);
			colorDict[@"blue"] = @([rgbs[2] floatValue]);
			colors[colorSections++] = colorDict;
		}
		[table reloadData];
	}else if(alertView.tag == BCAlertViewTagDelete) {
		deleteFileName = fileName;
		UIAlertView* confirmDeleteAlert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:@"Are you sure?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes, Delete", nil];
		confirmDeleteAlert.tag = BCAlertViewTagConfirmDelete;
		[confirmDeleteAlert show];
	}else if(alertView.tag == BCAlertViewTagConfirmDelete) {
		if(XIS_EMPTY(deleteFileName)) return;
		NSString* deleteFilePath = filePath = [BCColorPath stringByAppendingPathComponent:deleteFileName];
		NSError* error = nil;
		[[NSFileManager defaultManager] removeItemAtPath:deleteFilePath error:&error];
		if(error) {
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:Xstr(@"Error deleting '%@'. Error: '%@'", deleteFilePath, [error description]) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
			[alert show];
		}
		deleteFileName = nil;
	}
}

// Presets

- (void)savePreset {

	XLog(@"save preset");

	UIAlertView* saveAlert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:@"Enter color preset name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", @"Save + Overwrite", nil];
	if(!XIS_EMPTY(fileName)) [saveAlert textFieldAtIndex:0].text = fileName;
	saveAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	saveAlert.tag = BCAlertViewTagSave;
	[saveAlert show];

}

- (void)loadPreset {

	XLog(@"load preset");

	UIAlertView* loadAlert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:@"Enter color preset to load" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Load", nil];
	loadAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	loadAlert.tag = BCAlertViewTagLoad;
	[loadAlert show];

}

- (void)viewPresets {

	XLog(@"view presets");

	NSString* fileString = @"";
	for(NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:BCColorPath error:nil])
		fileString = [fileString stringByAppendingString:Xstr(@"%@\n", file)];
	fileString = [fileString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:fileString delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[alert show];

}

- (void)deletePreset {

	XLog(@"delete preset");

	UIAlertView* deleteAlert = [[UIAlertView alloc] initWithTitle:@"BubbleColor" message:@"Enter color preset to delete" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
	deleteAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	deleteAlert.tag = BCAlertViewTagDelete;
	[deleteAlert show];

}

// Colors

- (void)newColor {

	XLog(@"new color");

	colors[colorSections++] = [NSMutableDictionary new];

	[table reloadData];
	[table reloadSections:[NSIndexSet indexSetWithIndex:(colorSections + 2) - 1] withRowAnimation:UITableViewRowAnimationTop]; // subtract one because it's the index

}

- (void)clearColors {

	XLog(@"clear colors");

	int prevSections = colorSections;
	colorSections = 0;
	colors = [NSMutableArray new];

	[table beginUpdates];
	[table deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, prevSections)] withRowAnimation:UITableViewRowAnimationTop];
	[table endUpdates];

	[table reloadData];

}

- (void)removeColor:(int)section {

    XLog(@"remove color");

    colorSections--;
    [colors removeObjectAtIndex:section - 2];

    [table beginUpdates];
	[table deleteSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationTop];
	[table endUpdates];

	[table reloadData];

}

@end