//
//  GJContactDetailsViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactDetailsViewController.h"
#import "UIImageView+Network.h"

@interface GJContactDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@end

@implementation GJContactDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"Detail";
    
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
