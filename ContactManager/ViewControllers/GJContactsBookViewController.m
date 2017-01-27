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
#import "GJContactsRetryManager.h"

@interface GJContactsBookViewController ()<NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, GJContactTableViewCellDelegate>

@property (strong, nonatomic) NSFetchedResultsController *contactsFRC;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addContactButton;
@property (weak, nonatomic) IBOutlet UIView *noContactView;
@property (weak, nonatomic) IBOutlet UILabel *noContactLabel;
@property (weak, nonatomic) IBOutlet GJContactUploadHeaderView *headerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerViewHeightContraint;
@property (strong, nonatomic) UIBarButtonItem *favoriteButton;
@property (assign, nonatomic) BOOL isFavoritesFilterOn;

@end

@implementation GJContactsBookViewController

- (NSPersistentContainer *)persistentContainer {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).persistentContainer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self subscribeForNotifications];
    self.navigationController.navigationBarHidden = NO;
    self.title = @"Contact Book";
    [self loadContacts];
    [self applyShadowToAddContactButton];
    [GJContactsRetryManager sharedManager];
    
    self.favoriteButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"heart_grey"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(favoritePressed)];
    self.navigationItem.rightBarButtonItem = self.favoriteButton;
}

- (void)viewWillAppear:(BOOL)animated
{
     [super viewWillAppear:animated];
}

- (void)subscribeForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshData:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactToUploadUpdated:)
                                                 name:GJContactUploadNotification
                                               object:nil];
}

- (void)loadContacts
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([GJContactEntity class])];
    if(self.isFavoritesFilterOn)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite == 1"];
        fetchRequest.predicate = predicate;
    }
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    fetchRequest.sortDescriptors = @[sd];
    self.contactsFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self persistentContainer].viewContext sectionNameKeyPath:@"firstName.stringGroupByFirstInitial" cacheName:nil];
    self.contactsFRC.delegate = self;
    [self.contactsFRC performFetch:nil];
    [self.tableView reloadData];
    
    _tableView.hidden = (self.contactsFRC.fetchedObjects.count==0);
    _noContactLabel.text = self.isFavoritesFilterOn?@"No Favortie Contacts":@"No Contact Found";
}

- (void)loadContactsToUpload:(GJContactToUpload*)contactToUpload
{
    if(!contactToUpload)
        contactToUpload = [[GJContactsRetryManager sharedManager] currentContactToUpload];

    self.headerViewHeightContraint.constant = contactToUpload?[GJContactUploadHeaderView viewHeight]:0;
    self.headerView.hidden = contactToUpload?NO:YES;
    [self.headerView loadViewWithContactToUpload:contactToUpload];
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.25f animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)contactToUploadUpdated:(NSNotification*)notification
{
    GJContactToUpload *contactToUpload = (GJContactToUpload*)[notification object];
    [self loadContactsToUpload:contactToUpload];
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
    header.text = [NSString stringWithFormat:@"    %@",[sectionInfo.name uppercaseString]];
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
    [self refreshUI];
}

- (void)refreshUI
{
    [self.tableView reloadData];    
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
    if([[GJContactsRetryManager sharedManager] currentContactToUpload])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"A Contact is being uploaded, Please wait.. "
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GJAddContactViewController *addVC = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GJAddContactViewController class])];
    [self.navigationController pushViewController:addVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Favorites

- (void)favoritePressed
{
    self.isFavoritesFilterOn = !self.isFavoritesFilterOn;
    self.favoriteButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:self.isFavoritesFilterOn?@"heart":@"heart_grey"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(favoritePressed)];
    self.navigationItem.rightBarButtonItem = self.favoriteButton;
    [self loadContacts];
}

@end
