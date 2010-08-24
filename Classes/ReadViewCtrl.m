    //
//  ReadViewCtrl.m
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/27.
//  Copyright 2010 3di. All rights reserved.
//

#import "ReadViewCtrl.h"
#import "WindowModeType.h"
#import "ReadViewBaseCtrl.h"
#import "ReadViewACtrl.h"
#import "ReadViewBCtrl.h"
#import "DirectionType.h"
#import "Define.h"

#define CHANGE_ORIENTATION_ANIM_ID @"change_orientation_anim"

@implementation ReadViewCtrl
@synthesize slider = _slider;
@synthesize startLabel = startLabel_;
@synthesize endLabel = endLabel_;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	_readViewACtrl = nil;
	_readViewBCtrl = nil;
	_windowMode = MODE_NONE;
	[_slider addTarget:self action:@selector(onUpdateSlider:) forControlEvents:UIControlEventValueChanged];
	_slider.minimumValue = 1;
	_slider.maximumValue = _pageNum;
	_slider.value = _pageNum;
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(onTouchImage:) name:@"imageTouchEvent" object:nil];
	[notificationCenter addObserver:self selector:@selector(onBookmarkSaveSelect:) name:BOOKMARK_SAVE_EVENT object:nil];
	[notificationCenter addObserver:self selector:@selector(onPageChangeSelect:) name:PAGE_CHANGE_EVENT object:nil];
}

- (void)setup:(NSString *)uuid selectPage:(NSUInteger)selectPage pageNum:(NSInteger)pageNum fakePage:(NSInteger)fakePage direction:(NSInteger)direction {
	_direction = direction;
	_uuid = [uuid retain];
	_pageNum = pageNum;
	_fakePage = fakePage;
	_selectPage = selectPage;
}

- (void)initAnimation:(NSString *)animationID duration:(NSTimeInterval)duration {
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:animationID context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector:@selector(onAnimationEnd:finished:context:)];	
}

- (void)changeOrientation {

	ReadViewBaseCtrl *ctrl;
	NSInteger maxPage;
	if (_windowMode == MODE_A) {
		ctrl = [[ReadViewACtrl alloc] initWithNibName:@"ReadViewA" bundle:0];
		_readViewACtrl = [(ReadViewACtrl*)ctrl retain];
		maxPage = _pageNum - _fakePage;
	}
	else {
		ctrl = [[ReadViewBCtrl alloc] initWithNibName:@"ReadViewB" bundle:0];
		_readViewBCtrl = [(ReadViewBCtrl*)ctrl retain];
		maxPage = _pageNum;
	}
	
	if (_readViewACtrl && _readViewACtrl.currentPage > 0) {
		_selectPage = _readViewACtrl.currentPage;
	}
	else if (_readViewBCtrl && _readViewBCtrl.currentPage > 0) {
		_selectPage = _readViewBCtrl.currentPage;
	}
	
	[self.view insertSubview:ctrl.view atIndex:0];
	[ctrl.view setAlpha:0];
	[ctrl setup:_uuid selectPage:_selectPage pageNum:maxPage direction:_direction];
	
	[self initAnimation:CHANGE_ORIENTATION_ANIM_ID duration:0.25f];
	[ctrl.view setAlpha:1];
	[UIView commitAnimations];
	[ctrl release];
}

- (void)cleanupCurrentView:(NSInteger)requireMode {
	if (requireMode == MODE_A) {
		if (_readViewACtrl)
		{
			[_readViewACtrl.view removeFromSuperview];
			[_readViewACtrl release];
			_readViewACtrl = nil;
		}
	}
	else {
		if (_readViewBCtrl)
		{
			[_readViewBCtrl.view removeFromSuperview];
			[_readViewBCtrl release];
			_readViewBCtrl = nil;
		}
	}
}

