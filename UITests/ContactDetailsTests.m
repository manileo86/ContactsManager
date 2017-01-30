//
//  ContactDetailsTests.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 30/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//

#import "ContactDetailsTests.h"
#import "TestHeader.h"

@implementation ContactDetailsTests

- (void)beforeEach
{
    [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Contacts Table"];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Contacts Table"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void)testDetailsViewElements
{
    [tester waitForViewWithAccessibilityLabel:@"Details Profile Pic Image View"];
    [tester waitForViewWithAccessibilityLabel:@"Details Name Button"];
    [tester waitForViewWithAccessibilityLabel:@"Details Phone Button"];
    [tester waitForViewWithAccessibilityLabel:@"Details Email Button"];
    [tester waitForViewWithAccessibilityLabel:@"Details Share Button"];
}

- (void)testDetailsNameTap
{
    UIButton *nameButton = (UIButton*)[tester waitForViewWithAccessibilityLabel:@"Details Name Button"];
    NSData *favImageBeforeData = UIImagePNGRepresentation(nameButton.imageView.image);
    [tester tapViewWithAccessibilityLabel:@"Details Name Button"];
    NSData *favImageAfterData = UIImagePNGRepresentation(nameButton.imageView.image);
    
    NSData *heartImageData = UIImagePNGRepresentation([UIImage imageNamed:@"heart"]);
    NSData *heartGreyImageData = UIImagePNGRepresentation([UIImage imageNamed:@"heart_grey"]);
    
    if([favImageBeforeData isEqual:heartImageData])
    {
        KIFAssertEqualObjects(favImageAfterData, heartGreyImageData, @"Expected to toggle the favorite indication");
    }
    
    if([favImageAfterData isEqual:heartGreyImageData])
    {
        KIFAssertEqualObjects(favImageAfterData, heartImageData, @"Expected to toggle the favorite indication");
    }
}

- (void)testPhoneNumberTap
{
    UIButton *phoneButton = (UIButton*)[tester waitForViewWithAccessibilityLabel:@"Details Phone Button"];
    NSString *phoneNumber = [phoneButton titleForState:UIControlStateNormal];
    [tester tapViewWithAccessibilityLabel:@"Details Phone Button"];
    [tester waitForViewWithAccessibilityLabel:phoneNumber];
    [tester waitForTappableViewWithAccessibilityLabel:@"Call"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Message"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)testPhoneNumberCall
{
    UIButton *phoneButton = (UIButton*)[tester waitForViewWithAccessibilityLabel:@"Details Phone Button"];
    NSString *phoneNumber = [phoneButton titleForState:UIControlStateNormal];
    [tester tapViewWithAccessibilityLabel:@"Details Phone Button"];
    [tester waitForViewWithAccessibilityLabel:phoneNumber];
    [tester waitForTappableViewWithAccessibilityLabel:@"Call"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Message"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    
    [tester tapViewWithAccessibilityLabel:@"Call"];
    if([tester acknowledgeSystemAlert])
    {
        if([tester waitForViewWithAccessibilityLabel:@"Dismiss"])
            [tester tapViewWithAccessibilityLabel:@"Dismiss"];
    }
}

- (void)testPhoneNumberMessasge
{
    UIButton *phoneButton = (UIButton*)[tester waitForViewWithAccessibilityLabel:@"Details Phone Button"];
    NSString *phoneNumber = [phoneButton titleForState:UIControlStateNormal];
    [tester tapViewWithAccessibilityLabel:@"Details Phone Button"];
    [tester waitForViewWithAccessibilityLabel:phoneNumber];
    [tester waitForTappableViewWithAccessibilityLabel:@"Call"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Message"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    
    [tester tapViewWithAccessibilityLabel:@"Message"];    
    
    if([tester waitForViewWithAccessibilityLabel:@"Dismiss"])
        [tester tapViewWithAccessibilityLabel:@"Dismiss"];
}

- (void)testEmail
{
    [tester waitForViewWithAccessibilityLabel:@"Details Email Button"];
    [tester tapViewWithAccessibilityLabel:@"Details Email Button"];
    
    if([tester waitForViewWithAccessibilityLabel:@"Ok"])
        [tester tapViewWithAccessibilityLabel:@"Ok"];
}

- (void)testShare
{
    [tester waitForViewWithAccessibilityLabel:@"Details Share Button"];
    [tester tapViewWithAccessibilityLabel:@"Details Share Button"];
 
    if([tester waitForViewWithAccessibilityLabel:@"Cancel"])
        [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)testShareVCFGeneration
{
    [tester waitForViewWithAccessibilityLabel:@"Details Share Button"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"contact"] URLByAppendingPathExtension:@"vcf"];
    NSString *fileURLPath = [fileURL path];
    
    // Remove old file
    if([fileManager fileExistsAtPath:fileURLPath])
    {
        NSError *error;
        [fileManager removeItemAtPath:fileURLPath error:&error];
        if(error)
        {
            NSLog(@"Old file not deleted");
        }
    }
    
    [tester tapViewWithAccessibilityLabel:@"Details Share Button"];
    [tester waitForViewWithAccessibilityLabel:@"Share Contact Activity Controller"];
    [tester waitForTimeInterval:0.5f]; // Wait for file to be generated    
    // File should be exisiting now
    KIFAssertTrue([fileManager fileExistsAtPath:fileURLPath]);
    
    if([tester waitForViewWithAccessibilityLabel:@"Cancel"])
        [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

@end
