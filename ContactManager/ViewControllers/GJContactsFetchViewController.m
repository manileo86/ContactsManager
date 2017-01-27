//
//  GJContactsFetchViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsFetchViewController.h"
#import "GJContactsSyncManager.h"
#import "GJContactsBookViewController.h"

@interface GJContactsFetchViewController ()

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@end

@implementation GJContactsFetchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupListeners];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBarHidden = YES;
    
    [[GJContactsSyncManager sharedManager] fetchContacts];
}

- (void) setupListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBeginContactsFetch)
                                                 name:GJContactsFetchDidBeginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndContactsFetch)
                                                     name:GJContactsFetchDidEndNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailContactsFetch:)
                                                 name:GJContactsFetchDidFailNotification object:nil];
}

- (void)didBeginContactsFetch
{
    self.statusLabel.text = @"Fetching Contacts";
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
}

- (void)didEndContactsFetch
{
    self.statusLabel.text = @"";
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GJContactsBookViewController *bookVC = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([GJContactsBookViewController class])];
    
    [self.navigationController setViewControllers:[NSArray arrayWithObject:bookVC] animated:YES];
}

- (void)didFailContactsFetch:(NSNotification*)notification
{
    self.statusLabel.text = notification.object[@"error"];// @"Contacts Fetching Failed";
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
    
    self.retryButton.hidden = NO;
}

- (IBAction)retryPressed:(id)sender
{
    self.retryButton.hidden = YES;    
    [[GJContactsSyncManager sharedManager] fetchContacts];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
