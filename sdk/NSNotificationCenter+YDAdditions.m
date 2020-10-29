/* Лицензионное соглашение на использование набора средств разработки
 * «SDK Яндекс.Диска» доступно по адресу: http://legal.yandex.ru/sdk_agreement
 */


#import "NSNotificationCenter+YDAdditions.h"

@implementation NSNotificationCenter (Additions)

- (void)postNotificationInMainQueueWithName:(NSString *)aName
                                     object:(id)anObject
                                   userInfo:(NSDictionary *)aUserInfo
{
    if ([NSThread isMainThread]) {
        [self postNotificationName:aName object:anObject userInfo:aUserInfo];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postNotificationName:aName object:anObject userInfo:aUserInfo];
        });
    }
}

@end
