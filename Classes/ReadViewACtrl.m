//
//  ReadViewACtrl.m
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/27.
//  Copyright 2010 3di. All rights reserved.
//

#import "ReadViewACtrl.h"
#import "WindowModeType.h"
#import "Util.h"
#import "Define.h"
#import "DirectionType.h"
#import "UIImageViewWithTouch.h"

#define CENTER_SHADOW_WIDTH 64

@implementation ReadViewACtrl
@synthesize scrollView = _scrollView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	_scrollView = [[MyScrollView alloc] init];
	[_scrollView setMinimumZoomScale:MIN_ZOOM_SCALE];
	[_scrollView setMaximumZoomScale:MAX_ZOOM_SCALE];
	if ( MAX_ZOOM_SCALE == MIN_ZOOM_SCALE ) {
		_scrollView.scrollEnabled = NO;
	}
	if ( _windowMode == MODE_A ) {
		self.view.frame = CGRectMake(0, 0, WINDOW_AW, WINDOW_AH);
		_scrollView.frame = CGRectMake(0, 0, WINDOW_AW, WINDOW_AH);
		_scrollView.contentSize = CGSizeMake(WINDOW_AW, WINDOW_AH);
	} else {
		self.view.frame = CGRectMake(0, 0, WINDOW_BW, WINDOW_BH);
		_scrollView.frame = CGRectMake(0, 0, WINDOW_BW, WINDOW_BH);
		_scrollView.contentSize = CGSizeMake(WINDOW_BW, WINDOW_BH);
	}
	_scrollView.pagingEnabled = NO;
	_scrollView.delegate = self;
	_scrollView.delaysContentTouches = NO;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.showsVerticalScrollIndicator = NO;
	
	_leftView = [[UIView alloc] init];
	[_leftView setUserInteractionEnabled:NO];
	[_scrollView addSubview:_leftView];
	
	_rightView = [[UIView alloc] init];
	[_rightView setUserInteractionEnabled:NO];
	[_scrollView addSubview:_rightView];
	
	[self.view addSubview:_scrollView];
	
	_pageCurlView = [[UIView alloc] initWithFrame:self.view.frame];
	//[_pageCurlView setBackgroundColor:[UIColor blueColor]];
	[_pageCurlView setUserInteractionEnabled:NO];
	//_pageCurlView.delegate = self;
	
	[self initLayers:_pageCurlView];
	
	[self.view addSubview:_pageCurlView];
	
	_mode = page_mode_none;
	
	image_margin_x = 0;
	image_margin_y = 0;
}

- (void) initLayers:(UIView *)targetView {
	targetView.clipsToBounds = YES;
	
	curlingPageR = [[CALayer alloc] init];
	curlingPageR.masksToBounds = YES;
	//curlingPageR.backgroundColor = [[UIColor redColor] CGColor];
	
	curlingPageRImage = [[CALayer alloc] init];
	curlingPageRImage.backgroundColor = [[UIColor whiteColor] CGColor];
	//curlingPageRImage.contentsGravity = kCAGravityLeft;
	curlingPageRImage.masksToBounds = YES;
	
	curlingPageRImageOverlay = [[CALayer alloc] init];
	curlingPageRImageOverlay.masksToBounds = YES;
	curlingPageRImageOverlay.backgroundColor = [[UIColor whiteColor] CGColor];
	
	[curlingPageRImage addSublayer:curlingPageRImageOverlay];
	
	[curlingPageR addSublayer:curlingPageRImage];
	
	curlingPageL = [[CALayer alloc] init];
	curlingPageL.masksToBounds = YES;
	//curlingPageL.backgroundColor = [[UIColor blueColor] CGColor];
	
	curlingPageLImage = [[CALayer alloc] init];
	curlingPageLImage.masksToBounds = YES;
	curlingPageLImage.backgroundColor = [[UIColor whiteColor] CGColor];
	
	curlingPageLImageOverlay = [[CALayer alloc] init];
	curlingPageLImageOverlay.masksToBounds = YES;
	curlingPageLImageOverlay.backgroundColor = [[UIColor whiteColor] CGColor];
	
	[curlingPageLImage addSublayer:curlingPageLImageOverlay];
	
	[curlingPageL addSublayer:curlingPageLImage];
	
	curlingPageRShadow = [[CAGradientLayer alloc] init];
	[curlingPageR addSublayer:curlingPageRShadow];
	
	curlingPageLShadow = [[CAGradientLayer alloc] init];
	[curlingPageL addSublayer:curlingPageLShadow];
	
	centerPageShadow = [[CAGradientLayer alloc] init];
	[targetView.layer addSublayer:centerPageShadow];
	
	rightPageShadow = [[CAGradientLayer alloc] init];
	[targetView.layer addSublayer:rightPageShadow];
	
	leftPageShadow = [[CAGradientLayer alloc] init];
	[targetView.layer addSublayer:leftPageShadow];
	
	[targetView.layer addSublayer:curlingPageR];
	
	[targetView.layer addSublayer:curlingPageL];
}

- (void)setup:(NSString *)uuid selectPage:(NSUInteger)selectPage pageNum:(NSInteger)pageNum direction:(NSInteger)direction windowMode:(NSInteger)windowMode {
	[super setup:uuid selectPage:selectPage pageNum:pageNum direction:direction windowMode:windowMode];
	
	//	if (direction == DIRECTION_LEFT) {
	//		_scrollView.contentOffset = CGPointMake(WINDOW_AW * (pageNum - 1), 0);
	//	} else {
	//		_scrollView.contentOffset = CGPointMake(WINDOW_AW * 0, 0);
	//	}
	
	NSInteger scrollPointX;
	if (_direction == DIRECTION_LEFT) {
		scrollPointX = _maxPage - selectPage;
	} else {
		scrollPointX = selectPage - 1;
	}
	
	//_scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width * scrollPointX, 0);
	[self setPage:selectPage windowMode:windowMode];
	
	if (windowMode == MODE_A) {
		[centerPageShadow removeFromSuperlayer];
	}
	else {
		centerPageShadow.opacity = 1;
		centerPageShadow.colors = [NSArray arrayWithObjects:
								   (id)[[UIColor clearColor] CGColor],
								   (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor], 
								   (id)[[UIColor clearColor] CGColor],
								   nil];
		centerPageShadow.startPoint = CGPointMake(1, 0.5);
		centerPageShadow.endPoint = CGPointMake(0, 0.5);
		centerPageShadow.frame = CGRectMake((WINDOW_BW / 2) - (CENTER_SHADOW_WIDTH / 2), 0, CENTER_SHADOW_WIDTH, WINDOW_BH);
		[_pageCurlView.layer addSublayer:centerPageShadow];
	}

}