- (void)pageNext {
	
	CGRect frame = self.view.frame;
	if (_windowMode == MODE_A) {
		if (![_readViewACtrl isNext])
			return;
		
		[_readViewACtrl next];
		
		frame.size.width = WINDOW_AW;
		frame.size.height = WINDOW_AH;
	} else {
		if (![_readViewBCtrl isNext])
			return;
		
		[_readViewBCtrl next];
		
		frame.size.width = WINDOW_BW;
		frame.size.height = WINDOW_BH;
	}
	
	self.view.frame = frame;
	
	[self initAnimation:nil duration:0.5f];
	//	[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
	[UIView commitAnimations];
}

- (void)pagePrev {
	
	if (_windowMode == MODE_A) {
		if (![_readViewACtrl isPrev])
			return;
		
		[_readViewACtrl prev];
	} else {
		if (![_readViewBCtrl isPrev])
			return;
		
		[_readViewBCtrl prev];
	}
	
	[self initAnimation:nil duration:0.5f];
	//	[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:YES];	
	[UIView commitAnimations];
}

- (void)onUpdateSlider:(UISlider *)aSlider {
	int number = floor(_slider.value);
	
//	if (_direction == DIRECTION_LEFT)
//		number = _pageNum - number + 1;
	
	if (_windowMode == MODE_A) {
		[_readViewACtrl requestPage:number];
	} else {
		[_readViewBCtrl requestPage:number];
	}
	
}

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
		[self changeOrientation];
	}
    return YES;
}

-(void)onAnimationEnd:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	
	if ([animationID isEqualToString:CHANGE_ORIENTATION_ANIM_ID]) {
		CGRect frame;
		if (_windowMode == MODE_A) {
			frame = _slider.frame;
			frame.origin.y = 30;
			_slider.frame = frame;
			
			[self cleanupCurrentView:MODE_B];
		} else {
			frame = _slider.frame;
			frame.origin.y = 30;
			_slider.frame = frame;
			
			[self cleanupCurrentView:MODE_A];
		}
		
		endLabel_.text = (_direction == DIRECTION_LEFT) ? @"始め" : @"終わり";
		startLabel_.text = (_direction == DIRECTION_LEFT) ? @"終わり" : @"始め";
		if (_direction == DIRECTION_LEFT) {
			CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * 180 / 180.0f);
			_slider.transform = trans;
		}
	}
}

- (IBAction)onBackClick:(id)sender {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:READ_TO_SELECT_EVENT object:nil userInfo:nil];
}

- (void)onTouchImage:(NSNotification *)notification {
	//	NSLog(@"touchesEnded tapCount: %d x: %f y: %f", tapCount, point.x, point.y);
	NSArray *dic = [notification object];
	NSNumber *index = [dic objectAtIndex:0];
	NSNumber *px = [dic objectAtIndex:1];
//	NSNumber *py = [dic objectAtIndex:2];
//	NSLog(@"onTouchImage index: %d px: %f py: %f", [index intValue], [px floatValue], [py floatValue]);
	
	if (_windowMode == MODE_A) {
		if ([px floatValue] < (self.view.frame.size.width / 2)) {
			if (_direction == DIRECTION_LEFT) {
				[self pageNext];
			} else {
				[self pagePrev];
			}
		} else {
			if (_direction == DIRECTION_LEFT) {
				[self pagePrev];
			} else {
				[self pageNext];
			}
		}
		
	} else {
		if ([index intValue] % 2 == 1) {
			[self pagePrev];
		} else {
			[self pageNext];
		}
	}	
}

- (void)onPageChangeSelect:(NSNotification *)notification {
	NSNumber *pageNumber = (NSNumber *)[notification object];
	
	float rate = [pageNumber floatValue] / _pageNum;
	_slider.value = _slider.maximumValue * rate;
	
	NSLog(@"value: %f rate: %f %d", _slider.value, rate, _pageNum);
}

- (void)onBookmarkSaveSelect:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	NSNumber *currentPage = [userInfo objectForKey:BOOKMARK_PAGE];
	_selectPage = [currentPage intValue];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	if (_windowMode == MODE_A) {
		[self cleanupCurrentView:MODE_A];
	} else {
		[self cleanupCurrentView:MODE_B];
	}

	[self.slider release];
	[self.startLabel release];
	[self.endLabel release];
	[_uuid release];
    [super dealloc];
}

@end
