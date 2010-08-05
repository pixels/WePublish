//
//  WePublishViewController.m
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/26.
//  Copyright 3di 2010. All rights reserved.
//

#import "WePublishViewController.h"
#import "BookCollection.h"
#import "BookInfo.h"
#import "LogoViewCtrl.h"
#import "XMLController.h"
#import "ListViewCtrl.h"
#import "BuyViewCtrl.h"
#import "DetailViewCtrl.h"
#import "ReadViewCtrl.h"
#import "LoginViewCtrl.h"
#import "WindowModeType.h"
#import "Define.h"
#import "DirectionType.h"
#import "FileDownloader.h"
#import "ZipArchive.h"
#import "Util.h"

//#define BOOK_ANIMATION_SETUP
#define W_COUNT_A 4
#define H_COUNT_A 4
#define W_COUNT_B 5
#define H_COUNT_B 3
#define LOGO_ANIM_ID @"logo_anim"
#define SET_BOOK_ANIM_ID @"set_book_anim"
#define CHANGE_ORIENTATION_ANIM_ID @"change_orientation_anim"
#define DETAIL_ANIM_ID @"detail_anim"
#define DETAIL_TO_SELECT_ANIM_ID @"detail_to_select_anim"
#define DETAIL_TO_READ_ANIM_ID @"detail_to_anim_anim"
#define READ_TO_SELECT_ANIM_ID @"read_to_select_anim"

@implementation WePublishViewController
@synthesize scrollView = _scrollView;
@synthesize activitiyView = _activitiyView;
@synthesize bookBarButton = _bookBarButton;
@synthesize listBarButton = _listBarButton;
@synthesize trashBarButton = _trashBarButton;
@synthesize buyBarButton = _buyBarButton;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	_tmpDlDic = [[NSMutableDictionary alloc] init];
	_aBgList = [[NSMutableArray alloc] init];
	_bBgList = [[NSMutableArray alloc] init];
	_buttons = [[NSMutableArray alloc] init];
	_windowMode = MODE_NONE;
	_xmlCtrl = [[XMLController alloc] init];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(onLogoEndSelect:) name:LOGO_END_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onDetailDisappearSelect:) name:DETAIL_DISAPPEAR_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onReadToSelect:) name:READ_TO_SELECT_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onDetailToReadSelect:) name:DETAIL_TO_READ_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onListToDetailSelect:) name:LIST_TO_DETAIL_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onParseEndSelect:) name:PARSE_END_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onDLBookSuccessSelect:) name:DLBOOK_SUCCESS_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onDLBookErrorSelect:) name:DLBOOK_ERROR_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onAuthenticationSelect:) name:AUTHENTICATION_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onLoginFinishSelect:) name:LOGIN_FINISH_END_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onBookmarkSaveSelect:) name:BOOKMARK_SAVE_EVENT object:nil];

	[self initDirectory];
	
	LogoViewCtrl *ctrl = [[LogoViewCtrl alloc] initWithNibName:@"LogoView" bundle:nil];
	_logoView = [ctrl retain];
	[self.view addSubview:_logoView.view];
	[ctrl release];
	
	// Bookmarkがあるならロード
	_bookmarkPath = [[NSString alloc] initWithFormat:@"%@/%@/%@", [Util getLocalDocument], XML_DIRECTORY, BOOKMARK_FILENAME];
	if ([Util isExist:_bookmarkPath]) {
		_bookmarkDic = [[NSMutableDictionary alloc] initWithContentsOfFile:_bookmarkPath];
	}
	else {
		_bookmarkDic = [[NSMutableDictionary alloc] init];
	}
//	NSLog(@"Bookmark path: %@", _bookmarkPath);
	
	[self setMenuBarItems:NO list:NO trash:NO buy:NO];
	[self logoToTop];
}