- (BOOL)isNext {
    if (_currentPage < _maxPage)
		return YES;
	
    return NO;
}

- (void)next {
	[super next];
	
	//NSLog(@"next");
	
	NSInteger targetPage;
	if ( _windowMode == MODE_A ) { //TODO
		targetPage = _currentPage + 1;
	} else {
		targetPage = _currentPage + 2;
	}
	
	if (targetPage > _maxPage)
		return;
	
	NSInteger scrollPointX;
	if (_direction == DIRECTION_LEFT) {
		scrollPointX = _maxPage - targetPage;
	} else {
		scrollPointX = targetPage - 1;
	}
	
	[self setPage:targetPage windowMode:_windowMode];
	
	[self resetContentsSize];
	
	//_scrollView.contentOffset = CGPointMake(0, 0);
	[self releaseFarBooks:targetPage];
}

- (BOOL)isPrev {
    if (_currentPage > 1)
		return YES;
	
    return NO;
}

- (void)prev {
	[super prev];
	
	NSInteger targetPage;
	if ( _windowMode == MODE_A ) { //TODO
		targetPage = _currentPage - 1;
	} else {
		targetPage = _currentPage - 2;
	}
	if (targetPage < 1)
		return;
	
	NSInteger scrollPointX;
	if (_direction == DIRECTION_LEFT) {
		scrollPointX = _maxPage - targetPage;
	} else {
		scrollPointX = targetPage - 1;
	}
	
	[self setPage:targetPage windowMode:_windowMode];
	
	[self resetContentsSize];
	
	//_scrollView.contentOffset = CGPointMake(0, 0);
	[self releaseFarBooks:targetPage];
}

- (void)resetContentsSize {
	_scrollView.contentOffset = CGPointMake(0, 0);
	_scrollView.zoomScale = 1.0f;
	if ( _windowMode == MODE_A ) {
		_scrollView.frame = CGRectMake(0, 0, WINDOW_AW, WINDOW_AH);
		_scrollView.contentSize = CGSizeMake(WINDOW_AW, WINDOW_AH);
	} else {
		_scrollView.frame = CGRectMake(0, 0, WINDOW_BW, WINDOW_BH);
		_scrollView.contentSize = CGSizeMake(WINDOW_BW, WINDOW_BH);
	}
}

- (void)requestPage:(NSInteger)targetPage {
	// NSLog(@"%d", targetPage);
	if ( _windowMode == MODE_B ) {
		targetPage = 2 * floor(targetPage / 2) + 1;
	}
	[super requestPage:targetPage];
	
	//if (_direction == DIRECTION_LEFT)
	// targetPage = _maxPage - targetPage;
	
	[self setPage:targetPage windowMode:_windowMode];
	
	[self releaseFarBooks:targetPage];
	
	_scrollView.contentOffset = CGPointMake(0, 0);
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	/*
	 CGFloat pageWidth = _scrollView.frame.size.width;  
	 NSInteger targetPage = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	 
	 if (_direction == DIRECTION_LEFT)
	 targetPage = _maxPage - targetPage;
	 else {
	 targetPage = targetPage + 1;
	 }
	 
	 [self setPage:targetPage windowMode:_windowMode];
	 */
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)sender {
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)sender {
}

/*
 - (void)scrollViewDidEndDragging:(UIScrollView *)sender willDecelerate:(BOOL)decelerate{
 CGFloat pageWidth = _scrollView.frame.size.width;  
 NSInteger targetPage = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
 NSLog(@"end dragging");
 
 if (_direction == DIRECTION_LEFT)
 targetPage = _maxPage - targetPage;
 else {
 targetPage = targetPage + 1;
 }
 
 if(_currentPage != targetPage) {
 [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width * targetPage, 0) animated:YES];
 }
 
 [self setPage:targetPage];
 }
 */

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	if (_scrollOffsetX > scrollView.contentOffset.x) {
		if (_direction == DIRECTION_LEFT) {
			//			NSLog(@"scrollViewDidEndScrollingAnimation Next");
		} else {
			//			NSLog(@"scrollViewDidEndScrollingAnimation Prev");
		}
	} else {
		if (_direction == DIRECTION_LEFT) {
			//			NSLog(@"scrollViewDidEndScrollingAnimation Prev");
		} else {
			//			NSLog(@"scrollViewDidEndScrollingAnimation Next");
		}
	}
	
	[self setPage:_currentPage windowMode:_windowMode];
	
	[self releaseFarBooks:_currentPage];
}

-(void)scrollViewDidEndZooming:(UIScrollView *)sv withView:(UIView*)v0 atScale:(float)scale {
	if (_windowMode == MODE_A) {
		_scrollView.frame = CGRectMake(0, 0, WINDOW_AW, WINDOW_AH);
		_scrollView.contentSize = CGSizeMake(WINDOW_AW * scale, WINDOW_AH * scale);
	} else {
		_scrollView.frame = CGRectMake(0, 0, WINDOW_BW, WINDOW_BH);
		_scrollView.contentSize = CGSizeMake(WINDOW_BW * scale, WINDOW_BH * scale);
	}
}

