//
//  LockGlyphXPrefs.mm
//  Settings for LockGlyphX
//
//  (c)2017 evilgoldfish
//
//  feat. @sticktron
//

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <Preferences/PSTableCell.h>
#import <Social/Social.h>

#define kPrefsAppID CFSTR("com.evilgoldfish.lockglyphx")
#define kPrefsCurrentThemeKey CFSTR("currentTheme")
#define kSettingsChangedNotification CFSTR("com.evilgoldfish.lockglyphx.settingschanged")

#define kPrefsBundlePath 	@"/Library/PreferenceBundles/LockGlyphX.bundle"
#define kThemePath 			@"/Library/Application Support/LockGlyph/Themes/"

#define kDefaultTheme 		@"Default.bundle"
#define kDefaultThemeName 	@"Default (Apple Pay)"

#define kResetColorsAlertTag 	1
#define kApplyThemeAlertTag 	2

#define kThumbnailTag 	1
#define kTitleTag 		2

#define kHeaderHeight 148.0f

#define kTintColor [UIColor colorWithRed:1 green:0.17 blue:0.33 alpha:1]


@interface PSListController ()
- (void)clearCache;
@end


@interface LGShared : NSObject
+ (NSString *)localisedStringForKey:(NSString *)key;
+ (void)parseSpecifiers:(NSArray *)specifiers;
@end

