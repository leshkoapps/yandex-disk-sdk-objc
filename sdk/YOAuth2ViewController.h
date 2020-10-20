/* Лицензионное соглашение на использование набора средств разработки
 * «SDK Яндекс.Диска» доступно по адресу: http://legal.yandex.ru/sdk_agreement
 */


#import <UIKit/UIKit.h>
#import "YOAuth2Protocol.h"

typedef NS_ENUM(NSUInteger, YOAuth2ViewControllerOptions) {
    YOAuth2ViewControllerOptionsNone = 0,
    YOAuth2ViewControllerOptionsClearCookies = 1 << 1,
};

@interface YOAuth2ViewController : UIViewController <YOAuth2Protocol>

- (instancetype)initWithDelegate:(id<YOAuth2Delegate>)delegate options:(YOAuth2ViewControllerOptions)options;

@end
