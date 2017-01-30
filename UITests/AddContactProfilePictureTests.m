//
//  AddContactProfilePictureTests.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 30/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//

#import "AddContactProfilePictureTests.h"
#import "TestHeader.h"

@implementation AddContactProfilePictureTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"+"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void)testProfilePicActionSheet
{
    [tester tapViewWithAccessibilityLabel:@"Avatar Button"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Open Camera"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)testProfilePicChoosing
{
    UIButton *avatarButton = (UIButton*)[tester waitForViewWithAccessibilityLabel:@"Avatar Button"];
    [tester tapViewWithAccessibilityLabel:@"Avatar Button"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Open Camera"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    NSData *avatarData = UIImagePNGRepresentation(avatarButton.imageView.image);
    NSData *defaultAvatarData = UIImagePNGRepresentation([UIImage imageNamed:@"default_avatar"]);
    
    KIFAssertEqualObjects(avatarData, defaultAvatarData, @"Expected Default Avatar");
    
    [tester tapViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester acknowledgeSystemAlert];
    [tester waitForTimeInterval:0.5f]; // Wait for view to stabilize
    [tester choosePhotoInAlbum:@"Camera Roll" atRow:0 column:0];
    [tester tapViewWithAccessibilityLabel:@"Choose"];
    
    NSData *updatedAvatarData = UIImagePNGRepresentation(avatarButton.imageView.image);
    KIFAssertFalse([updatedAvatarData isEqual:defaultAvatarData]);
    
    // Check the action sheet again for Remove Photo option
    [tester tapViewWithAccessibilityLabel:@"Avatar Button"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Open Camera"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Remove Photo"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)testProfilePicChoosingAndRemoving
{
    UIButton *avatarButton = (UIButton*)[tester waitForViewWithAccessibilityLabel:@"Avatar Button"];
    [tester tapViewWithAccessibilityLabel:@"Avatar Button"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Open Camera"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    
    NSData *avatarData = UIImagePNGRepresentation(avatarButton.imageView.image);
    NSData *defaultAvatarData = UIImagePNGRepresentation([UIImage imageNamed:@"default_avatar"]);
    
    KIFAssertEqualObjects(avatarData, defaultAvatarData, @"Expected Default Avatar");
    
    [tester tapViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester acknowledgeSystemAlert];
    [tester waitForTimeInterval:0.5f]; // Wait for view to stabilize
    [tester choosePhotoInAlbum:@"Camera Roll" atRow:0 column:0];
    [tester tapViewWithAccessibilityLabel:@"Choose"];
    
    NSData *updatedAvatarData = UIImagePNGRepresentation(avatarButton.imageView.image);
    KIFAssertFalse([updatedAvatarData isEqual:defaultAvatarData]);
    
    // Check the action sheet again for Remove Photo option
    [tester tapViewWithAccessibilityLabel:@"Avatar Button"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Open Camera"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Remove Photo"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    [tester tapViewWithAccessibilityLabel:@"Remove Photo"];
    
    updatedAvatarData = UIImagePNGRepresentation(avatarButton.imageView.image);
    KIFAssertEqualObjects(updatedAvatarData, defaultAvatarData, @"Expected Default Avatar");
    
    // Check the action sheet again for options
    [tester tapViewWithAccessibilityLabel:@"Avatar Button"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Open Camera"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Select from Gallery"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Remove Photo"];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

@end