-(void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate {
	float w;
	if ( _windowMode == MODE_A ) {
		w = WINDOW_AW;
	} else {
		w = WINDOW_BW;
	}
	//NSLog(@"%f, %f", sv.contentOffset.x + w , sv.contentSize.width + PAGE_CHANGE_TRIGGER_MARGIN);
	if (sv.contentOffset.x < -1.0f * PAGE_CHANGE_TRIGGER_MARGIN) {
		if (_direction == DIRECTION_LEFT) {
			[self notifyGoToNextPage];
		} else {
			[self notifyGoToPrevPage];
		}
	} else if (sv.contentOffset.x + w > sv.contentSize.width + PAGE_CHANGE_TRIGGER_MARGIN) {
		if (_direction == DIRECTION_LEFT) {
			[self notifyGoToPrevPage];
		} else {
			[self notifyGoToNextPage];
		}
	}
	//NSLog(@"release %f, %f", sv.contentOffset.x, sv.contentOffset.y);
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return scrollView;
}

- (void)releaseFarBooks:(NSInteger)targetPage {
	for (NSInteger i = 1; i < _maxPage; i++) {
		if ((_windowMode == MODE_A && (i < (targetPage - 1) || (targetPage + 1) < i)) ||
			(_windowMode == MODE_B && (i < (targetPage - 2) || (targetPage + 3) < i))) {
			NSNumber *number = [NSNumber numberWithInteger:i];
			if ([_pageList objectForKey:number]) {
				[super releaseBook:number removeFromList:YES];
			}
			if ([_imageList objectForKey:number]) {
				[super releaseImage:number removeFromList:YES];
			}
		}
	}
}

- (void)releaseAllBooks:(NSInteger)targetPage {
	for (NSInteger i = 1; i < _maxPage; i++) {
		NSNumber *number = [NSNumber numberWithInteger:i];
		if ([_pageList objectForKey:number]) {
			[super releaseBook:number removeFromList:YES];
		}
		if ([_imageList objectForKey:number]) {
			[super releaseImage:number removeFromList:YES];
		}
	}
}

- (void)setPage:(NSInteger)selectPage windowMode:(NSInteger)windowMode {
	if (windowMode != _windowMode) {
		_windowMode = windowMode;
		
		if (_windowMode == MODE_A) {
			self.view.frame = CGRectMake(0, 0, WINDOW_AW, WINDOW_AH);
			_scrollView.frame = CGRectMake(0, 0, WINDOW_AW, WINDOW_AH);
			_scrollView.contentSize = CGSizeMake(WINDOW_AW, WINDOW_AH);
			[_rightView setFrame:CGRectMake(0, 0, WINDOW_AW, WINDOW_AH)];
			[_leftView setFrame:CGRectMake(WINDOW_AW, 0, WINDOW_AW, WINDOW_AH)]; //TODO
			
			[_pageCurlView setFrame:CGRectMake(0, 0, WINDOW_AW, WINDOW_AH)];
		} else {
			self.view.frame = CGRectMake(0, 0, WINDOW_BW, WINDOW_BH);
			_scrollView.frame = CGRectMake(0, 0, WINDOW_BW, WINDOW_BH);
			_scrollView.contentSize = CGSizeMake(WINDOW_BW, WINDOW_BH);
			[_rightView setFrame:CGRectMake(WINDOW_BW / 2, 0, WINDOW_BW / 2, WINDOW_BH)];
			[_leftView setFrame:CGRectMake(0, 0, WINDOW_BW / 2, WINDOW_BH)];
			
			[_pageCurlView setFrame:CGRectMake(0, 0, WINDOW_BW, WINDOW_BH)];
		}
	} else {
		if (selectPage == _currentPage)
			return;
	}
	
	[super setPage:selectPage windowMode:_windowMode];
	
	if (_windowMode == MODE_A) {
		[self setPageForSingleFace:selectPage];
	} else {
		[self setPageForDoubleFace:selectPage];
	}
}

- (void)setPageForSingleFace:(NSInteger)selectPage {
	NSInteger selectPageWithOffset;
	for (NSInteger i = 0; i < 3; i++) {
		selectPageWithOffset = selectPage + (i - 1);
		NSInteger pagePosition = selectPageWithOffset;
		if (_direction == DIRECTION_LEFT)
			pagePosition = _maxPage - pagePosition;
		else {
			pagePosition = pagePosition - 1;
		}
		
		NSNumber *number = [NSNumber numberWithInteger:selectPageWithOffset];
		if ([_pageList objectForKey:number]) {
			UIImageViewWithTouch *imageView = [_pageList objectForKey:number];
			//			NSLog(@"already exist page: %d", selectPageWithOffset);
			[imageView setFrame:CGRectMake(0, 0, WINDOW_AW, WINDOW_AH)];
			
			if (selectPageWithOffset == _currentPage) {
				[self removeAllSubviewsFrom:_rightView];
				[_rightView addSubview:imageView];
			}
		} else {
			NSString *documentDir = [[NSString alloc] initWithFormat:@"%@/%@/%@", [Util getLocalDocument], BOOK_DIRECTORY, _uuid];
			NSString *image_path = [Util makeBookPathFormat:documentDir pageNo:selectPageWithOffset extension:BOOK_EXTENSION];
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:image_path];
			if (image)
			{
				UIImageViewWithTouch *imageView = [[UIImageViewWithTouch alloc] initWithImage:image];
				[imageView setContentMode:UIViewContentModeScaleAspectFit];
				[imageView setUserInteractionEnabled:NO];
				[imageView setTag:selectPageWithOffset];
				[imageView setFrame:CGRectMake(0, 0, WINDOW_AW, WINDOW_AH)];
				if (selectPageWithOffset == _currentPage) {
					[self removeAllSubviewsFrom:_rightView];
					[_rightView addSubview:imageView];
				}
				[_pageList setObject:imageView forKey:number];
				[_imageList setObject:[self getImageRefFromUIImage:image] forKey:number];
				[imageView release];
				[image release];
				
				//				NSLog(@"add page: %d", selectPageWithOffset);
			}
			[image_path release];
			[documentDir release];
		}
	}
}

