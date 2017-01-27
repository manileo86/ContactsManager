//
//  GJContactDetailsViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactDetailsViewController.h"
#import "GJContactsSyncManager.h"
#import "AppDelegate.h"
#import "UIButton+Position.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <MessageUI/MessageUI.h>
#import "VCFGenerator.h"

@interface GJContactDetailsViewController ()<NSFetchedResultsControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIButton *phoneButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;

@property (strong, nonatomic) NSFetchedResultsController *contactFRC;
@property(nonatomic, strong) GJContactEntity *contactEntity;

@end

@implementation GJContactDetailsViewController

- (NSPersistentContainer *)persistentContainer {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).persistentContainer;
}

- (void) refreshData:(NSNotification *)notif {
    [[[self contactFRC] managedObjectContext] mergeChangesFromContextDidSaveNotification:notif];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"Detail";
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share_contact"] style:UIBarButtonItemStylePlain target:self action:@selector(sharePressed)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    

    
    _nameButton.hidden = YES;
    _phoneButton.hidden = YES;
    _emailButton.hidden = YES;
    
    [self.nameButton centerButtonAndImageWithSpacing:10.0f];
    [self.phoneButton centerButtonAndImageWithSpacing:10.0f];
    [self.emailButton centerButtonAndImageWithSpacing:10.0f];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshData:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    NSManagedObjectContext *context = [self persistentContainer].viewContext;
    [context setStalenessInterval:0];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contactId == %@", [NSString stringWithFormat:@"%lld",_contactId]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([GJContactEntity class])
                                              inManagedObjectContext:[self persistentContainer].viewContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    fetchRequest.sortDescriptors = [NSMutableArray array];
    
    self.contactFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.contactFRC.delegate = self;
    NSError *requestError = nil;
    [self.contactFRC performFetch:&requestError];
    
    NSArray *objs = [self.contactFRC fetchedObjects];
    _contactEntity = [objs firstObject];
    
    if(!_contactEntity.isInfoFetched)
    {
        [[GJContactsSyncManager sharedManager] getContactDetailsForId:[NSString stringWithFormat:@"%lld",_contactEntity.contactId] withCompletionBlock:^{
        }];
    }
    [self refreshUI];
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self refreshUI];
}

- (void)refreshUI
{
    [self.nameButton setImage:[UIImage imageNamed:_contactEntity.isFavorite?@"heart":@"heart_grey"] forState:UIControlStateNormal];
    
    [_avatarView sd_setImageWithURL:[NSURL URLWithString:_contactEntity.imageUrl] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
    
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", _contactEntity.firstName, _contactEntity.lastName];
    [_nameButton setTitle:fullName forState:UIControlStateNormal];
    [_phoneButton setTitle:_contactEntity.phone forState:UIControlStateNormal];
    [_emailButton setTitle:_contactEntity.email forState:UIControlStateNormal];
    
    _nameButton.hidden = fullName.length==0;
    _phoneButton.hidden = _contactEntity.phone.length==0;
    _emailButton.hidden = _contactEntity.email.length==0;
}

#pragma mark - Actions

- (void)sharePressed
{
    NSString *vcf = [VCFGenerator generateVCardStringFor:self.contactEntity];
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"contact"] URLByAppendingPathExtension:@"vcf"];    
    // remove old file
    NSError *error;
    if([[NSFileManager defaultManager] fileExistsAtPath:[fileURL absoluteString]])
    {
        [[NSFileManager defaultManager] removeItemAtPath:[fileURL absoluteString] error:&error];
        if(error)
        {
            NSLog(@"Old file not deleted");
        }
    }

    
    BOOL succeed = [vcf writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"contact.vcf"]
                              atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (succeed)
    {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.contactEntity.firstName, fileURL] applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"Sorry, Not able to share this contact"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (IBAction)nameButtonPressed:(id)sender
{
    BOOL favStatus = !_contactEntity.isFavorite;
    
    [[[self contactFRC] managedObjectContext] performBlock:^{
        _contactEntity.isFavorite = favStatus;
        [[[self contactFRC] managedObjectContext] save:nil];
        [self refreshUI];
    }];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSString *dateFromString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary *contactInfo = @{@"id":[NSString stringWithFormat:@"%lld",_contactId],
                                  @"favorite":favStatus?@"true":@"false",
                                  @"updated_at":dateFromString
                                  };
    [[GJContactsSyncManager sharedManager] updateContactDetails:contactInfo withCompletionBlock:^(NSError *error, NSDictionary *data) {
    }];
}

- (IBAction)phoneButtonPressed:(id)sender
{
    [[[UIActionSheet alloc] initWithTitle:_contactEntity.phone
                                 delegate:self
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:nil
                        otherButtonTitles:@"Call", @"Message", nil] showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", _contactEntity.phone]];
        [[UIApplication sharedApplication] openURL:url];
    }
    else if(buttonIndex == 1)
    {
        if ([MFMessageComposeViewController canSendText]) {
            
            MFMessageComposeViewController *messageComposeVC = [[MFMessageComposeViewController alloc] init];
            messageComposeVC.recipients = @[_contactEntity.phone];
            messageComposeVC.body = @"";
            messageComposeVC.delegate = (id <UINavigationControllerDelegate>)self;
            messageComposeVC.messageComposeDelegate = (id <MFMessageComposeViewControllerDelegate>)self;
            [self presentViewController:messageComposeVC animated:YES completion:nil];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"This device is not configured to send messages."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
    else
    {
        [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)mailButtonPressed:(id)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        [controller setToRecipients:@[_contactEntity.email]];
        [controller setMessageBody:@"" isHTML:NO];
        [controller setSubject:@"Hi"];
        [controller setMailComposeDelegate:(id)[self class]];
        [self presentViewController:controller animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"This device is not configured to send email."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