- (void)initDirectory {
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *path;
	
	path = [[NSString alloc] initWithFormat:@"%@/%@", [Util getLocalDocument], XML_DIRECTORY];
	[fm createDirectoryAtPath:path attributes:nil];
	[path release];
	
	path = [[NSString alloc] initWithFormat:@"%@/%@", [Util getLocalDocument], BOOK_DIRECTORY];
	[fm createDirectoryAtPath:path attributes:nil];	
	[path release];
}

- (void)initBooks {
	
	NSInteger book_count = [_bookCollection count];
	NSInteger i, page, h_line, w_line;
	NSInteger HxW = H_COUNT_A * W_COUNT_A;
	UIImage *image;
	NSString *documentDir;
	NSString *image_path;
	UIButton* btn;
	BookInfo *info;
	
	for (i = 0; i < book_count; i++) {
		page = i / HxW;
		w_line = (i % HxW) % W_COUNT_A;
		h_line = (i % HxW) / W_COUNT_A;
		
		info = [_bookCollection getAt:i];
		
		documentDir = [[NSString alloc] initWithFormat:@"%@/%@/%@", [Util getLocalDocument], BOOK_DIRECTORY, info.uuid];
		image_path = [Util makeBookPathFormat:documentDir pageNo:1 extension:BOOK_EXTENSION];
//		NSLog(@"image_path: %@", image_path);
		if (image_path) {
			image = [[UIImage alloc] initWithContentsOfFile:image_path];
			if (image) {
				btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
				[btn.imageView setContentMode:UIViewContentModeScaleAspectFit];
				[btn setShowsTouchWhenHighlighted:YES];
				[btn setFrame:CGRectMake(0, 0, 146, 205)];
				[btn setTitle:nil forState:UIControlStateNormal];
				[btn setTag:i];
				[btn setBackgroundImage:image forState:UIControlStateNormal];
				[btn addTarget:self action:@selector(onBookClick:) forControlEvents:UIControlEventTouchUpInside];
				[_scrollView addSubview:btn];
				[_buttons addObject:btn];
				[image release];
			}		
			[image_path release];
		}
	}
	[documentDir release];
}

- (void)initAnimation:(NSString *)animationID duration:(NSTimeInterval)duration {
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:animationID context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector:@selector(onAnimationEnd:finished:context:)];	
}

// Logo画面からTopへ
- (void)logoToTop {
	NSTimer *timer;
	timer = [NSTimer scheduledTimerWithTimeInterval:1.00 * 3
											 target:self
										   selector:@selector(onLogoTimer:)
										   userInfo:nil
											repeats:NO];
}

// Alertを表示する
- (void)showAlert:(NSString *)title message:(NSString *)message btn1:(NSString *)btn1 btn2:(NSString *)btn2 tag:(NSUInteger)tag {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:self
										  cancelButtonTitle:btn1
										  otherButtonTitles:btn2, nil];
	[alert setTag:tag];
	[alert show];
	[alert release];
}

// 全てのデータを削除する
- (void)trashAllData {
	[self setMenuBarItems:NO list:NO trash:NO buy:NO];
	[self releaseBooks:NO];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [[NSString alloc] initWithFormat:@"%@/%@", [Util getLocalDocument], XML_DIRECTORY];
	[fm removeItemAtPath:path error:nil];
	[path release];
	
	[self initDirectory];
	[self showAlert:nil message:RELOAD_DATA_WARNING_MESSAGE btn1:@"NO" btn2:@"YES" tag:RELOAD_DATA_ALERT_TAG];
}

- (void)updateXML {
	_updating = YES;

	[_xmlCtrl update:UPDATE_URL];
}

// XMLの更新終了
- (void)updateXMLFinish {
	[self reloadBooks];
	[self setMenuBarItems:NO list:YES trash:YES buy:YES];
	
	_activitiyView.hidden = YES;
	_updating = NO;
}

