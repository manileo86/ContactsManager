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
#import "GJContactsRetryManager.h"

@interface GJContactUploadHeaderView ()

/* UI */
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *contactNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *progressImageView;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@end

@implementation GJContactUploadHeaderView

- (void)loadViewWithContactToUpload:(GJContactToUpload*)contactToUpload
{
    self.contactToUpload = contactToUpload;
    [self commonInit];
}

- (void)commonInit
{
    if(!self.contactToUpload)
    {
        _contactNameLabel.text = @"Contact Name";
        _avatarView.image = [UIImage imageNamed:@"default_avatar"];
        _retryButton.hidden = YES;
        [_progressImageView setImage:[UIImage imageNamed:@"loading_bar_frame"]];
        return;
    }
    
    __block NSDictionary *contactInfo = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:_contactToUpload.params];
    
    _contactNameLabel.text = [NSString stringWithFormat:@"%@ %@", contactInfo[@"first_name"], contactInfo[@"last_name"]];
    
    if(_contactToUpload.image)
        _avatarView.image = [UIImage imageWithData:_contactToUpload.image];
    else
        _avatarView.image = [UIImage imageNamed:@"default_avatar"];
    
    if(_contactToUpload.isUploading)
    {
        if(_contactToUpload.isFailed)
        {
            [_progressImageView setImage:[UIImage imageNamed:@"loading_bar_frame"]];
        }
        else
        {
            NSURL *fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"loading_bar.gif" ofType:nil]];
            [_progressImageView sd_setImageWithURL:fileURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            }];
        }
    }
    else
    {
        [_progressImageView setImage:[UIImage imageNamed:@"loading_bar_frame"]];
    }
    
    if(_contactToUpload.isFailed)
    {
        _retryButton.hidden = NO;
        [_progressImageView setImage:[UIImage imageNamed:@"loading_bar_frame"]];
    }
    else
    {
        _retryButton.hidden = YES;
    }
}

- (IBAction)retryPressed:(id)sender
{
    [[GJContactsRetryManager defaultManager] checkAndStartUpload];
}

+ (CGFloat)viewHeight
{
    return 75.0f;
}

@end
