//
//  GJAddContactViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJAddContactViewController.h"
#import "GJContactsSyncManager.h"

@interface GJAddContactViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UITextField *firstnameField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameField;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissKeyboardButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *firstNameLabelTopContraint;

@end

@implementation GJAddContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dismissKeyboardButton.hidden = YES;
    
    _firstnameField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    _lastnameField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    _phoneField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    _emailField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.firstNameLabelTopContraint.constant = 20.0f;
    self.avatarView.hidden = YES;
    self.dismissKeyboardButton.hidden = NO;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.firstNameLabelTopContraint.constant = 190.0f;
    self.avatarView.hidden = NO;
    self.dismissKeyboardButton.hidden = YES;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{        
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)dismissKeyboardPressed:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)savePressed:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *dateFromString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary *contactInfo = @{
        @"first_name": _firstnameField.text,
        @"last_name": _lastnameField.text,
        @"email": _emailField.text,
        @"phone_number": _phoneField.text,
        //@"profile_pic": @"",
        @"created_at":dateFromString,
        @"updated_at":dateFromString
        };
    [[GJContactsSyncManager defaultManager] postContactDetails:contactInfo withCompletionBlock:^(NSError *error, NSDictionary *data) {        
    }];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
