//
//  ContactsFetchTests.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 29/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//

#import "ContactsFetchTests.h"
#import <KIF/KIF.h>

@implementation ContactsFetchTests

//- (void)testScrollingToTop
//{
//    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] inTableViewWithAccessibilityIdentifier:@"Contacts Table"];
//    [tester tapViewWithAccessibilityLabel: @"Back"];
//    [tester tapStatusBar];
//    
//    UITableView *tableView;
//    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"Contacts Table" tappable:NO];
//    [tester runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
//        KIFTestWaitCondition(tableView.contentOffset.y == - tableView.contentInset.top, error, @"Waited for scroll view to scroll to top, but it ended at %@", NSStringFromCGPoint(tableView.contentOffset));
//        return KIFTestStepResultSuccess;
//    }];
//}

//- (void)testAddContact
//{
//    [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Contacts Table"];
//    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Contacts Table"];
//    [tester tapViewWithAccessibilityLabel: @"Back"];
//}
//
//- (void)testShowAddContact
//{
//    [tester tapViewWithAccessibilityLabel:@"+"];
//    [tester tapViewWithAccessibilityLabel: @"Back"];
//}

@end
