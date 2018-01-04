#import "OMSCardIOManager.h"
@import CardIO;

@implementation OMSCardIOManager


+ (BOOL)canReadCardWithCamera {
    NSLog(@"%@", [CardIOUtilities class]);
    NSLog(@"%d", [[CardIOUtilities class] canReadCardWithCamera]);
    return [[CardIOUtilities class] canReadCardWithCamera];
}

+ (CardIOPaymentViewController * _Nullable)cardIOPaymentViewControllerWithDelegate:(id<CardIOPaymentViewControllerDelegate>)delegate {
    CardIOPaymentViewController *cardIOPaymentViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:delegate];
    cardIOPaymentViewController.hideCardIOLogo = YES;
    cardIOPaymentViewController.disableManualEntryButtons = YES;
    cardIOPaymentViewController.collectCVV = NO;
    cardIOPaymentViewController.collectExpiry = YES;
    cardIOPaymentViewController.scanExpiry = YES;
    cardIOPaymentViewController.suppressScanConfirmation = YES;
    return cardIOPaymentViewController;
}

@end