@implementation LGShared
+ (NSString *)localisedStringForKey:(NSString *)key {
	NSString *englishString = [[NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/en.lproj", kPrefsBundlePath]] localizedStringForKey:key value:@"" table:nil];
	return [[NSBundle bundleWithPath:kPrefsBundlePath] localizedStringForKey:key value:englishString table:nil];
}
+ (void)parseSpecifiers:(NSArray *)specifiers {
	for (PSSpecifier *specifier in specifiers) {
		NSString *localisedTitle = [LGShared localisedStringForKey:specifier.properties[@"label"]];
		NSString *localisedFooter = [LGShared localisedStringForKey:specifier.properties[@"footerText"]];
		[specifier setProperty:localisedFooter forKey:@"footerText"];
		specifier.name = localisedTitle;
	}
}
@end


@implementation UIImage (Private)
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
	UIGraphicsBeginImageContextWithOptions(size, NO, 0);
	[image drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}
+ (UIImage *)imageWithImage:(UIImage *)image scaledToFitSize:(CGSize)size {
	CGFloat oldWidth = image.size.width;
	CGFloat oldHeight = image.size.height;
	// use longest side to determine scale factor
	CGFloat scaleFactor = (oldWidth > oldHeight) ? size.width / oldWidth : size.height / oldHeight;
	return [self imageWithImage:image scaledToSize:CGSizeMake(oldWidth * scaleFactor, oldHeight * scaleFactor)];
}
@end



// Main Controller -------------------------------------------------------------

@interface LockGlyphXPrefsController : PSListController
@end

@implementation LockGlyphXPrefsController
- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = @"";
	
	// add a heart button to the navbar
	// UIImage *heartImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/heart.png", kPrefsBundlePath]];
	// UIBarButtonItem *heartButton = [[UIBarButtonItem alloc] initWithImage:heartImage style:UIBarButtonItemStylePlain target:self action:@selector(showLove)];
	// heartButton.imageInsets = (UIEdgeInsets){2, 0, -2, 0};
	// heartButton.tintColor = kTintColor;
	// [self.navigationItem setRightBarButtonItem:heartButton];
}
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	return _specifiers;
}
// - (void)showLove {
// 	// send a nice tweet ;)
// 	NSString *tweet = @"Bless your lockscreen with LockGlyphX, free for iOS 10!";
// 	SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
// 	[composeController setInitialText:tweet];
// 	[self presentViewController:composeController animated:YES completion:nil];
// }
- (void)openTwitterForUser:(NSString *)user {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]]];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]]];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:user]]];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]]];
		
	} else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]]];
	}
}
- (void)twitterButton {
	[self openTwitterForUser:@"evilgoldfish01"];
}
- (void)twitterButton2 {
	[self openTwitterForUser:@"sticktron"];
}
- (void)twitterButton3 {
	[self openTwitterForUser:@"AppleBetasDev"];
}
- (void)issueButton {
	// [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/evilgoldfish/LockGlyphX/issues"]];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/sticktron/LockGlyphX/issues"]];
}
- (CGFloat)tableView:(id)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 2) {
		return 60;
	} else {
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
	}
}
- (CGFloat)tableView:(id)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return kHeaderHeight;
	} else if (section == 1 || section == 2) {
		return 4;
	} else {
		return [super tableView:tableView heightForHeaderInSection:section];
	}
}
- (CGFloat)tableView:(id)tableView heightForFooterInSection:(NSInteger)section {
	if (section == 0 || section == 1) {
		return 4;
	} else {
		return [super tableView:tableView heightForFooterInSection:section];
	}
}
- (id)tableView:(id)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		UIView *headerView = [[UIView alloc] initWithFrame:(CGRect){{0, 0}, {320, kHeaderHeight}}];
		headerView.backgroundColor = UIColor.clearColor;
		headerView.clipsToBounds = YES;
		
		// icon
		UIImage *icon = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Icon.png", kPrefsBundlePath]];
		UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
		iconView.frame = (CGRect){{0, 21}, iconView.frame.size};
		iconView.center = (CGPoint){headerView.center.x, iconView.center.y};
		iconView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:iconView];
		
		// title
		CGRect frame = CGRectMake(0, 54, headerView.bounds.size.width, 50);
		UILabel *tweakTitle = [[UILabel alloc] initWithFrame:frame];
		tweakTitle.font = [UIFont systemFontOfSize:46 weight:UIFontWeightUltraLight];
		tweakTitle.text = @"LockGlyphX";
		tweakTitle.textColor = UIColor.blackColor;
		tweakTitle.textAlignment = NSTextAlignmentCenter;
		tweakTitle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:tweakTitle];
		
		// subtitle
		CGRect subtitleFrame = CGRectMake(0, 102, headerView.bounds.size.width, 30);
		UILabel *tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
		tweakSubtitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightUltraLight];
		tweakSubtitle.text = @"custom lockscreen glyphs";
		tweakSubtitle.textColor = [UIColor colorWithWhite:0 alpha:0.33];
		tweakSubtitle.textAlignment = NSTextAlignmentCenter;
		tweakSubtitle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:tweakSubtitle];
		
		// beta tag
		UILabel *betaLabel = [[UILabel alloc] initWithFrame:headerView.bounds];
		betaLabel.font = [UIFont systemFontOfSize:120 weight:UIFontWeightBold];
		betaLabel.text = @"BETA";
		betaLabel.textColor = [UIColor colorWithRed:0.5 green:1 blue:0 alpha:0.05];
		betaLabel.textAlignment = NSTextAlignmentCenter;
		betaLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:betaLabel];
		
		return headerView;
	} else {
		return [super tableView:tableView viewForHeaderInSection:section];
	}
}
@end


// Behaviour Controller --------------------------------------------------------

@interface LockGlyphXPrefsBehaviourController : PSListController
@end

@implementation LockGlyphXPrefsBehaviourController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Behaviour" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"BEHAVIOUR_TITLE"]];
	return _specifiers;
}
@end


// Appearance Controller -------------------------------------------------------

@interface LockGlyphXPrefsAppearanceController : PSListController
@end