- (BOOL)startToDownloadBookFromQueue {
	
	if ([_tmpDlDic count] > 0) {
		
		BookInfo *info;
		for (id key in _tmpDlDic) {
			info = [_tmpDlDic objectForKey:key];
			FileDownloader *fd = [[FileDownloader alloc] init];
			[fd download:info.uuid url:info.url];
			[fd release];
			
			// 一冊ずつDL
			break;
		}
	}
	
	else {
		return NO;
	}
	
	return YES;
}

- (void)setBooks:(BOOL)animation {

	_scrollView.contentOffset = CGPointMake(0, 0);
	
#ifdef BOOK_ANIMATION_SETUP
	if (animation == YES)
		[self initAnimation:SET_BOOK_ANIM_ID duration:0.2f];
#endif
	
	NSInteger page, h_line, w_line;
	NSInteger HxW_A = H_COUNT_A * W_COUNT_A;
	NSInteger HxW_B = H_COUNT_B * W_COUNT_B;
	NSInteger i = 0;
	for (UIButton *btn in _buttons) {
		CGRect frame = btn.frame;
		if (_windowMode == MODE_A) {
			page = i / HxW_A;
			w_line = (i % HxW_A) % W_COUNT_A;
			h_line = (i % HxW_A) / W_COUNT_A;
//			frame.origin.x = 140 * w_line + 42 + page * WINDOW_AW;
//			frame.origin.y = 240 * h_line + 112;
			frame.origin.x = 180 * w_line + 42 + page * WINDOW_AW;
			frame.origin.y = 240 * h_line + 80;
		}
		else {
			page = i / HxW_B;
			w_line = (i % HxW_B) % W_COUNT_B;
			h_line = (i % HxW_B) / W_COUNT_B;
//			frame.origin.x = 160 * w_line + 52 + page * WINDOW_BW;
//			frame.origin.y = 234 * h_line + 106;
			frame.origin.x = 190 * w_line + 60 + page * WINDOW_BW;
			frame.origin.y = 234 * h_line + 74;
		}
		
		btn.frame = frame;
		i++;
	}
	
	
#ifdef BOOK_ANIMATION_SETUP
	if (animation == YES)
		[UIView commitAnimations];
#endif

}

- (void)releaseBooks:(BOOL)scrollHidden {
	for (UIButton *button in _buttons) {
		button.imageView.image = nil;
		[button removeFromSuperview];
	}
	[_buttons removeAllObjects];
	
	_scrollView.hidden = scrollHidden;
	_scrollView.scrollEnabled = NO;
}