- (void)setPageForDoubleFace:(NSInteger)selectPage {
	
	NSInteger selectPageWithOffset;
	for (NSInteger i = 0; i < 6; i++) {
		selectPageWithOffset = selectPage + (i - 2);
		NSInteger pagePosition = selectPageWithOffset;
		if (_direction == DIRECTION_LEFT)
			pagePosition = _maxPage - pagePosition;
		else {
			pagePosition = pagePosition - 1;
		}
		
		NSNumber *number = [NSNumber numberWithInteger:selectPageWithOffset];
		if ([_pageList objectForKey:number]) {
			UIImageViewWithTouch *imageView = [_pageList objectForKey:number];
			[imageView setFrame:CGRectMake(0, 0, WINDOW_BW / 2, WINDOW_BH)];
			
			if ( _direction == DIRECTION_LEFT ) {
				if (selectPageWithOffset == _currentPage) {
					[self removeAllSubviewsFrom:_rightView];
					[_rightView addSubview:imageView];
				} else if (selectPageWithOffset == _currentPage + 1) {
					[self removeAllSubviewsFrom:_leftView];
					[_leftView addSubview:imageView];
				}
			} else {
				if (selectPageWithOffset == _currentPage + 1) {
					[self removeAllSubviewsFrom:_rightView];
					[_rightView addSubview:imageView];
				} else if (selectPageWithOffset == _currentPage) {
					[self removeAllSubviewsFrom:_leftView];
					[_leftView addSubview:imageView];
				}
			}
		} else {
			NSString *documentDir = [[NSString alloc] initWithFormat:@"%@/%@/%@", [Util getLocalDocument], BOOK_DIRECTORY, _uuid];
			NSString *image_path = [Util makeBookPathFormat:documentDir pageNo:selectPageWithOffset extension:BOOK_EXTENSION];
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:image_path];
			if (image)
			{
				UIImageViewWithTouch *imageView = [[UIImageViewWithTouch alloc] initWithImage:image];
				[imageView setContentMode:UIViewContentModeScaleAspectFit];
				[imageView setUserInteractionEnabled:NO];
				[imageView setTag:selectPageWithOffset];
				[imageView setFrame:CGRectMake(0, 0, WINDOW_BW / 2, WINDOW_BH)];
				if ( _direction == DIRECTION_LEFT ) {
					if (selectPageWithOffset == _currentPage) {
						[self removeAllSubviewsFrom:_rightView];
						[_rightView addSubview:imageView];
					} else if (selectPageWithOffset == _currentPage + 1) {
						[self removeAllSubviewsFrom:_leftView];
						[_leftView addSubview:imageView];
					}
				} else {
					if (selectPageWithOffset == _currentPage) {
						[self removeAllSubviewsFrom:_leftView];
						[_leftView addSubview:imageView];
					} else if (selectPageWithOffset == _currentPage + 1) {
						[self removeAllSubviewsFrom:_rightView];
						[_rightView addSubview:imageView];
					}
				}
				[_pageList setObject:imageView forKey:number];
				[_imageList setObject:[self getImageRefFromUIImage:image] forKey:number];
				//NSLog(@"load image %d", selectPageWithOffset);
				[imageView release];
				[image release];
				
				//				NSLog(@"add page: %d", selectPageWithOffset);
			}
			[image_path release];
			[documentDir release];
		}
	}
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
	[self.scrollView release];
	[super dealloc];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	touchStartPoint = [[touches anyObject] locationInView:self.view];
	
	if ( [touches count] == 1 && _scrollView.zoomScale == 1.0f) {
		if ( _mode == page_mode_none ) {
			_mode = page_mode_curl_start;
		}
		
		[_scrollView setScrollEnabled:NO];
		[_scrollView setCanCancelContentTouches:NO];
	}
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint point;
	point = [[touches anyObject] locationInView:self.view];
	float delta_x = point.x - touchStartPoint.x;
	float curlRatio = 0.0f;
	
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.01f]
					 forKey:kCATransactionAnimationDuration];
	
	if ( _mode == page_mode_curl_start ) {
		if ( delta_x >= 0) {
			if (_direction == DIRECTION_LEFT) {
				if([self isNext]) [self beginToCurlLeft];
			} else {
				if([self isPrev]) [self beginToCurlLeft];
			}
			_mode = page_mode_curl_left;
		} else {
			if (_direction == DIRECTION_LEFT) {
				if([self isPrev]) [self beginToCurlRight];
			} else {
				if([self isNext]) [self beginToCurlRight];
			}
			_mode = page_mode_curl_right;
		}
	} else if ( _mode == page_mode_curl_right ) {
		if ( delta_x >= 0) {
			[self beginToCurlLeft];
			_mode = page_mode_curl_left;
		} else {
			if (_windowMode == MODE_A) {
				curlRatio = ((-1.0f * delta_x) / WINDOW_AW);
			} else {
				curlRatio = ((-1.0f * delta_x) / WINDOW_BW);
			}
			if (_direction == DIRECTION_LEFT) {
				if([self isPrev]) [self curlPageToRight:curlRatio];
			} else {
				if([self isNext]) [self curlPageToRight:curlRatio];
			}
		}
	} else if ( _mode == page_mode_curl_left ) {
		if ( delta_x < 0) {
			[self beginToCurlRight];
			_mode = page_mode_curl_right;
		} else {
			if (_windowMode == MODE_A) {
				curlRatio = (delta_x / WINDOW_AW);
			} else {
				curlRatio = (delta_x / WINDOW_BW);
			}
			if (_direction == DIRECTION_LEFT) {
				if([self isNext]) [self curlPageToLeft:curlRatio];
			} else {
				if([self isPrev]) [self curlPageToLeft:curlRatio];
			}
		}
	}
	
	[CATransaction commit];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.view];
	
	float delta_x = point.x - touchStartPoint.x;
	
	BOOL page_change_flag = false;
	
	if ( _mode == page_mode_curl_start ) {
		if ( point.x < self.view.frame.size.width / 2 ) {
			if ( _direction == DIRECTION_LEFT ) {
				//[self notifyGoToNextPage];
			} else {
				//[self notifyGoToPrevPage];
			}
		} else {
			if ( _direction == DIRECTION_LEFT ) {
				//[self notifyGoToPrevPage];
			} else {
				//[self notifyGoToNextPage];
			}
		}
		_mode = page_mode_none;
	} else {
		if ( _mode == page_mode_curl_right ) {
			if ( _windowMode == MODE_A ) {
				if ( -1.0f * delta_x / WINDOW_AW > 0.5f) {
					if ( _direction == DIRECTION_LEFT && [self isPrev]) {
						page_change_flag = true;
						[self performSelector:@selector(notifyGoToPrevPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					} else if ( _direction == DIRECTION_RIGHT && [self isNext]) {
						page_change_flag = true;
						[self performSelector:@selector(notifyGoToNextPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					}
				}
			} else {
				if ( -1.0f * delta_x / WINDOW_BW > 0.5f) {
					if ( _direction == DIRECTION_LEFT && [self isPrev]) {
						page_change_flag = true;
						[self performSelector:@selector(notifyGoToPrevPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					} else if ( _direction == DIRECTION_RIGHT && [self isNext]) {
						page_change_flag = true;
						[self performSelector:@selector(notifyGoToNextPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					}
				}
			}
			
			[CATransaction begin];
			[CATransaction setValue:[NSNumber numberWithFloat:PAGING_WAIT_TIME]
							 forKey:kCATransactionAnimationDuration];
			if ( page_change_flag ) {
				[self curlPageToRight:1.0f];
			} else {
				[self curlPageToRight:0];
			}
			[CATransaction commit];
		} else if ( _mode == page_mode_curl_left ) {
			if ( _windowMode == MODE_A ) {
				if ( delta_x / WINDOW_AW > 0.5f) {
					page_change_flag = true;
					if ( _direction == DIRECTION_LEFT && [self isNext]) {
						[self performSelector:@selector(notifyGoToNextPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					} else if ( _direction == DIRECTION_RIGHT && [self isPrev]) {
						[self performSelector:@selector(notifyGoToPrevPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					}
				}
			} else {
				if ( delta_x / WINDOW_BW > 0.5f) {
					page_change_flag = true;
					if ( _direction == DIRECTION_LEFT && [self isNext]) {
						[self performSelector:@selector(notifyGoToNextPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					} else if ( _direction == DIRECTION_RIGHT && [self isPrev]) {
						[self performSelector:@selector(notifyGoToPrevPage)
								   withObject:nil 
								   afterDelay:PAGING_WAIT_TIME + 0.05f];
					}
				}
			}
			
			[CATransaction begin];
			[CATransaction setValue:[NSNumber numberWithFloat:PAGING_WAIT_TIME]
							 forKey:kCATransactionAnimationDuration];
			if ( page_change_flag ) {
				[self curlPageToLeft:1.0f];
			} else {
				[self curlPageToLeft:0];
			}
			[CATransaction commit];
		}
		[self performSelector:@selector(endToCurl)
				   withObject:nil 
				   afterDelay:PAGING_WAIT_TIME + 0.1f];
		
		[self performSelector:@selector(setModeToNone)
				   withObject:nil 
				   afterDelay:PAGING_WAIT_TIME + 0.15f];
	}
	
	if ( MAX_ZOOM_SCALE != MIN_ZOOM_SCALE ) [_scrollView setScrollEnabled:YES];
	[_scrollView setCanCancelContentTouches:YES];
}

- (void)touchesCanceled:(NSSet*)touches withEvent:(UIEvent*)event {
	_mode = page_mode_none;
	if ( MAX_ZOOM_SCALE != MIN_ZOOM_SCALE ) [_scrollView setScrollEnabled:YES];
	[_scrollView setCanCancelContentTouches:YES];
}

- (void) beginToCurlLeft {
	//NSLog(@"begin to left");
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
    [self initCurlPageToLeft];
	[CATransaction commit];
	
	if ( _windowMode == MODE_A) {
		if ( _direction == DIRECTION_LEFT ) {
			[self removeAllSubviewsFrom:_rightView];
			[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage+1]]];
		} else {
			[self removeAllSubviewsFrom:_rightView];
			[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]]];
		}
	} else {
		if ( _direction == DIRECTION_LEFT ) {
			[self removeAllSubviewsFrom:_leftView];
			[_leftView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage+3]]];
		} else {
			[self removeAllSubviewsFrom:_leftView];
			[_leftView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage-2]]];
		}
	}
}

- (void) beginToCurlRight {
	//NSLog(@"begin to right");
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
    [self initCurlPageToRight];
	[CATransaction commit];
	
	if ( _windowMode == MODE_A) {
		if ( _direction != DIRECTION_LEFT ) {
			[self removeAllSubviewsFrom:_rightView];
			[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage+1]]];
		} else {
			[self removeAllSubviewsFrom:_rightView];
			[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]]];
		}
	} else {
		if ( _direction == DIRECTION_LEFT ) {
			[self removeAllSubviewsFrom:_rightView];
			[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage-2]]];
		} else {
			[self removeAllSubviewsFrom:_rightView];
			[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage+3]]];
		}
	}
}