@implementation LockGlyphXPrefsAppearanceController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Appearance" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"APPEARANCE_TITLE"]];
	return _specifiers;
}
- (void)viewWillAppear:(BOOL)animated {
	// for libcolorpicker
	[self clearCache];
	[self reload];
	
	[super viewWillAppear:animated];
}
- (void)resetColors {
	CFPreferencesSetAppValue(CFSTR("primaryColor"), CFSTR("#BCBCBC:1.000000"), CFSTR("com.evilgoldfish.lockglyphx"));
    CFPreferencesSetAppValue(CFSTR("secondaryColor"), CFSTR("#777777:1.000000"), CFSTR("com.evilgoldfish.lockglyphx"));
    CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyphx"));
    CFNotificationCenterPostNotification(
    	CFNotificationCenterGetDarwinNotifyCenter(),
    	CFSTR("com.evilgoldfish.lockglyphx.settingschanged"),
    	NULL,
    	NULL,
    	YES
    );
    [self clearCache];
	[self reload];
}
@end


// Animations Controller -------------------------------------------------------

@interface LockGlyphXPrefsAnimationsController : PSListController
@end

@implementation LockGlyphXPrefsAnimationsController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Animations" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"ANIMATIONS_TITLE"]];
	return _specifiers;
}
@end


// Credits Controller ----------------------------------------------------------

@interface LockGlyphXPrefsCreditsController : PSListController
@end

@implementation LockGlyphXPrefsCreditsController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Credits" target:self];
	}
	// [LGShared parseSpecifiers:_specifiers];
	// [(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"ANIMATIONS_TITLE"]];
	return _specifiers;
}
@end


// Theme List Controller -------------------------------------------------------

@interface LockGlyphXThemeController : PSViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *themes;
@property (nonatomic, strong) NSString *selectedTheme;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) NSIndexPath *checkedIndexPath;
@end