- (void)changeOrientation:(BOOL)animation {

	NSInteger pageCount = 1;
	NSInteger i;
	UIImageView *imageView;
	NSString *path;
	UIImage *image;
	CGRect frame;
	
	if (_windowMode == MODE_A) {
		pageCount = [_bookCollection count] / (H_COUNT_A * W_COUNT_A) + 1;
	}
	else {
		pageCount = [_bookCollection count] / (H_COUNT_B * W_COUNT_B) + 1;
	}

	for (i = 0; i < pageCount; i++) {
		imageView = [[UIImageView alloc] init];
		imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		frame = imageView.frame;
		
		if (_windowMode == MODE_A) {
			[_aBgList addObject:imageView];
			path = [[NSBundle mainBundle] pathForResource:@"bk_a" ofType:@"png"];
			frame.size.width = WINDOW_AW;
			frame.size.height = WINDOW_AH;
			frame.origin.x = WINDOW_AW * i;
		}
		else {
			[_bBgList addObject:imageView];
			path = [[NSBundle mainBundle] pathForResource:@"bk_b" ofType:@"png"];
			frame.size.width = WINDOW_BW;
			frame.size.height = WINDOW_BH;
			frame.origin.x = WINDOW_BW * i;
		}
		
		image = [[UIImage alloc] initWithContentsOfFile:path];
		imageView.image = image;
		imageView.alpha = 0;
		imageView.frame = frame;
		[_scrollView insertSubview:imageView atIndex:0];
		[image release];
	}
	
	frame = _scrollView.frame;
	frame.size.width = WINDOW_BW;
	frame.size.height = WINDOW_AH;
	_scrollView.frame = frame;
	
	if (animation == YES)
		[self initAnimation:CHANGE_ORIENTATION_ANIM_ID duration:0.2f];
	
	frame = _scrollView.frame;
	if (_windowMode == MODE_A) {
		frame.size.width = WINDOW_AW;
		frame.size.height = WINDOW_AH;
		_scrollView.contentSize = CGSizeMake(WINDOW_AW * pageCount, WINDOW_AH);
		for (UIImageView *v in _aBgList) {
			v.alpha = 1;
		}
		for (UIImageView *v in _bBgList) {
			v.alpha = 0;
		}
	}
	else {
		frame.size.width = WINDOW_BW;
		frame.size.height = WINDOW_BH;
		_scrollView.contentSize = CGSizeMake(WINDOW_BW * pageCount, WINDOW_BH);
		for (UIImageView *v in _bBgList) {
			v.alpha = 1;
		}
		for (UIImageView *v in _aBgList) {
			v.alpha = 0;
		}
	}
	frame.origin.x = 0;
	frame.origin.y = -20;
	_scrollView.frame = frame;
	
#ifdef BOOK_ANIMATION_SETUP
	for (UIButton *btn in _buttons) {
		CGRect frame = btn.frame;
		if (_windowMode == MODE_A) {
			frame.origin.x = 42;
			frame.origin.y = 112;
		}
		else {
			frame.origin.x = 52;
			frame.origin.y = 106;
		}
		
		btn.frame = frame;
	}
#endif	
	
	if (animation == YES) {
		[UIView commitAnimations];
	} else {
		[self setBooks:NO];
	}

}

- (void)reloadBooks {
	[self initBooks];
	[self changeOrientation:NO];
	_scrollView.hidden = NO;
	_scrollView.scrollEnabled = YES;
}

- (void)setMenuBarItems:(BOOL)book list:(BOOL)list trash:(BOOL)trash buy:(BOOL)buy {
	
	self.bookBarButton.style = (book == YES) ? UIBarButtonItemStyleBordered : UIBarButtonItemStylePlain;
	self.bookBarButton.enabled = book;
	
	self.listBarButton.style = (list == YES) ? UIBarButtonItemStyleBordered : UIBarButtonItemStylePlain;
	self.listBarButton.enabled = list;
	
	self.trashBarButton.style = (trash == YES) ? UIBarButtonItemStyleBordered : UIBarButtonItemStylePlain;
	self.trashBarButton.enabled = trash;
	
	self.buyBarButton.style = (buy == YES) ? UIBarButtonItemStyleBordered : UIBarButtonItemStylePlain;
	self.buyBarButton.enabled = buy;
}

// 詳細の表示
- (void)showDetail:(NSInteger)bookIndex {
	DetailViewCtrl *ctrl;
	if (_windowMode == MODE_A)
		ctrl = [[DetailViewCtrl alloc] initWithNibName:@"DetailViewA" bundle:nil];
	else
		ctrl = [[DetailViewCtrl alloc] initWithNibName:@"DetailViewB" bundle:nil];
	
	_detailViewCtrl = [ctrl retain];
	[_detailViewCtrl.view setAlpha:0];
	
	BookInfo *info = [_bookCollection getAt:bookIndex];
	NSString *documentDir = [[NSString alloc] initWithFormat:@"%@/%@/%@", [Util getLocalDocument], BOOK_DIRECTORY, info.uuid];
	NSString *image_path = [Util makeBookPathFormat:documentDir pageNo:1 extension:BOOK_EXTENSION];
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:image_path];
//	NSLog(@"author: %@ title: %@ review: %@ path: %@", info.author, info.title, info.review, image_path);
	if (image) {
		_detailViewCtrl.frontImage.image = image;
		_detailViewCtrl.titleText.text = [info.title retain];
		_detailViewCtrl.authorText.text = [info.author retain];
		_detailViewCtrl.reviewView.text = [info.review retain];
		[image release];
	}
	[image_path release];
	[documentDir release];
	[self.view addSubview:_detailViewCtrl.view];
	[ctrl release];
	
	[self initAnimation:nil duration:0.15f];
	[_detailViewCtrl.view setAlpha:1];
	[UIView commitAnimations];
}

