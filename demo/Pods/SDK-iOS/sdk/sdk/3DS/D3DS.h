#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

extern NSString * const  POST_BACK_URL;

@protocol D3DSDelegate
@required
-(void) willPresentWebView: (WKWebView*) webView;
-(void) authorizationCompletedWithMD: (NSString *) md andPares: (NSString *) paRes;
-(void) authorizationFailedWithHtml: (NSString *) html;
@end

@interface D3DS : NSObject <WKNavigationDelegate> {
    __weak id<D3DSDelegate> d3DSDelegate;
}

-(void) make3DSPaymentWithDelegate: (id<D3DSDelegate>) delegate andAcsURLString: (NSString *) acsUrlString andPaReqString: (NSString *) paReqString andTransactionIdString: (NSString *) transactionIdString;

@end