- (void) initCurlPageToLeft {
	//NSLog(@"init curl page l");
	curlingPageRShadow.opacity = 0.0f;
	curlingPageRShadow.colors = [NSArray arrayWithObjects:
								 (id)[[UIColor clearColor] CGColor],
								 (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor],
								 (id)[[UIColor clearColor] CGColor], nil];
	curlingPageRShadow.startPoint = CGPointMake(1,0.5);
	curlingPageRShadow.endPoint = CGPointMake(0,0.5);
	
	curlingPageLShadow.colors = [NSArray arrayWithObjects:
								 (id)[[UIColor clearColor] CGColor],
								 (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor],
								 (id)[[UIColor clearColor] CGColor], nil];
	curlingPageLShadow.startPoint = CGPointMake(1,0.5);
	curlingPageLShadow.endPoint = CGPointMake(0,0.5);
	
	leftPageShadow.opacity = 0.0f;
	leftPageShadow.colors = [NSArray arrayWithObjects:
							 (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor],
							 (id)[[UIColor clearColor] CGColor], nil];
	leftPageShadow.startPoint = CGPointMake(1,0.5);
	leftPageShadow.endPoint = CGPointMake(0,0.5);
	
	rightPageShadow.opacity = 0.0f;
	rightPageShadow.colors = [NSArray arrayWithObjects:
							  (id)[[UIColor clearColor] CGColor],
							  (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor], nil];
	rightPageShadow.startPoint = CGPointMake(1,0.5);
	rightPageShadow.endPoint = CGPointMake(0,0.5);
	
	if ( _windowMode == MODE_A ) {
		if ( _direction == DIRECTION_LEFT ) {
			curlingPageR.opacity = 1.0f;
			curlingPageRImage.opacity = 1.0f;
			curlingPageRImage.transform = CATransform3DMakeScale(1, 1, 1);
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage]];
			curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
			curlingPageRImageOverlay.opacity = 0.0f;
			
			curlingPageL.opacity = 1.0f;
			curlingPageLImage.opacity = 1.0f;
			curlingPageLImage.transform = CATransform3DMakeScale(-1, 1, 1);
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage]];
			curlingPageLImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
			curlingPageLImageOverlay.opacity = REVERSE_PAGE_OPACITY;
			
			[curlingPageL removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:curlingPageL];
			[leftPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:leftPageShadow];
			[rightPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:rightPageShadow];
		} else {
			curlingPageR.opacity = 1.0f;
			curlingPageRImage.opacity = 1.0f;
			curlingPageRImage.transform = CATransform3DMakeScale(-1, 1, 1);
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]];
			curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]] image]];
			curlingPageRImageOverlay.opacity = REVERSE_PAGE_OPACITY;
			
			curlingPageL.opacity = 1.0f;
			curlingPageLImage.opacity = 1.0f;
			curlingPageLImage.transform = CATransform3DMakeScale(1, 1, 1);
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]];
			curlingPageLImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]] image]];
			curlingPageLImageOverlay.opacity = 0.0f;
			
			[curlingPageR removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:curlingPageR];

			[rightPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:rightPageShadow];
			[leftPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:leftPageShadow];
		}
		
		[centerPageShadow removeFromSuperlayer];
	} else {
		curlingPageRImageOverlay.opacity = 0.0f;
		curlingPageLImageOverlay.opacity = 0.0f;
		
		curlingPageR.opacity = 1.0f;
		curlingPageRImage.opacity = 1.0f;
		curlingPageRImage.transform = CATransform3DMakeScale(1, 1, 1);
		
		if ( _direction == DIRECTION_LEFT ) {
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage+1]];
			curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage + 1]] image]];
		} else {
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage]];
			curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
		}
		curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
		
		curlingPageL.opacity = 1.0f;
		curlingPageLImage.opacity = 1.0f;
		curlingPageLImage.transform = CATransform3DMakeScale(1, 1, 1);
		if ( _direction == DIRECTION_LEFT ) {
			// NSLog(@"set page %d", _currentPage+2);
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage + 2]];
			curlingPageLImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage + 2]] image]];
		} else {
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]];
			curlingPageLImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]] image]];
		}
		
		[curlingPageL removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:curlingPageL];
		[leftPageShadow removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:leftPageShadow];
		[rightPageShadow removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:rightPageShadow];
		[centerPageShadow removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:centerPageShadow];
	}
	
	[self curlPageToLeft:0];
}

