//
//  GJContactDetailsViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactDetailsViewController.h"
#import "UIImageView+Network.h"
#import "GJContactsSyncManager.h"
#import "AppDelegate.h"

@interface GJContactDetailsViewController ()<NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@end

@implementation GJContactDetailsViewController

- (NSPersistentContainer *)persistentContainer {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).persistentContainer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"Detail";
    
    [[GJContactsSyncManager defaultManager] getContactDetailsForId:[NSString stringWithFormat:@"%lld",self.contactId] withCompletionBlock:^{

        
        NSManagedObjectContext *context = [self persistentContainer].viewContext;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contactId == %@", [NSString stringWithFormat:@"%lld",_contactId]];
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([GJContactEntity class])
                                                  inManagedObjectContext:[self persistentContainer].viewContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = entity;
        fetchRequest.predicate = predicate;
        fetchRequest.fetchLimit = 1;
        fetchRequest.sortDescriptors = [NSMutableArray array];
        
        NSError *requestError = nil;
        NSArray *result = [context executeFetchRequest:fetchRequest error:&requestError];
        
        NSMutableArray *sortDescriptors = [NSMutableArray array];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
        self.fetchedResultsController.delegate = self;
        [self.fetchedResultsController performFetch:&requestError];
        
        NSArray *objs = [self.fetchedResultsController fetchedObjects];        
        GJContactEntity *contactEntity = result[0];
        self.contactEntity = contactEntity;
        [_avatarView loadImageFromURL:[NSURL URLWithString:_contactEntity.imageUrl] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
        
        _nameLabel.text = [NSString stringWithFormat:@"%@ %@", _contactEntity.firstName, _contactEntity.lastName];
        _phoneLabel.text = _contactEntity.phone;
        _emailLabel.text = _contactEntity.email;
    }];
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_avatarView loadImageFromURL:[NSURL URLWithString:_contactEntity.imageUrl] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
    
    _nameLabel.text = [NSString stringWithFormat:@"%@ %@", _contactEntity.firstName, _contactEntity.lastName];
    _phoneLabel.text = _contactEntity.phone;
    _emailLabel.text = _contactEntity.email;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