// 本の表示
- (void)showBook:(NSUInteger)selectPage {
	BookInfo *info = [_bookCollection getAt:_selectBookIndex];
	ReadViewCtrl *ctrl = [[ReadViewCtrl alloc] initWithNibName:@"ReadView" bundle:nil];
	_readViewCtrl = [ctrl retain];
	[_readViewCtrl setup:info.uuid selectPage:selectPage pageNum:info.length fakePage:info.fake direction:info.direction];
	[self.view insertSubview:_readViewCtrl.view belowSubview:_detailViewCtrl.view];
	
	[self initAnimation:DETAIL_TO_READ_ANIM_ID duration:0.5f];
//	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
	
	[_readViewCtrl.view setAlpha:0];
	[_detailViewCtrl.view setAlpha:1];
	[_detailViewCtrl viewWillDisappear:YES];
	[_readViewCtrl.view setAlpha:1];
	[_detailViewCtrl.view setAlpha:0];
	[_detailViewCtrl viewDidDisappear:YES];
	[UIView commitAnimations];
	
	[ctrl release];
}

- (void)releaseListView {
	if (_listViewCtrl != nil) {
		[_listViewCtrl.view removeFromSuperview];
		[_listViewCtrl release];
		_listViewCtrl = nil;
	}
}

- (void)releaseBuyView {
	if (_buyViewCtrl != nil) {
		[_buyViewCtrl.view removeFromSuperview];
		[_buyViewCtrl release];
		_buyViewCtrl = nil;
	}
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSInteger requireMode;
	if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		requireMode = MODE_A;
	}
	else {
		requireMode = MODE_B;
	}
	
	if (requireMode != _windowMode)
	{
		_windowMode = requireMode;
		[self changeOrientation:YES];
		
		if (_readViewCtrl != nil)
			[_readViewCtrl shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	}
    return YES;
}

- (void)releaseXML {
	if (_xmlCtrl) {
		[_xmlCtrl release];
		_xmlCtrl = nil;
	}
}

-(void)onAnimationEnd:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if ([animationID isEqualToString:LOGO_ANIM_ID]) {
		[_logoView.view removeFromSuperview];
		[_logoView release];
		
		[self updateXML];
	}
	
	else if ([animationID isEqualToString:CHANGE_ORIENTATION_ANIM_ID]) {
		if (_windowMode == MODE_A) {
			for (UIImageView *v in _bBgList) {
				v.image = nil;
				[v removeFromSuperview];
			}
			[_bBgList removeAllObjects];
		}
		else {
			for (UIImageView *v in _aBgList) {
				v.image = nil;
				[v removeFromSuperview];
			}
			[_aBgList removeAllObjects];
		}
		
		[self setBooks:YES];
	}

	else if ([animationID isEqualToString:SET_BOOK_ANIM_ID]) {
	}
	
	else if ([animationID isEqualToString:DETAIL_TO_SELECT_ANIM_ID] || [animationID isEqualToString:DETAIL_TO_READ_ANIM_ID]) {
		[_detailViewCtrl.view removeFromSuperview];
		[_detailViewCtrl release];
		_detailViewCtrl = nil;
	}
	
	else if ([animationID isEqualToString:READ_TO_SELECT_ANIM_ID]) {
		[_readViewCtrl.view removeFromSuperview];
		[_readViewCtrl release];
		_readViewCtrl = nil;
	}
}

