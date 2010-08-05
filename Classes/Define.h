//
//  Define.h
//  WePublish
//
//  Created by Yusuke Kikkawa on 10/06/28.
//  Copyright 2010 3di. All rights reserved.
//

#import <UIKit/UIKit.h>

// Flag
#define USE_WEBKIT false

// Page size
#define WINDOW_AW 768
#define WINDOW_AH 1024
#define WINDOW_BW 1024
#define WINDOW_BH 768

// URL
#define TOP_URL @"http://wepublish.jp/"
#define UPDATE_URL @"http://wepublish.jp/mypage/login_check.php"
#define NEW_ACCOUNT_URL @"http://wepublish.jp/entry/kiyaku.php"

// Event
#define APP_FINISH_EVENT @"app_finish_event"
#define LOGO_END_EVENT @"logo_end_event"
#define AUTHENTICATION_EVENT @"autheantication_event"
#define LOGIN_FINISH_END_EVENT @"login_finish_event"
#define LOGIN_FINISHED_AND_XML_CHECK_EVENT @"login_finished_and_xml_check_event"
#define PARSE_END_EVENT @"parse_end_event"               // XML解析完了
#define DLBOOK_SUCCESS_EVENT @"dlbook_success_event"     // DL成功
#define DLBOOK_ERROR_EVENT @"dlbook_error_event"         // DL失敗
#define BOOKMARK_SAVE_EVENT @"bookmark_save_event"       // しおり保存
#define READ_TO_SELECT_EVENT @"read_to_select_event"     // 読む画面から選択画面へ
#define LIST_TO_DETAIL_EVENT @"list_to_detail_event"     // 詳細画面から選択画面へ
#define DETAIL_DISAPPEAR_EVENT @"detail_disappear_event" // 詳細画面を消すアニメーション開始
#define DETAIL_TO_READ_EVENT @"detail_to_read_event"     // 詳細画面から読む画面へ

// TagID
#define TRASH_ALERT_TAG 100
#define RELOAD_DATA_ALERT_TAG 101
#define BOOKMARK_ALERT_TAG 102

// Auth
#define UPDATE_RETRY_COUNT 2

// Message
#define WARNING_TITLE @"警告"
#define BOOKMARK_MESSAGE @"続きから読みますか？"
#define TRASH_WARNING_MESSAGE @"iPadに保存されたアカウントと本を削除します。\nアカウントを再設定後、本を再ダウンロードします。\nよろしいですか？"
#define RELOAD_DATA_WARNING_MESSAGE @"データを再取得しますか？"
#define AUTHENTICATION_ERROR_MESSAGE @"認証に失敗しました"
#define NETWORK_ERROR_MESSAGE @"ネットワークに接続されていません"
#define NETWORK_ERROR_LOGO_MESSAGE @"情報が取得できません\nアプリケーションを終了して下さい"

#define XML_DIRECTORY @"xml"
#define BOOK_DIRECTORY @"xml/book"
#define BOOK_EXTENSION @"jpg"
#define LIST_FILENAME @"list.xml"
#define USER_FILENAME @"user.xml"
#define BOOKMARK_FILENAME @"bookmark.xml"
#define USER_NAME @"name"
#define USER_PASS @"pass"
#define BOOKMARK_UUID @"uuid"
#define BOOKMARK_PAGE @"page"
