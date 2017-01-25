//
//  GJContactUploadHeaderView.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactUploadHeaderView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "GJContactsSyncManager.h"
#import "GJContactEntity+CoreDataClass.h"

@interface GJContactUploadHeaderView ()

/* UI */
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *contactNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *progressImageView;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@end

@implementation GJContactUploadHeaderView

//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    [self commonInit];
//}

//- (void)setContactToUpload:(GJContactToUpload *)contactToUpload
//{
//    _contactToUpload = contactToUpload;
//    [self commonInit];
//}

- (void)loadViewWithContactToUpload:(GJContactToUpload*)contactToUpload
{
    self.contactToUpload = contactToUpload;
    [self commonInit];
}

- (void)commonInit
{
    if(!self.contactToUpload)
        return;
    
    __block NSDictionary *contactInfo = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:_contactToUpload.params];
    
    _contactNameLabel.text = [NSString stringWithFormat:@"%@ %@", contactInfo[@"first_name"], contactInfo[@"last_name"]];
    
    if(_contactToUpload.image)
        _avatarView.image = [UIImage imageWithData:_contactToUpload.image];
    else
        _avatarView.image = [UIImage imageNamed:@"default_avatar"];
    
    if(_contactToUpload.isUploadPending)
    {
        [self tryUploading];
    }
    
    if(_contactToUpload.isUploading)
    {
        NSURL *fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"loading_bar.gif" ofType:nil]];
        [_progressImageView sd_setImageWithURL:fileURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        }];
    }
    else
    {
        [_progressImageView setImage:[UIImage imageNamed:@"loading_bar_frame"]];
    }
    
    if(_contactToUpload.isFailed)
    {
        _retryButton.hidden = NO;
    }
    else
    {
        _retryButton.hidden = YES;
    }
}

- (IBAction)retryPressed:(id)sender
{
    [self tryUploading];
}

- (void)tryUploading
{
    if(_contactToUpload.isUploading)
    {
        return;
    }
    
    _contactToUpload.isUploading = YES;
        
    __block NSDictionary *contactInfo = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:_contactToUpload.params];
    
    if(_contactToUpload.image)
    {
        [[GJContactsSyncManager defaultManager] uploadImageData:_contactToUpload.image withCompletionBlock:^(NSError *error, NSString *imageId) {
            if(!error)
            {
                __block NSMutableDictionary *updatedInfo = [contactInfo mutableCopy];
                [updatedInfo setObject:imageId forKey:@"profile_pic"];
                _contactToUpload.params = [NSKeyedArchiver archivedDataWithRootObject:updatedInfo];
                NSError *error = nil;
                if (![_contactToUpload.managedObjectContext save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                
                [[GJContactsSyncManager defaultManager] postContactDetails:updatedInfo withCompletionBlock:^(NSError *error, NSDictionary *data) {
                    if(!error)
                    {
                        [[GJContactsSyncManager defaultManager] createContactFromInfo:contactInfo removeContactUpload:_contactToUpload withCompletionBlock:^{
                            
                        }];
                    }
                    else
                    {
                        _contactToUpload.isFailed = YES;
                        _contactToUpload.isUploading = NO;
                        _contactToUpload.isUploadPending = NO;
                        NSError *error = nil;
                        if (![_contactToUpload.managedObjectContext save:&error]) {
                            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                        }
                        [self commonInit];
                    }
                }];
            }
            else
            {
                _contactToUpload.isFailed = YES;
                _contactToUpload.isUploading = NO;
                _contactToUpload.isUploadPending = NO;
                NSError *error = nil;
                if (![_contactToUpload.managedObjectContext save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                [self commonInit];
            }
        }];
    }
    else
    {
        [[GJContactsSyncManager defaultManager] postContactDetails:contactInfo withCompletionBlock:^(NSError *error, NSDictionary *data) {
            if(!error)
            {
                [[GJContactsSyncManager defaultManager] createContactFromInfo:contactInfo removeContactUpload:_contactToUpload withCompletionBlock:^{
                    
                }];
            }
            else
            {
                _contactToUpload.isFailed = YES;
                _contactToUpload.isUploading = NO;
                _contactToUpload.isUploadPending = NO;
                NSError *error = nil;
                if (![_contactToUpload.managedObjectContext save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                [self commonInit];
            }
        }];
    }
}

+ (CGFloat)viewHeight
{
    return 75.0f;
}

@end
