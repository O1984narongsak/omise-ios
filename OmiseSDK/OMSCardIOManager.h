@import Foundation;

@class CardIOPaymentViewController;
@protocol CardIOPaymentViewControllerDelegate;


@interface OMSCardIOManager : NSObject

+ (BOOL)canReadCardWithCamera;

+ (CardIOPaymentViewController * _Nullable)cardIOPaymentViewControllerWithDelegate:(id<CardIOPaymentViewControllerDelegate> _Nullable)delegate;


@end