- (void) initCurlPageToRight {
	//NSLog(@"init curl page r");
	curlingPageRShadow.opacity = 0.0f;
	curlingPageRShadow.colors = [NSArray arrayWithObjects:
								 (id)[[UIColor clearColor] CGColor],
								 (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor],
								 (id)[[UIColor clearColor] CGColor], nil];
	curlingPageRShadow.startPoint = CGPointMake(1,0.5);
	curlingPageRShadow.endPoint = CGPointMake(0,0.5);
	
	curlingPageLShadow.colors = [NSArray arrayWithObjects:
								 (id)[[UIColor clearColor] CGColor],
								 (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor],
								 (id)[[UIColor clearColor] CGColor], nil];
	curlingPageLShadow.startPoint = CGPointMake(1,0.5);
	curlingPageLShadow.endPoint = CGPointMake(0,0.5);
	
	leftPageShadow.opacity = 0.0f;
	leftPageShadow.colors = [NSArray arrayWithObjects:
							 (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor],
							 (id)[[UIColor clearColor] CGColor], nil];
	leftPageShadow.startPoint = CGPointMake(1,0.5);
	leftPageShadow.endPoint = CGPointMake(0,0.5);
	
	rightPageShadow.opacity = 0.0f;
	rightPageShadow.colors = [NSArray arrayWithObjects:
							  (id)[[UIColor clearColor] CGColor],
							  (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor], nil];
	rightPageShadow.startPoint = CGPointMake(1,0.5);
	rightPageShadow.endPoint = CGPointMake(0,0.5);
	
	if ( _windowMode == MODE_A ) {
		if ( _direction == DIRECTION_LEFT ) {
			curlingPageL.opacity = 1.0f;
			curlingPageLImage.opacity = 1.0f;
			curlingPageLImage.transform = CATransform3DMakeScale(-1, 1, 1);
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]];
			curlingPageLImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]] image]];
			curlingPageLImageOverlay.opacity = REVERSE_PAGE_OPACITY;
			
			curlingPageR.opacity = 1.0f;
			curlingPageRImage.opacity = 1.0f;
			curlingPageRImage.transform = CATransform3DMakeScale(1, 1, 1);
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]];
			curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]] image]];
			curlingPageRImageOverlay.opacity = 0.0f;
			
			[curlingPageL removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:curlingPageL];
			[leftPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:leftPageShadow];
			[rightPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:rightPageShadow];
		} else {
			curlingPageL.opacity = 1.0f;
			curlingPageLImage.opacity = 1.0f;
			curlingPageLImage.transform = CATransform3DMakeScale(1, 1, 1);
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage]];
			curlingPageLImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
			curlingPageLImageOverlay.opacity = 0.0f;
			
			curlingPageR.opacity = 1.0f;
			curlingPageRImage.opacity = 1.0f;
			curlingPageRImage.transform = CATransform3DMakeScale(-1, 1, 1);
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage]];
			curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
			curlingPageRImageOverlay.opacity = REVERSE_PAGE_OPACITY;
			
			[curlingPageR removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:curlingPageR];
			[leftPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:leftPageShadow];
			[rightPageShadow removeFromSuperlayer];
			[_pageCurlView.layer addSublayer:rightPageShadow];
		}
		[centerPageShadow removeFromSuperlayer];
	} else {
		curlingPageR.opacity = 1.0f;
		curlingPageRImage.opacity = 1.0f;
		curlingPageRImage.transform = CATransform3DMakeScale(1, 1, 1);
		
		curlingPageRImageOverlay.opacity = 0.0f;
		curlingPageLImageOverlay.opacity = 0.0f;
		
		if ( _direction == DIRECTION_LEFT ) {
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage - 1]];
		} else {
			curlingPageRImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage + 2]];
		}
		curlingPageRImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
		
		curlingPageL.opacity = 1.0f;
		curlingPageLImage.opacity = 1.0f;
		curlingPageLImage.transform = CATransform3DMakeScale(1, 1, 1);
		if ( _direction == DIRECTION_LEFT ) {
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage]];
		} else {
			curlingPageLImage.contents = [_imageList objectForKey:[NSNumber numberWithInteger:_currentPage + 1]];
		}
		curlingPageLImage.frame = [self getAspectFittingImageRect:[[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]] image]];
		
		[curlingPageR removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:curlingPageR];
		[leftPageShadow removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:leftPageShadow];
		[rightPageShadow removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:rightPageShadow];
		[centerPageShadow removeFromSuperlayer];
		[_pageCurlView.layer addSublayer:centerPageShadow];
	}
	
	[self curlPageToRight:0];
}

