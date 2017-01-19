//
//  GJContactsBookViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsBookViewController.h"
#import "GJContactDetailsViewController.h"
#import <CoreData/CoreData.h>
#import "APIClient.h"
#import "GJContactTableViewCell.h"
#import "AppDelegate.h"
#import "NSString+Additions.h"

@interface GJContactsBookViewController ()<NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, GJContactTableViewCellDelegate>

@property (strong, nonatomic) NSFetchedResultsController *myContactsFRC;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation GJContactsBookViewController

- (NSPersistentContainer *)persistentContainer {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).persistentContainer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Contact Book";
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"contactsFetched"])
    {
        [[APIClient defaultClient] getContactsWithCompletionBlock:^(NSError *error, id data) {
            
            NSManagedObjectContext *context = [self persistentContainer].viewContext;
            
            [context performBlock:^{
                
                NSArray *contacts = (NSArray*)data;
                for(NSDictionary *contactInfo in contacts)
                {
                    GJContactEntity *contactEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([GJContactEntity class]) inManagedObjectContext:context];
                    contactEntity.contactId = [[contactInfo objectForKey:@"id"] integerValue];
                    contactEntity.firstName = [contactInfo objectForKey:@"first_name"];
                    contactEntity.lastName = [contactInfo objectForKey:@"last_name"];
                    contactEntity.imageUrl = [contactInfo objectForKey:@"profile_pic"];
                    //contactEntity.email = [contactInfo objectForKey:@""];
                    //contactEntity.phone = [contactInfo objectForKey:@""];
                    //contactEntity.isFavorite = NO;
                }
                
                NSError	*error	= nil;
                [context save:(&error)];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"contactsFetched"];
                [self loadContacts];
            }];
        }];
    }
    else
    {
        [self loadContacts];
    }
}

- (void)loadContacts
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([GJContactEntity class])];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]];
    self.myContactsFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self persistentContainer].viewContext sectionNameKeyPath:@"firstName.stringGroupByFirstInitial" cacheName:nil];
    self.myContactsFRC.delegate = self;
    [self.myContactsFRC performFetch:nil];
    [self.tableView reloadData];
}

- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView
{
    return [self.myContactsFRC sectionIndexTitles];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.myContactsFRC sectionForSectionIndexTitle:title atIndex:index];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.myContactsFRC sections].count;
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
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    header.backgroundColor = [UIColor lightGrayColor];
    header.font = [UIFont boldSystemFontOfSize:15.0f];
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.myContactsFRC sections][section];
    header.text = [NSString stringWithFormat:@"  %@",sectionInfo.name];
    return header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.myContactsFRC sections][section];
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
    [cell reloadCellWithContactEntity:[self.myContactsFRC objectAtIndexPath:indexPath]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GJContactDetailsViewController *detailsVC = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GJContactDetailsViewController class])];
    detailsVC.contactEntity = [self.myContactsFRC objectAtIndexPath:indexPath];
    [self.navigationController pushViewController:detailsVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