// Logo終了タイマー
- (void)onLogoTimer:(NSTimer*)timer {
	[_logoView requestEnd];
}

// Parseが完了したら
- (void)onParseEndSelect:(NSNotification *)notification {
	BookCollection *collection = (BookCollection *)[notification object];
	BookInfo *info;
	NSString *bookDir;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSInteger length = [collection count];
	for (NSInteger i = 0; i < length; i++) {
		info = [collection getAt:i];
//		NSLog(@"uuid: %@ download: %@ url: %@ md5: %@ category: %@ title: %@ author: %@ length: %d direction: %d review: %@",
//			  info.uuid,
//			  info.download,
//			  info.url,
//			  info.md5,
//			  info.category,
//			  info.title,
//			  info.author,
//			  info.length,
//			  info.direction,
//			  info.review
//			  );

		bookDir = [[NSString alloc] initWithFormat:@"%@/%@/%@", [Util getLocalDocument], BOOK_DIRECTORY, info.uuid];
//		NSLog(@"bookDir: %@", bookDir);
		if ([fm fileExistsAtPath:bookDir] && !info.oldVersion) {
			// Update length
			NSArray * files = [[NSFileManager defaultManager] directoryContentsAtPath:bookDir];
			[info setLength:[files count]];
		}
		else {
			// ここはDLしたいinfoを追加
			[_tmpDlDic setValue:info forKey:info.uuid];
		}
		[bookDir release];
	}
	
	_bookCollection = [collection retain];
	_activitiyView.hidden = NO;
	
	// List has no books.
	if (![self startToDownloadBookFromQueue]) {
		[self updateXMLFinish];
	}
}

// 本のDLが完了した時のEvent
- (void)onDLBookSuccessSelect:(NSNotification *)notification {
	
	FileDownloader *fd = (FileDownloader *)[notification object];
	NSString *zipPath = [fd path];
	NSString *outDir = [fd pathWithoutExtension];
	NSString *tmpDir = [[NSString alloc] initWithFormat:@"%@_tmp", [fd pathWithoutExtension]];
	
	ZipArchive* za = [[ZipArchive alloc] init];
	if([za UnzipOpenFile:zipPath]) {
		BOOL ret = [za UnzipFileTo:tmpDir overWrite:YES];
		if(NO == ret) {
			NSLog(@"unzip error");
		}
		[za UnzipCloseFile];
	}
	[za release];
	
	NSArray *files;
	NSFileManager *fm = [NSFileManager defaultManager];
	files = [[NSFileManager defaultManager] directoryContentsAtPath:tmpDir];
	if ([files count] > 0) {
		NSString *srcDir = [[NSString alloc] initWithFormat:@"%@/%@", tmpDir, [files objectAtIndex:0]];
//		NSLog(@"srcDir: %@ outDir: %@", srcDir, outDir);
		NSDictionary *attribs = [fm attributesOfItemAtPath:srcDir error:nil];
		if ([attribs objectForKey:NSFileType] == NSFileTypeDirectory) {
			[fm moveItemAtPath:srcDir toPath:outDir error:nil];
			[fm removeItemAtPath:tmpDir error:nil];
		}

		// Rename tmp directory if doesn't exist inner directory.
		else {
			[fm moveItemAtPath:tmpDir toPath:outDir error:nil];
		}
		[srcDir release];
	}
	
	// Remove the zip file.
	[fm removeItemAtPath:zipPath error:nil];
	zipPath = nil;
	
	files = [[NSFileManager defaultManager] directoryContentsAtPath:outDir];
	NSUInteger count = 1;
	NSString *srcName;
	NSString *outName;
	for (NSString *file in files) {
		srcName = [[NSString alloc] initWithFormat:@"%@/%@", outDir, file];
		outName = [Util makeBookPathFormat:outDir pageNo:count extension:@"jpg"];
//		NSLog(@"srcName: %@ outName: %@", srcName, outName);
		[fm moveItemAtPath:srcName toPath:outName error:nil];
		[srcName release];
		[outName release];
		
		count++;
	}
	outDir = nil;
	
	// Set length.
	BookInfo *info = [_bookCollection getByKey:[fd uuid]];
	if (info) {
		[info setLength:(count - 1)];
	}
	
	[tmpDir release];
	[_tmpDlDic removeObjectForKey:[fd uuid]];
	
	// List has no books.
	if (![self startToDownloadBookFromQueue]) {
		if (_updating)
			[self updateXMLFinish];
	}
}