@implementation LockGlyphXThemeController
- (instancetype)init {
	self = [super init];
	if (self) {
		self.title = @"Themes";
		
		_imageCache = [[NSCache alloc] init];
		_queue = [[NSOperationQueue alloc] init];
		_queue.maxConcurrentOperationCount = 4;
		
		// check prefs for selected theme
		CFPreferencesAppSynchronize(kPrefsAppID);
		CFPropertyListRef value = CFPreferencesCopyAppValue(kPrefsCurrentThemeKey, kPrefsAppID);
		_selectedTheme = (value) ? (NSString *)CFBridgingRelease(value) : kDefaultTheme;
	}
	return self;
}
- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 60.0f;
	[self.view addSubview:self.tableView];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateThemeList];
}
- (void)viewWillDisappear:(BOOL)animated {
	[self.imageCache removeAllObjects];
	[super viewWillDisappear:animated];
}
- (void)updateThemeList {
	NSDictionary *defaultTheme = @{ @"theme":kDefaultTheme, @"name":kDefaultThemeName };
	NSMutableArray *themes = [NSMutableArray arrayWithArray:@[ defaultTheme ]];
	
	NSMutableArray *folders = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:kThemePath error:nil] mutableCopy];
    for (int i = 0; i < folders.count; i++) {
    	NSString *path = [folders objectAtIndex:i];
		if (![path isEqualToString:kDefaultTheme]) {
			NSString *name = [path stringByReplacingOccurrencesOfString:@".bundle" withString:@""];
			[themes addObject:@{ @"theme":path, @"name":name }];
		}
    }
	
	self.themes = themes;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.themes.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CustomCellIdentifier = @"CustomCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CustomCellIdentifier];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									  reuseIdentifier:CustomCellIdentifier];
		cell.opaque = YES;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		// thumbnail
		// UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 5, 64, 64)];
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 5, 48, 48)];
		// imageView.opaque = YES;
		imageView.opaque = NO;
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		// UIImage *bgTile = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/tile99cc.png", kPrefsBundlePath]];
		// imageView.backgroundColor = [UIColor colorWithPatternImage:bgTile];
		imageView.backgroundColor = UIColor.clearColor;
		
		// imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
		// imageView.layer.borderWidth = 0.5;
		
		imageView.layer.shadowOffset = CGSizeMake(0, 1);
		imageView.layer.shadowRadius = 1;
		imageView.layer.shadowColor = UIColor.blackColor.CGColor;
		imageView.layer.shadowOpacity = 0.4;
		
		imageView.tag = kThumbnailTag;
		[cell.contentView addSubview:imageView];
		
		// title
		CGRect frame = CGRectMake(94, 5, cell.contentView.bounds.size.width - 94, 64);
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:frame];
		titleLabel.opaque = YES;
		titleLabel.font = [UIFont systemFontOfSize:14];
		titleLabel.textColor = UIColor.blackColor;
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		titleLabel.tag = kTitleTag;
		[cell.contentView addSubview:titleLabel];
	}
	
	// populate cell...
	
	NSDictionary *themeInfo = self.themes[indexPath.row];
	UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:kTitleTag];
	titleLabel.text = themeInfo[@"name"];
	UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kThumbnailTag];
	
	if ([themeInfo[@"name"] isEqualToString:kDefaultThemeName]) {
		imageView.hidden = YES;
		CGRect frame = titleLabel.frame;
		frame.origin.x = 15;
		titleLabel.frame = frame;
		
	} else {
		imageView.hidden = NO;
		CGRect frame = titleLabel.frame;
		frame.origin.x = 94;
		titleLabel.frame = frame;
		
		// get thumbnail from cache, or create and cache new one...
		NSString *path = [NSString stringWithFormat:@"%@/%@/IdleImage.png", kThemePath, themeInfo[@"theme"]];
		UIImage *thumbnail = [self.imageCache objectForKey:path];
		if (thumbnail) {
			imageView.image = thumbnail;
		} else {
			// image is not yet cached
			[self.queue addOperationWithBlock:^{
				UIImage *image = [UIImage imageWithContentsOfFile:path];
				if (image) {
					// add to cache
					[self.imageCache setObject:image forKey:path];
					
					// display in cell (using main thread)
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
						if (cell) {
							UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kThumbnailTag];
							imageView.image = image;
						}
					}];
				} else {
					// image not found
				}
			}];
		}
	}
	
	// do we know which row should be checked?
	if (!self.checkedIndexPath) {
		// not yet; is it this row?
		if ([themeInfo[@"theme"] isEqualToString:self.selectedTheme]) {
			self.checkedIndexPath = indexPath;
		}
	}
	
	if ([indexPath isEqual:self.checkedIndexPath]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
		// cell is already selected
	} else {
		// un-check previously checked cell
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:self.checkedIndexPath];
		oldCell.accessoryType = UITableViewCellAccessoryNone;
		
		// check this cell
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		self.checkedIndexPath = indexPath;
		
		// get the image info
		NSDictionary *themeInfo;
		themeInfo = self.themes[indexPath.row];
		
		// save selection to prefs
		self.selectedTheme = themeInfo[@"theme"];
		CFPreferencesSetAppValue(kPrefsCurrentThemeKey, (CFStringRef)self.selectedTheme, kPrefsAppID);
		CFPreferencesAppSynchronize(kPrefsAppID);
		
		// notify tweak
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kSettingsChangedNotification, NULL, NULL, true);
	}
}
@end


// Custom Cells ----------------------------------------------------------------

@interface LGXButtonCell : PSTableCell
@end

@implementation LGXButtonCell
- (void)layoutSubviews {
	[super layoutSubviews];
	[self.textLabel setTextColor:UIColor.blackColor];
}
@end


@interface LGXSwitchCell : PSSwitchTableCell
@end

@implementation LGXSwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:kTintColor];
	}
	return self;
}
@end


@interface LGXThemeLinkCell : PSTableCell
@end

@implementation LGXThemeLinkCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	// overridde the cell style because we want a detail label on the right side ...
	if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier specifier:specifier]) {
		NSString *selectedTheme;
		
		// check prefs for selected theme
		CFPreferencesAppSynchronize(kPrefsAppID);
		CFPropertyListRef value = CFPreferencesCopyAppValue(kPrefsCurrentThemeKey, kPrefsAppID);
		selectedTheme = (value) ? (NSString *)CFBridgingRelease(value) : kDefaultThemeName;
		
		self.detailTextLabel.text = selectedTheme;
	}
	return self;
}
@end