- (void) curlPageToLeft:(float)curlRatio {
	if ( _windowMode == MODE_A ) {
		if ( _direction == DIRECTION_LEFT ) {
			curlingPageRShadow.opacity = 0.0f;
			
			leftPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			leftPageShadow.frame = CGRectMake(WINDOW_AW * curlRatio - BOTTOM_SHADOW_WIDTH, 0, 
											  BOTTOM_SHADOW_WIDTH, WINDOW_AH);
			
			curlingPageL.frame = CGRectMake(WINDOW_AW * curlRatio, 0, 
											WINDOW_AW * curlRatio, WINDOW_AH);
			curlingPageLImage.frame = CGRectMake(-1.0f * WINDOW_AW * (1.0f - curlRatio) + image_margin_x, image_margin_y, 
												 WINDOW_AW, WINDOW_AH);
			
			curlingPageR.frame = CGRectMake(WINDOW_AW * curlRatio, 0, 
											WINDOW_AW * (1.0f - curlRatio), WINDOW_AH);
			curlingPageRImage.frame = CGRectMake(-1.0f * WINDOW_AW * curlRatio + image_margin_x, image_margin_y,
												 curlingPageRImage.frame.size.width, curlingPageRImage.frame.size.height);
			
			curlingPageLShadow.opacity = MAX((0.25f - (curlRatio - 0.5f)*(curlRatio - 0.5f)), 0);
			curlingPageLShadow.frame = CGRectMake((TOP_SHADOW_WIDTH * 0.2) , 0, 
												  TOP_SHADOW_WIDTH, WINDOW_AH);
			
			rightPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			rightPageShadow.frame = CGRectMake(2.0f * WINDOW_AW * curlRatio, 0, 
											   BOTTOM_SHADOW_WIDTH, WINDOW_AH);
		} else {
			curlingPageLShadow.opacity = 0.0f;
			
			leftPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			leftPageShadow.frame = CGRectMake((2.0f * WINDOW_AW * curlRatio) - WINDOW_AW - BOTTOM_SHADOW_WIDTH + image_margin_x, 0, 
											  BOTTOM_SHADOW_WIDTH, WINDOW_AH);
			
			curlingPageR.frame = CGRectMake((2.0f * WINDOW_AW * curlRatio) - WINDOW_AW, 0, 
											WINDOW_AW - (WINDOW_AW * curlRatio), WINDOW_AH);
			curlingPageRImage.frame = CGRectMake(image_margin_x, image_margin_y,
												 curlingPageRImage.frame.size.width, curlingPageRImage.frame.size.height);
			
			curlingPageL.frame = CGRectMake(0, 0, 
											WINDOW_AW * curlRatio, WINDOW_AH);
			curlingPageLImage.frame = CGRectMake(image_margin_x, image_margin_y,
												 curlingPageLImage.frame.size.width, curlingPageLImage.frame.size.height);
			
			curlingPageRShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			curlingPageRShadow.frame = CGRectMake(WINDOW_AW * (1.0f - curlRatio) - (TOP_SHADOW_WIDTH * 1.2), 0, 
												  TOP_SHADOW_WIDTH, WINDOW_AH);
			
			rightPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			rightPageShadow.frame = CGRectMake(WINDOW_AW * curlRatio, 0, 
											   BOTTOM_SHADOW_WIDTH, WINDOW_AH);
		}
		curlingPageRImageOverlay.frame = curlingPageRImage.frame; 
		curlingPageLImageOverlay.frame = curlingPageLImage.frame; 
	} else {
		curlingPageRImageOverlay.opacity = 0.0f;
		curlingPageLImageOverlay.opacity = 0.0f;
		
		leftPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
		leftPageShadow.frame = CGRectMake((WINDOW_BW / 2 ) * curlRatio - BOTTOM_SHADOW_WIDTH, 0, 
										  BOTTOM_SHADOW_WIDTH, WINDOW_AH);
		
		curlingPageR.frame = CGRectMake((WINDOW_BW / 2 ) * curlRatio, 0, 
										MAX((WINDOW_BW / 2) - (WINDOW_BW / 2 ) * curlRatio, 0), WINDOW_BH);
		curlingPageRImage.frame = CGRectMake(-1.0f * (WINDOW_BW / 2) * curlRatio, image_margin_y,
											 curlingPageRImage.frame.size.width, curlingPageRImage.frame.size.height);
		
		curlingPageLShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
		curlingPageLShadow.frame = CGRectMake((TOP_SHADOW_WIDTH * 0.2), 0, 
											  TOP_SHADOW_WIDTH, WINDOW_AH);
		
		curlingPageL.frame = CGRectMake((WINDOW_BW / 2) * curlRatio, 0, 
										(WINDOW_BW / 2) * curlRatio, WINDOW_BH);
		curlingPageLImage.frame = CGRectMake(-1.0f * ((WINDOW_BW / 2) - ((WINDOW_BW / 2) * curlRatio)), image_margin_y,
											 curlingPageLImage.frame.size.width, curlingPageLImage.frame.size.height);
		
		rightPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
		rightPageShadow.frame = CGRectMake(2 * (WINDOW_BW / 2 ) * curlRatio, 0, 
										   BOTTOM_SHADOW_WIDTH, WINDOW_AH);
		
		curlingPageRImageOverlay.frame = curlingPageRImage.frame; 
		curlingPageLImageOverlay.frame = curlingPageLImage.frame; 
	}
}

- (void) curlPageToRight:(float)curlRatio {
	if ( _windowMode == MODE_A ) {
		if ( _direction == DIRECTION_LEFT ) {
			curlingPageRShadow.opacity = 0.0f;
			
			leftPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			leftPageShadow.frame = CGRectMake(WINDOW_AW * (1.0f - curlRatio) - BOTTOM_SHADOW_WIDTH, 0, 
											  BOTTOM_SHADOW_WIDTH, WINDOW_AH);
			
			curlingPageL.frame = CGRectMake(WINDOW_AW * (1.0f - curlRatio), 0, 
											WINDOW_AW * curlRatio, WINDOW_AH);
			curlingPageLImage.frame = CGRectMake((-1.0f * WINDOW_AW * curlRatio) + image_margin_x, image_margin_y,
												 curlingPageLImage.frame.size.width, curlingPageLImage.frame.size.height);
			
			curlingPageR.frame = CGRectMake(WINDOW_AW * (1.0f - curlRatio), 0, 
											WINDOW_AW * curlRatio, WINDOW_AH);
			curlingPageRImage.frame = CGRectMake(WINDOW_AW * (curlRatio - 1.0f) + image_margin_x, image_margin_y,
												 curlingPageRImage.frame.size.width, curlingPageRImage.frame.size.height);
			
			curlingPageLShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			curlingPageLShadow.frame = CGRectMake((TOP_SHADOW_WIDTH * 0.2) , 0, 
												  TOP_SHADOW_WIDTH, WINDOW_AH);
			
			rightPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			rightPageShadow.frame = CGRectMake(2 * WINDOW_AW * (1.0f - curlRatio) - image_margin_x, 0, 
											   BOTTOM_SHADOW_WIDTH, WINDOW_AH);
		} else {
			leftPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			leftPageShadow.frame = CGRectMake(WINDOW_AW * (1.0f - (2 * curlRatio)) + image_margin_x - BOTTOM_SHADOW_WIDTH, 0, 
											  BOTTOM_SHADOW_WIDTH, WINDOW_AH);
			
			curlingPageLShadow.opacity = 0.0f;
			curlingPageL.frame = CGRectMake(0 , 0, 
											WINDOW_AW * (1.0f - curlRatio), WINDOW_AH);
			curlingPageLImage.frame = CGRectMake(image_margin_x, image_margin_y,
												 curlingPageLImage.frame.size.width, curlingPageLImage.frame.size.height);
			
			curlingPageR.frame = CGRectMake(WINDOW_AW * (1.0f - (2 * curlRatio)), 0, 
											WINDOW_AW * curlRatio, WINDOW_AH);
			curlingPageRImage.frame = CGRectMake(image_margin_x, image_margin_y,
												 curlingPageRImage.frame.size.width, curlingPageRImage.frame.size.height);
			
			curlingPageRShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			curlingPageRShadow.frame = CGRectMake(WINDOW_AW * curlRatio - (TOP_SHADOW_WIDTH * 1.2), 0, 
												  TOP_SHADOW_WIDTH, WINDOW_AH);
			
			rightPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
			rightPageShadow.frame = CGRectMake(WINDOW_AW * (1.0f - curlRatio), 0, 
											   BOTTOM_SHADOW_WIDTH, WINDOW_AH);
		}
		
		curlingPageRImageOverlay.frame = curlingPageRImage.frame;
		curlingPageLImageOverlay.frame = curlingPageLImage.frame;
	} else {
		leftPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
		leftPageShadow.frame = CGRectMake(WINDOW_BW - 2 * (WINDOW_BW / 2) * curlRatio - BOTTOM_SHADOW_WIDTH, 0, 
										  BOTTOM_SHADOW_WIDTH, WINDOW_AH);
		
		curlingPageL.frame = CGRectMake(WINDOW_BW / 2 , 0, 
										MAX((WINDOW_BW / 2) - (WINDOW_BW / 2 ) * curlRatio, 0), WINDOW_BH);
		curlingPageLImage.frame = CGRectMake(image_margin_x, image_margin_y,
											 curlingPageLImage.frame.size.width, curlingPageLImage.frame.size.height);
		
		curlingPageR.frame = CGRectMake(WINDOW_BW - 2 * (WINDOW_BW / 2) * curlRatio, 0, 
										(WINDOW_BW / 2) * curlRatio, WINDOW_BH);
		curlingPageRImage.frame = CGRectMake(image_margin_x, image_margin_y,
											 curlingPageRImage.frame.size.width, curlingPageRImage.frame.size.height);
		
		curlingPageRImageOverlay.frame = curlingPageRImage.frame;
		curlingPageLImageOverlay.frame = curlingPageLImage.frame; 
		
		curlingPageRShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
		curlingPageRShadow.frame = CGRectMake((WINDOW_BW / 2) * curlRatio - (TOP_SHADOW_WIDTH * 1.2), 0, 
											  TOP_SHADOW_WIDTH, WINDOW_AH);
		
		rightPageShadow.opacity = MAX((0.25f - (curlRatio - 0.5)*(curlRatio - 0.5)), 0);
		rightPageShadow.frame = CGRectMake(WINDOW_BW - (WINDOW_BW / 2) * curlRatio, 0, 
										   BOTTOM_SHADOW_WIDTH, WINDOW_AH);
	}
}

