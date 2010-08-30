//
//  ReadViewACtrl.h
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/27.
//  Copyright 2010 3di. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Utilities.h"
#import "ReadViewBaseCtrl.h"
#import "UIViewWithTouchesDelegate.h"
#import "MyScrollView.h"

enum {
  page_mode_none,
  page_mode_curl_start,
  page_mode_curl_right,
  page_mode_curl_left,
  page_mode_zoom,
  page_mode_wait
};

@interface ReadViewACtrl : ReadViewBaseCtrl <UIScrollViewDelegate> {
	MyScrollView *_scrollView;

	UIView * _rightView;
	UIView * _leftView;
	UIViewWithTouchesDelegate * _pageCurlView;

	NSInteger _mode;

	CGPoint touchStartPoint;

	CAGradientLayer * rightPageShadow;

	CALayer *curlingPageR;
	CALayer *curlingPageRImage;
	CALayer *curlingPageRImageOverlay;
	CAGradientLayer * curlingPageRShadow;

	CALayer *curlingPageL;
	CALayer *curlingPageLImage;
	CALayer *curlingPageLImageOverlay;
	CAGradientLayer * curlingPageLShadow;

	CAGradientLayer * leftPageShadow;

	float image_margin_x, image_margin_y;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

- (void)initLayers:(UIView *)targetView;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
- (void)resetContentsSize;
- (void)setPage:(NSInteger)selectPage windowMode:(NSInteger)windowMode;
- (void)setPageForSingleFace:(NSInteger)selectPage;
- (void)setPageForDoubleFace:(NSInteger)selectPage;
- (void)releaseFarBooks:(NSInteger)targetPage;
- (CGRect)getAspectFittingImageRect:(UIImage *)im0;
- (void)curlPageToLeft:(float)curlRatio;
- (void)curlPageToRight:(float)curlRatio;
- (void)initCurlPageToLeft;
- (void)initCurlPageToRight;
- (void)beginToCurlLeft;
- (void)beginToCurlRight;
- (void)notifyGoToNextPage;
- (void)notifyGoToPrevPage;
- (void)setModeToNone;
- (CGImageRef)getImageRefFromUIImage:(UIImage *)im0;

@end