// 本のDLが失敗した時のEvent
- (void)onDLBookErrorSelect:(NSNotification *)notification {
	FileDownloader *fd = (FileDownloader *)[notification object];
	[_tmpDlDic removeObjectForKey:[fd uuid]];
	
	// List has no books.
	if (![self startToDownloadBookFromQueue]) {
		if (_updating)
			[self updateXMLFinish];
	}
}

// Login開始
- (void)onAuthenticationSelect:(NSNotification *)notification {
	LoginViewCtrl *ctrl = [[LoginViewCtrl alloc] initWithNibName:@"LoginView" bundle:nil];
	[self presentModalViewController:ctrl animated:YES];
	[ctrl release];
}

// Login終了
- (void)onLoginFinishSelect:(NSNotification *)notification {
	[self dismissModalViewControllerAnimated:YES];
}

// しおりの保存
- (void)onBookmarkSaveSelect:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	[_bookmarkDic setObject:[userInfo objectForKey:BOOKMARK_PAGE] forKey:[userInfo objectForKey:BOOKMARK_UUID]];
	[_bookmarkDic writeToFile:_bookmarkPath atomically:NO];
}

// 本が選択されて詳細画面が表示
- (void)onBookClick:(UIButton*)sender {
	
	_selectBookIndex = [sender tag];
	[self showDetail:_selectBookIndex];
}

// Logoアニメーション終了
- (void)onLogoEndSelect:(NSNotification *)notification {
	[self initAnimation:LOGO_ANIM_ID duration:0.25f];
	[_logoView.view setAlpha:0.0f];
	[UIView commitAnimations];	
}

// 詳細画面を消すアニメーション
- (void)onDetailDisappearSelect:(NSNotification *)notification {

	[self initAnimation:DETAIL_TO_SELECT_ANIM_ID duration:0.5f];
	[_detailViewCtrl.view setAlpha:0];
	CGRect frame = _detailViewCtrl.view.frame;
	frame.size.width = 0;
	frame.size.height = 0;
	if (_windowMode == MODE_A) {
		frame.origin.x = WINDOW_AW / 2;
		frame.origin.y = WINDOW_AH / 2;
	} else {
		frame.origin.x = WINDOW_BW / 2;
		frame.origin.y = WINDOW_BH / 2;
	}

	_detailViewCtrl.view.frame = frame;
	[UIView commitAnimations];
}

// 本画面から選択画面
- (void)onReadToSelect:(NSNotification *)notification {
	
	[self reloadBooks];

	[self initAnimation:READ_TO_SELECT_ANIM_ID duration:0.5f];
//	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
	[_readViewCtrl.view setAlpha:1];
	[_readViewCtrl viewWillDisappear:YES];
	[_readViewCtrl.view setAlpha:0];
	[_readViewCtrl viewDidDisappear:YES];
	[UIView commitAnimations];
}

// 詳細画面から読む画面
- (void)onDetailToReadSelect:(NSNotification *)notification {
	
	[self setMenuBarItems:NO list:YES trash:YES buy:YES];
	[self releaseListView];
	[self releaseBooks:YES];
	
	
	BookInfo *info = [_bookCollection getAt:_selectBookIndex];
	// ここでブックマークチェック
	NSString* _savedPage = [_bookmarkDic objectForKey:info.uuid];
	if(_savedPage) {
		_bookmarkPage = [_savedPage intValue];
		NSLog(@"saved page: %d", _bookmarkPage);
		[self showAlert:nil message:BOOKMARK_MESSAGE btn1:@"NO" btn2:@"YES" tag:BOOKMARK_ALERT_TAG];
	}
	
	else {
		[self showBook:1];
	}
}