- (void)notifyGoToNextPage {
	//NSLog(@"next");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"goToNextPageEvent" object:nil userInfo:nil];
}

- (void)notifyGoToPrevPage {
	//NSLog(@"prev");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"goToPrevPageEvent" object:nil userInfo:nil];
}

- (void)setModeToNone {
	_mode = page_mode_none;
	//NSLog(@"set none");
}

- (void)endToCurl {
	if ( _windowMode == MODE_A) {
		[self removeAllSubviewsFrom:_rightView];
		[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]]];
	} else {
		if ( _mode == page_mode_curl_right ) {
			//NSLog(@"end to curl right");
			if ( _direction == DIRECTION_LEFT ) {
				[self removeAllSubviewsFrom:_rightView];
				[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]]];
				[self removeAllSubviewsFrom:_leftView];
				[_leftView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage + 1]]];
			} else {
				[self removeAllSubviewsFrom:_rightView];
				[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage + 1]]];
				[self removeAllSubviewsFrom:_leftView];
				[_leftView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]]];
			}
		} else {
			//NSLog(@"end to curl left");
			if ( _direction == DIRECTION_LEFT ) {
				[self removeAllSubviewsFrom:_rightView];
				[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]]];
				[self removeAllSubviewsFrom:_leftView];
				[_leftView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage+1]]];
			} else {
				[self removeAllSubviewsFrom:_rightView];
				[_rightView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage+1]]];
				[self removeAllSubviewsFrom:_leftView];
				[_leftView addSubview:[_pageList objectForKey:[NSNumber numberWithInteger:_currentPage]]];
			}
		}
	}
	
	_mode = page_mode_wait;
	
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
    leftPageShadow.opacity = 0.0f;
    rightPageShadow.opacity = 0.0f;
    curlingPageR.opacity = 0.0f;
    curlingPageL.opacity = 0.0f;
	[CATransaction commit];
}

- (CGImageRef)getImageRefFromUIImage:(UIImage *)im0 {
	UIImage *im = im0;
	CGSize pageSize = im0.size;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, 
												 pageSize.width, 
												 pageSize.height, 
												 8,				/* bits per component*/
												 pageSize.width * 4, 	/* bytes per row */
												 colorSpace, 
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	
	CGColorSpaceRelease(colorSpace);
	
	CGContextClipToRect(context, CGRectMake(0, 0, pageSize.width, pageSize.height));
	
	CGRect imageRect = CGRectMake(0, 0, im.size.width, im.size.height);
	CGAffineTransform transform = aspectFit(imageRect,
											CGContextGetClipBoundingBox(context));
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, imageRect, [im CGImage]);
	
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	[UIImage imageWithCGImage:image];
	CGImageRelease(image);
	
	return image;
}

- (CGRect) getAspectFittingImageRect:(UIImage *)im0 {
	UIImage * im = im0;
	
	if ( _windowMode == MODE_A ) {
		if ( WINDOW_AW / WINDOW_AH < im.size.width / im.size.height ) {
			image_margin_y = 0;
			image_margin_x = (WINDOW_AW - (WINDOW_AH * (im.size.width / im.size.height))) / 2;
			return CGRectMake(image_margin_x, 0, floor(WINDOW_AH * (im.size.width / im.size.height)) , WINDOW_AH);
		} else {
			image_margin_x = 0;
			image_margin_y = (WINDOW_AH - (WINDOW_AW * (im.size.height / im.size.width))) / 2;
			return CGRectMake(0, image_margin_y, WINDOW_AW, floor(WINDOW_AW * (im.size.height / im.size.width)));
		}
	} else {
		if ( (WINDOW_BW / 2 ) / WINDOW_BH > im.size.width / im.size.height ) {
			image_margin_x = ((WINDOW_BW / 2) - (WINDOW_BH * (im.size.width / im.size.height))) / 2;
			//image_margin_x = 0;
			image_margin_y = 0;
			return CGRectMake(image_margin_x, 0, WINDOW_BH * (im.size.width / im.size.height) , WINDOW_BH);
		} else { 
			image_margin_x = 0;
			image_margin_y = (WINDOW_BH - ((WINDOW_BW / 2) * (im.size.height / im.size.width))) / 2;
			//image_margin_y = 0;
			return CGRectMake(0, image_margin_y, (WINDOW_BW / 2), (WINDOW_BW / 2) * (im.size.height / im.size.width));
		}
	}
}

@end
