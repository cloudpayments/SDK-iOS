#import "CPCardApi.h"

@interface CPCardApi (Private)
@end

@implementation CPCardApi

- (void)getBinInfo:(NSString *)firstSixDigits
{
  NSURLSessionConfiguration *defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultSessionConfiguration];

    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"https://widget.cloudpayments.ru/Home/BinInfo?firstSixDigits=%@", firstSixDigits]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];

    [urlRequest setHTTPMethod:@"GET"];

    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

        BOOL success = results[@"Success"];
        
        if (success && results[@"Model"] != nil) {
            
            results = results[@"Model"];
            NSString *bankName = results[@"BankName"];
            NSString *logoUrl = results[@"LogoUrl"];
            BinInfo *binInfo = [BinInfo alloc];
            binInfo.bankName = bankName;
            binInfo.logoUrl = logoUrl;
            
            if (self.delegate != nil)
            {
                [self.delegate didFinishBinInfo: binInfo];
            }

        } else {
            
            NSString *error = @"Unable to determine bank";
            
            if (self.delegate != nil)
            {
                //[self.delegate didFailWithError: error];
            }
        }

    }];

    [dataTask resume];
}

@end
