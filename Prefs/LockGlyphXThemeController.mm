//
//  LockGlyphXThemeController.mm
//  Theme Chooser
//
//  (c)2017 evilgoldfish
//
//  feat. @sticktron
//

#import "Common.h"
#import <Preferences/PSViewController.h>


#define kThumbnailTag 	1
#define kTitleTag 		2


@implementation UIImage (LockGlyphX)
+ (UIImage *)imageFromImageView:(UIImageView *)imageView {
	UIGraphicsBeginImageContextWithOptions(imageView.frame.size, NO, 0); // use screen scale factor
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextRotateCTM(context, 2 * M_PI);
    [imageView.layer renderInContext:context];
    UIImage *image =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
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
	
	// tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = kTintColor;
	
	[self updateThemeList];
}
- (void)viewWillDisappear:(BOOL)animated {
	[self.imageCache removeAllObjects];
	
	// un-tint navbar
	self.navigationController.navigationController.navigationBar.tintColor = nil;
	
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
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 5, 48, 48)];
		imageView.opaque = YES;
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.backgroundColor = UIColor.whiteColor;
		imageView.tag = kThumbnailTag;
		[cell.contentView addSubview:imageView];
		
		// title
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(78, 20, cell.contentView.bounds.size.width - 78, 20)];
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
			// image is not yet cached, cache it now (on background thread)
			[self.queue addOperationWithBlock:^{
				UIImage *image = [UIImage imageWithContentsOfFile:path];
				if (image) {
					
					// Bake a CALayer shadow into the thumbnail, using an ImageView ...
					
					UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
					imageView.contentMode = UIViewContentModeCenter;
					imageView.layer.shadowOffset = CGSizeMake(0, 1);
					imageView.layer.shadowRadius = 1;
					imageView.layer.shadowColor = UIColor.blackColor.CGColor;
					imageView.layer.shadowOpacity = 0.4;
					
					// add some padding for the shadows
					CGRect frame = imageView.frame;
					frame.size.width += 4;
					frame.size.height += 4;
					imageView.frame = frame;
					
					image = [UIImage imageFromImageView:imageView];
					
					
					// add the new image to cache
					[self.imageCache setObject:image forKey:path];
					
					// update the cell (on main thread)
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
