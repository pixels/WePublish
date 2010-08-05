//
//  ReadViewCtrl.h
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/27.
//  Copyright 2010 3di. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ReadViewACtrl;
@class ReadViewBCtrl;

@interface ReadViewCtrl : UIViewController {
	UISlider *_slider;
	NSInteger _windowMode;
	NSInteger _direction;
	NSString *_uuid;
	NSInteger _pageNum;
	NSInteger _fakePage;
	NSUInteger _selectPage;
	ReadViewACtrl *_readViewACtrl;
	ReadViewBCtrl *_readViewBCtrl;
	UIButton *_lButton;
	UIButton *_rButton;
}

@property (nonatomic, retain) IBOutlet UISlider *slider;
@property (nonatomic, retain) IBOutlet UIButton *lButton;
@property (nonatomic, retain) IBOutlet UIButton *rButton;

- (void)setup:(NSString *)uuid selectPage:(NSUInteger)selectPage pageNum:(NSInteger)pageNum fakePage:(NSInteger)fakePage direction:(NSInteger)direction;
- (void)initAnimation:(NSString *)animationID duration:(NSTimeInterval)duration;
- (void)changeOrientation;
- (void)cleanupCurrentView:(NSInteger)requireMode;
- (void)pageNext;
- (void)pagePrev;
- (void)onUpdateSlider:(UISlider *)aSlider;
- (void)onTouchImage:(NSNotification *)notification;
- (IBAction)onBackClick:(id)sender;
@end
