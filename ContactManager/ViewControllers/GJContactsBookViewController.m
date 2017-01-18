//
//  GJContactsBookViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsBookViewController.h"
#import <CoreData/CoreData.h>
#import "APIClient.h"
#import "GJContactTableViewCell.h"

@interface GJContactsBookViewController ()<NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, GJContactTableViewCellDelegate>

@property (strong, nonatomic) NSFetchedResultsController *myContactsFRC;

@end

@implementation GJContactsBookViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[APIClient defaultClient] getContactsWithCompletionBlock:^(NSError *error, NSDictionary *data) {
        
    }];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0f;
    if(section == 0)
    {
        return 44.0f;
    }
    else
    {
        return 44.0f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    return header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger rowsCount = self.myContactsFRC.fetchedObjects.count;
    return rowsCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GJContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[GJContactTableViewCell reuseIdentifier]];
    cell.delegate = self;
    [cell reloadCellWithContactEntity:nil];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
