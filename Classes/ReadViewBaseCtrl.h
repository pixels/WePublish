//
//  ReadViewBaseCtrl.h
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/27.
//  Copyright 2010 3di. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReadViewBaseCtrl : UIViewController <UIScrollViewDelegate> {
	NSMutableDictionary *_booksList;
	NSString *_uuid;
	NSInteger _direction;
	NSInteger _currentPage;
	NSInteger _maxPage;
	float _scrollOffsetX;
}

@property (assign) NSInteger currentPage;

- (BOOL)isNext;
- (void)next;
- (BOOL)isPrev;
- (void)prev;
- (void)requestPage:(NSInteger)targetPage;
- (void)setup:(NSString *)uuid selectPage:(NSUInteger)selectPage pageNum:(NSInteger)pageNum direction:(NSInteger)direction;
- (void)setPage:(NSInteger)selectPage;
- (void)saveBookmark;
- (void)releaseBook:(NSNumber*)pageNo removeFromList:(BOOL)removeFromList;
- (void)releaseAllBooks;

@end
