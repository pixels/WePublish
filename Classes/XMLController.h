//
//  XMLController.h
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/07/13.
//  Copyright 2010 3di. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BookInfo;
@class BookCollection;

@interface XMLController : NSObject {
	NSUInteger _updateRetryCount;
	NSString* _url;
	NSString* _userFilePath;
	NSString* _outputFilePath;
	NSData* _savedData;
	NSMutableData* _data;
	NSString *_currentNodeType;
	BookInfo *_currentBookInfo;
	BookCollection *_savedBookCollection;
	BookCollection *_bookCollection;
	BOOL _savedXMLLoad;
}

- (void)update:(NSString*)url;
- (void)updateContinue;
- (void)saveXML;
- (void)alertIfDontExistData:(NSString *)message;
- (void)parse:(NSData *)data savedXMLLoad:(BOOL)savedXMLLoad;

@end
