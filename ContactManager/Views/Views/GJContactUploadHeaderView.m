//
//  GJContactUploadHeaderView.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactUploadHeaderView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface GJContactUploadHeaderView ()

/* UI */
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *contactNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *progressImageView;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@end

@implementation GJContactUploadHeaderView

+ (instancetype)viewFromNib {
    return [self viewFromNib:nil bundle:nil];
}

+ (instancetype)viewFromNib:(NSString *)nib bundle:(NSBundle *)bundle {
    Class viewClass = self.class;
    
    NSString * nibName = nib ?: NSStringFromClass(viewClass);
    NSBundle * nibBundle = bundle ?: [NSBundle mainBundle];
    
    NSArray * loadedObjects = [nibBundle loadNibNamed:nibName owner:nil options:nil];
    for (id object in loadedObjects) {
        if ( [object isKindOfClass:viewClass] ) {
            return object;
        }
    }
    
    return nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    //_contactNameLabel.text = _contactToUpload
    
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
    
}

+ (CGFloat)viewHeight
{
    return 75.0f;
}

@end
