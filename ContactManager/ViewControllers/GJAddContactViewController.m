//
//  GJAddContactViewController.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJAddContactViewController.h"
#import "GJContactsSyncManager.h"
#import "UIColor+HexString.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+FixOrientation.h"
#import "GJContactsRetryManager.h"

@interface GJAddContactViewController ()<UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UITextField *firstnameField;
@property (weak, nonatomic) IBOutlet UILabel *firstnameErrorLabel;
@property (weak, nonatomic) IBOutlet UITextField *lastnameField;
@property (weak, nonatomic) IBOutlet UILabel *lastnameErrorLabel;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;
@property (weak, nonatomic) IBOutlet UILabel *phoneErrorLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UILabel *emailErrorLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissKeyboardButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *firstNameLabelTopContraint;
@property (assign, nonatomic) BOOL imagePicked;

@end

@implementation GJAddContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add Contact";
    self.dismissKeyboardButton.hidden = YES;
    
    _firstnameField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    _lastnameField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    _phoneField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    _emailField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    
    CGColorRef errorBorderColor = [UIColor colorWithHexString:@"FFC7C8"].CGColor;
    _firstnameField.layer.borderColor = errorBorderColor;
    _lastnameField.layer.borderColor = errorBorderColor;
    _phoneField.layer.borderColor = errorBorderColor;
    _emailField.layer.borderColor = errorBorderColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.firstNameLabelTopContraint.constant = 20.0f;
    self.avatarButton.hidden = YES;
    self.dismissKeyboardButton.hidden = NO;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.firstNameLabelTopContraint.constant = 140.0f;
    self.avatarButton.hidden = NO;
    self.dismissKeyboardButton.hidden = YES;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.25f animations:^{        
        [self.view layoutIfNeeded];
    }];
    
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == _firstnameField)
    {
        [_lastnameField becomeFirstResponder];
        return NO;
    }
    else if(textField == _lastnameField)
    {
        [_phoneField becomeFirstResponder];
        return NO;
    }
    else if(textField == _phoneField)
    {
        [_emailField becomeFirstResponder];
        return NO;
    }
    else if(textField == _emailField)
    {
        [_emailField resignFirstResponder];
        return YES;
    }
    else
    {
        return YES;
    }
}

- (IBAction)dismissKeyboardPressed:(id)sender
{
    [self.view endEditing:YES];
}

#pragma mark - Validation

- (BOOL)isInputsValid
{
    BOOL bOK = [self isFirstNameValid];
    bOK &= [self isLastNameValid];
    bOK &= [self isPhoneNumberValid];
    bOK &= [self isEmailValid];
    return bOK;
}

- (void)resetValidationUIHighlights
{
    _firstnameField.layer.borderWidth = 0;
    _lastnameField.layer.borderWidth = 0;
    _phoneField.layer.borderWidth = 0;
    _emailField.layer.borderWidth = 0;
    
    _firstnameErrorLabel.hidden = YES;
    _lastnameErrorLabel.hidden = YES;
    _phoneErrorLabel.hidden = YES;
    _emailErrorLabel.hidden = YES;
}

-(BOOL)isFirstNameValid
{
    if(_firstnameField.text.length < 3)
    {
        _firstnameField.layer.borderWidth = 1.0f;
        _firstnameErrorLabel.hidden = NO;
        return FALSE;
    }
    
    return TRUE;
}

-(BOOL)isLastNameValid
{
    // No validation as of now
    return TRUE;
}

-(BOOL)isPhoneNumberValid
{
    __block BOOL bOK = NO;
    NSString *phoneNumber = _phoneField.text;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:nil];
    [detector enumerateMatchesInString:phoneNumber
                               options:kNilOptions
                                 range:NSMakeRange(0, [phoneNumber length])
                            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         bOK = (result.phoneNumber && result.phoneNumber.length > 0);
     }];
    
    if(!bOK)
    {
        _phoneField.layer.borderWidth = 1.0f;
        _phoneErrorLabel.hidden = NO;
    }
    return bOK;
}

-(BOOL)isEmailValid
{
    NSString *email = _emailField.text;
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    BOOL bOK = [emailPredicate evaluateWithObject:email];
    
    if(!bOK)
    {
        _emailField.layer.borderWidth = 1.0f;
        _emailErrorLabel.hidden = NO;
    }
    
    return bOK;
}

#pragma mark - Save

- (IBAction)savePressed:(id)sender
{
    [self resetValidationUIHighlights];
    
    if(![self isInputsValid])
    {
        return;
    }
    
    [self.view endEditing:YES];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *dateFromString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary *contactInfo = @{
                                  @"first_name": _firstnameField.text,
                                  @"last_name": _lastnameField.text,
                                  @"email": _emailField.text,
                                  @"phone_number": _phoneField.text,
                                  @"favorite":@"false",
                                  //@"profile_pic": @"",
                                  @"created_at":dateFromString,
                                  @"updated_at":dateFromString
                                  };
    
    [[GJContactsSyncManager defaultManager] createContactToUploadWithImage:self.imagePicked?_avatarButton.imageView.image:nil andInfo:contactInfo withCompletionBlock:^{
        NSLog(@"CONTACT TO UPLOAD CREATED");
        [[GJContactsRetryManager defaultManager] checkAndStartUpload];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - Photo picker

-(IBAction)avatarPressed:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                 delegate:self
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:nil
                        otherButtonTitles:@"Open Camera", @"Select from Gallery", self.imagePicked?@"Remove Photo":nil, nil];
    actionSheet.destructiveButtonIndex = 2;
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [self.avatarButton setImage:[UIImage imageNamed:@"default_avatar"] forState:UIControlStateNormal];
        self.imagePicked = NO;
    }
    else if(buttonIndex == 0)
    {
        // open camera
        [self presentPickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
    }
    else if(buttonIndex == 1)
    {
        // open gallery
        [self presentPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    else if(buttonIndex == 2)
    {
        // delete photo
        [self.avatarButton setImage:[UIImage imageNamed:@"default_avatar"] forState:UIControlStateNormal];
        self.imagePicked = NO;
    }
    else
    {
        [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
    }
}

- (void)presentPickerWithSourceType:(UIImagePickerControllerSourceType)type {
    
    /* Check for camera avaliability */
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusDenied && type == UIImagePickerControllerSourceTypeCamera) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera access permission denied"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (![UIImagePickerController isSourceTypeAvailable:type]) {
        return;
    }
    
    UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
    pickerVC.sourceType = type;
    pickerVC.delegate = self;
    pickerVC.allowsEditing = YES;
    
    if (type == UIImagePickerControllerSourceTypeCamera) {
        pickerVC.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    [self presentViewController:pickerVC animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    image = [image imageWithFixedOrientation];    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self.avatarButton setImage:image forState:UIControlStateNormal];
    self.imagePicked = YES;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
