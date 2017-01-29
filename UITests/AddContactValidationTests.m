//
//  AddContactValidationTests.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 29/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//

#import "AddContactValidationTests.h"
#import <KIF/KIFTestStepValidation.h>

@implementation AddContactValidationTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"+"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void)testFirstNameEmpty
{
    NSString *firstNameId = @"First Name Field";
    [tester waitForViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:firstNameId];
    [tester enterText:@"" intoViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"First Name Error Label"];
}

- (void)testFirstNameLessThanThreeChars
{
    NSString *firstNameId = @"First Name Field";
    [tester waitForViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:firstNameId];
    [tester enterText:@"ab" intoViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"First Name Error Label"];
}

- (void)testFirstNameValid1
{
    NSString *firstNameId = @"First Name Field";
    [tester waitForViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:firstNameId];
    [tester enterText:@"abc" intoViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"First Name Error Label"];
}

- (void)testFirstNameValid2
{
    NSString *firstNameId = @"First Name Field";
    [tester waitForViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:firstNameId];
    [tester enterText:@"Simon" intoViewWithAccessibilityLabel:firstNameId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"First Name Error Label"];
}

- (void)testLastNameEmpty
{
    NSString *lastNameId = @"Last Name Field";
    [tester waitForViewWithAccessibilityLabel:lastNameId];
    [tester tapViewWithAccessibilityLabel:lastNameId];
    [tester enterText:@"" intoViewWithAccessibilityLabel:lastNameId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Last Name Error Label"];
}

- (void)testLastName
{
    NSString *lastNameId = @"Last Name Field";
    [tester waitForViewWithAccessibilityLabel:lastNameId];
    [tester tapViewWithAccessibilityLabel:lastNameId];
    [tester enterText:@"Cowell" intoViewWithAccessibilityLabel:lastNameId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Last Name Error Label"];
}

- (void)testMobileNumberEmpty
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testMobileInvalidFormat1
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"123" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testMobileInvalidFormat2
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"abc" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testMobileInvalidFormat3
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"ssd078" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testMobileInvalidFormat4
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"+120 abc" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testMobileInvalidFormat5
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"+120 abc" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testMobileValidFormat1
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"+91 9988776655" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testMobileValidFormat2
{
    NSString *mobileNumberId = @"Mobile Number Field";
    [tester waitForViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:mobileNumberId];
    [tester enterText:@"09988556677" intoViewWithAccessibilityLabel:mobileNumberId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Mobile Number Error Label"];
}

- (void)testEmailEmpty
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailInvalidFormat1
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"asd" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailInvalidFormat2
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"asd@" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailInvalidFormat3
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"asd@asd" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailInvalidFormat4
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"asd@asd." intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailInvalidFormat5
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"asd@asd.c" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailInvalidFormat6
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"asd.co" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailValidFormat1
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"john@mail.com" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Email Error Label"];
}

- (void)testEmailValidFormat2
{
    NSString *emailId = @"Email Field";
    [tester waitForViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:emailId];
    [tester enterText:@"john@mail.co.in" intoViewWithAccessibilityLabel:emailId];
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Email Error Label"];
}

@end
