//
//  FavoriteContactsTests.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 30/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//

#import "FavoriteContactsTests.h"
#import "TestHeader.h"

@implementation FavoriteContactsTests

-(void)testFavorites
{
    UITableView *tableView;
    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"Contacts Table" tappable:NO];
    
    NSUInteger totalRows = 0;
    NSInteger sections = [tableView numberOfSections];
    for(int s=0; s<sections; s++)
    {
        NSUInteger rows = [tableView numberOfRowsInSection:s];
        for(int r=0; r<rows; r++)
        {
            totalRows ++;
        }
    }
    
    [tester tapViewWithAccessibilityLabel:@"Favorites Button"];
    
    [tester waitForTimeInterval:0.5f]; // Wait for tableview reload
    
    NSUInteger totalFavoritesRows = 0;
    sections = [tableView numberOfSections];
    for(int s=0; s<sections; s++)
    {
        NSUInteger rows = [tableView numberOfRowsInSection:s];
        for(int r=0; r<rows; r++)
        {
            totalFavoritesRows ++;
        }
    }
    
    KIFAssertTrue(totalRows >= totalFavoritesRows);
    
    [tester tapViewWithAccessibilityLabel:@"Favorites Button"];
    
    NSUInteger newTotalRows = 0;
    sections = [tableView numberOfSections];
    for(int s=0; s<sections; s++)
    {
        NSUInteger rows = [tableView numberOfRowsInSection:s];
        for(int r=0; r<rows; r++)
        {
            newTotalRows ++;
        }
    }
    
    KIFAssertTrue(totalRows >= newTotalRows);
}

-(void)testFavoritesFilteredResults
{
    [tester waitForViewWithAccessibilityLabel:@"Favorites Button"];
    [tester tapViewWithAccessibilityLabel:@"Favorites Button"];
    
    [tester waitForTimeInterval:0.5f]; // Wait for tableview reload
    
    UITableView *tableView;
    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"Contacts Table" tappable:NO];
    
    NSInteger sections = [tableView numberOfSections];
    for(int s=0; s<sections; s++)
    {
        NSUInteger rows = [tableView numberOfRowsInSection:s];
        for(int r=0; r<rows; r++)
        {
            [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s] inTableViewWithAccessibilityIdentifier:@"Contacts Table"];
            
            NSData *heartImageData = UIImagePNGRepresentation([UIImage imageNamed:@"heart"]);
            UIButton *nameButton = (UIButton*)[tester waitForViewWithAccessibilityLabel:@"Details Name Button"];
            NSData *favImageData = UIImagePNGRepresentation(nameButton.imageView.image);
            
            KIFAssertEqualObjects(favImageData, heartImageData, @"Expected the contact to be a favorite.");
            
            [tester tapViewWithAccessibilityLabel:@"Back"];
        }
    }
}

@end
