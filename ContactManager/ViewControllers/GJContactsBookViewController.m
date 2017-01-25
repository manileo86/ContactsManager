//
//  GJContactsBookViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsBookViewController.h"
#import "GJContactDetailsViewController.h"
#import "GJAddContactViewController.h"
#import <CoreData/CoreData.h>
#import "APIClient.h"
#import "GJContactTableViewCell.h"
#import "AppDelegate.h"
#import "NSString+Additions.h"
#import "UIColor+HexString.h"
#import "GJContactToUpload+CoreDataClass.h"
#import "GJContactUploadHeaderView.h"

@interface GJContactsBookViewController ()<NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, GJContactTableViewCellDelegate>

@property (strong, nonatomic) NSFetchedResultsController *contactsFRC;
@property (strong, nonatomic) NSFetchedResultsController *contactToUploadFRC;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addContactButton;
@property (weak, nonatomic) IBOutlet GJContactUploadHeaderView *headerView;

@end

@implementation GJContactsBookViewController

- (NSPersistentContainer *)persistentContainer {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).persistentContainer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshData:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    self.navigationController.navigationBarHidden = NO;
    self.title = @"Contact Book";
    [self loadContacts];
    [self loadContactsToUpload];
    [self applyShadowToAddContactButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGRect expectedFrame = CGRectMake(0.0,0.0,self.tableView.bounds.size.width, [GJContactUploadHeaderView viewHeight]);
    if (!CGRectEqualToRect(self.headerView.frame, expectedFrame)) {
        self.headerView.frame = expectedFrame;
        self.tableView.tableHeaderView = self.headerView;
    }
}

- (void)loadContacts
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([GJContactEntity class])];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES];
    fetchRequest.sortDescriptors = @[sd];
    self.contactsFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self persistentContainer].viewContext sectionNameKeyPath:@"firstName.stringGroupByFirstInitial" cacheName:nil];
    self.contactsFRC.delegate = self;
    [self.contactsFRC performFetch:nil];
    [self.tableView reloadData];
}

- (void)loadContactsToUpload
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([GJContactToUpload class])];
    fetchRequest.sortDescriptors = @[];
    self.contactToUploadFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self persistentContainer].viewContext sectionNameKeyPath:nil cacheName:nil];
    self.contactToUploadFRC.delegate = self;
    [self.contactToUploadFRC performFetch:nil];
    
    GJContactToUpload *contactToUpload = [self.contactToUploadFRC.fetchedObjects firstObject];
    if(!contactToUpload)
    {
        [self.headerView loadViewWithContactToUpload:nil];
        self.tableView.tableHeaderView = nil;
    }
    else
    {
        self.tableView.tableHeaderView = self.headerView;
        [self.headerView loadViewWithContactToUpload:contactToUpload];
    }
}

//- (NSArray *)sectionIndexTitlesForTableView: (UITableView *) tableView
//{
//    return [self.contactsFRC sectionIndexTitles];
//}

#pragma mark - UITableViewDataSource

//- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
//{
//    return [self.contactsFRC sectionForSectionIndexTitle:title atIndex:index];
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.contactsFRC sections].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    header.backgroundColor = [UIColor colorWithHexString:@"BBE7F3"];
    header.font = [UIFont boldSystemFontOfSize:15.0f];
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.contactsFRC sections][section];
    header.text = [NSString stringWithFormat:@"    %@",sectionInfo.name];
    return header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.contactsFRC sections][section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GJContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[GJContactTableViewCell reuseIdentifier]];
    cell.delegate = self;
    [cell reloadCellWithContactEntity:[self.contactsFRC objectAtIndexPath:indexPath]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GJContactDetailsViewController *detailsVC = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GJContactDetailsViewController class])];
    detailsVC.contactId = ((GJContactEntity*)[self.contactsFRC objectAtIndexPath:indexPath]).contactId;
    [self.navigationController pushViewController:detailsVC animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if(controller == _contactsFRC)
        [self refreshUI];
    else
    {
        GJContactToUpload *contactToUpload = [self.contactToUploadFRC.fetchedObjects firstObject];
        if(!contactToUpload)
        {
            [self.headerView loadViewWithContactToUpload:nil];
            self.tableView.tableHeaderView = nil;
        }
        else
        {
            self.tableView.tableHeaderView = self.headerView;
            [self.headerView loadViewWithContactToUpload:contactToUpload];
        }
    }
}

- (void)refreshUI
{
    [self.tableView reloadData];
    //[self loadContactsToUpload];
}

- (void) refreshData:(NSNotification *)notif {
    [[[self contactsFRC] managedObjectContext] mergeChangesFromContextDidSaveNotification:notif];
}

#pragma mark - Add Contact

- (void) applyShadowToAddContactButton
{
    _addContactButton.layer.masksToBounds = NO;
    _addContactButton.layer.shadowColor = [UIColor grayColor].CGColor;
    _addContactButton.layer.shadowOpacity = 0.8;
    _addContactButton.layer.shadowRadius = 10.0f;
    _addContactButton.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
}

-(IBAction)addContactButtonPressed:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GJAddContactViewController *addVC = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GJAddContactViewController class])];
    [self.navigationController pushViewController:addVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
