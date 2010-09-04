//
//  WePublishViewController.h
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/26.
//  Copyright 3di 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LogoViewCtrl;
@class LoginViewCtrl;
@class XMLController;
@class BookCollection;
@class ListViewCtrl;
@class BuyViewCtrl;
@class DetailViewCtrl;
@class ReadViewCtrl;

@interface WePublishViewController : UIViewController {
	
	UIScrollView *_scrollView;
	UIActivityIndicatorView *_activitiyView;
	UILabel *statusLabel_;
	LogoViewCtrl *_logoView;
	LoginViewCtrl *_loginView;
	XMLController *_xmlCtrl;
	BookCollection *_bookCollection;
	ListViewCtrl *_listViewCtrl;
	BuyViewCtrl *_buyViewCtrl;
	DetailViewCtrl *_detailViewCtrl;
	ReadViewCtrl *_readViewCtrl;
	UIBarButtonItem *_bookBarButton;
	UIBarButtonItem *_listBarButton;
	UIBarButtonItem *_trashBarButton;
	UIBarButtonItem *_buyBarButton;
	NSMutableDictionary *_tmpDlDic;
	NSMutableDictionary *_bookmarkDic;
	NSString *_bookmarkPath;
	NSMutableArray *_aBgList;
	NSMutableArray *_bBgList;
	NSMutableArray *_buttons;
	NSInteger _windowMode;
	NSInteger _selectBookIndex;
	NSInteger _bookmarkPage;
	BOOL _updating;
	NSUInteger currentPage_;
	NSUInteger updateRequestFileCount_;
	NSUInteger updateTotalDownloadCount_;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activitiyView;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *bookBarButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *listBarButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *trashBarButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buyBarButton;

- (void)initDirectory;
- (void)initBooks;
- (void)setImageToBooks;
- (void)initAnimation:(NSString *)animationID duration:(NSTimeInterval)duration;
- (void)logoToTop;
- (void)showAlert:(NSString *)title message:(NSString *)message btn1:(NSString *)btn1 btn2:(NSString *)btn2 tag:(NSUInteger)tag;
- (void)trashAllData;
- (void)updateXML;
- (void)updateXMLFinish;
- (void)setBooks:(BOOL)animation;
- (void)reloadBooks;
- (void)releaseBackground:(NSInteger)windowModeType;
- (void)releaseBooks:(BOOL)scrollHidden;
- (void)setMenuBarItems:(BOOL)book list:(BOOL)list trash:(BOOL)trash buy:(BOOL)buy;
- (void)showDetail:(NSInteger)bookIndex;
- (void)showBook:(NSUInteger)selectPage;
- (void)releaseListView;
- (void)releaseBuyView;
- (void)changeOrientation:(BOOL)animation;
- (void)releaseXML;

- (IBAction)onMenuBookClick:(id)sender;
- (IBAction)onMenuListClick:(id)sender;
- (IBAction)onMenuTrashClick:(id)sender;
- (IBAction)onMenuBuyClick:(id)sender;

@end