// 一覧画面から詳細画面
- (void)onListToDetailSelect:(NSNotification *)notification {
	NSNumber *number = (NSNumber *)[notification object];
	NSInteger bookIndex = [number intValue];
	[self showDetail:bookIndex];
}

// メニュのブックボタンが押された場合
- (IBAction)onMenuBookClick:(id)sender {
	
	// buy viewからきた場合はリロードしておく？
	if (_buyViewCtrl) {
		
	}
	[self releaseBuyView];
	[self releaseListView];
	[self reloadBooks];
	[self setMenuBarItems:NO list:YES trash:YES buy:YES];
}

// 一覧ボタンが選択された時
- (IBAction)onMenuListClick:(id)sender {
	[self releaseBooks:YES];
	
	ListViewCtrl *ctrl;
	if (_windowMode == MODE_A)
		ctrl = [[ListViewCtrl alloc] initWithNibName:@"ListViewA" bundle:nil];
	else
		ctrl = [[ListViewCtrl alloc] initWithNibName:@"ListViewB" bundle:nil];
	_listViewCtrl = [ctrl retain];
	[_listViewCtrl setBookCollection:_bookCollection];
	[self.view insertSubview:ctrl.view atIndex:0];
	[ctrl release];
	[self setMenuBarItems:YES list:NO trash:NO buy:NO];
}

// 購入ボタンが選択されたとき
- (IBAction)onMenuBuyClick:(id)sender {
	if (USE_WEBKIT) {
		[self releaseBooks:YES];
		
		BuyViewCtrl *ctrl;
		if (_windowMode == MODE_A)
			ctrl = [[BuyViewCtrl alloc] initWithNibName:@"BuyViewA" bundle:nil];
		else
			ctrl = [[BuyViewCtrl alloc] initWithNibName:@"BuyViewB" bundle:nil];
		_buyViewCtrl = [ctrl retain];
		[self.view insertSubview:ctrl.view atIndex:0];
		[ctrl release];
		[self setMenuBarItems:YES list:NO trash:NO buy:NO];
	}
	
	else {
		NSURL *url = [[NSURL alloc] initWithString:TOP_URL];
		UIApplication *app = [UIApplication sharedApplication];
		[app openURL:url];
		[url release];
	}
}

// 削除ボタンが選択されたとき
- (IBAction)onMenuTrashClick:(id)sender {
	[self showAlert:WARNING_TITLE message:TRASH_WARNING_MESSAGE btn1:@"Cancel" btn2:@"OK" tag:TRASH_ALERT_TAG];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

	// Trash alert
	if ([alertView tag] == TRASH_ALERT_TAG) {
		
		// Trash
		if (buttonIndex == 1) {
			[self trashAllData];
		}
	}
	
	else if ([alertView tag] == RELOAD_DATA_ALERT_TAG) {
		if (buttonIndex == 1) {
			[self updateXML];
		}
	}
	
	else if ([alertView tag] == BOOKMARK_ALERT_TAG) {
		[self showBook:((buttonIndex == 1) ? _bookmarkPage : 1)];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
}

- (void)dealloc {
	[self releaseXML];
	[self releaseListView];
	[self releaseBuyView];
	[_bookmarkPath release];
	[_bookmarkDic release];
	[_tmpDlDic release];
	[_aBgList release];
	[_bBgList release];
	[_buttons release];
	[_bookCollection release];
	[self.bookBarButton release];
	[self.listBarButton release];
	[self.trashBarButton release];
	[self.buyBarButton release];
	[self.scrollView release];
    [super dealloc];
}

@end
