//
//  GJContactTableViewCell.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactTableViewCell.h"
#import "UIImageView+Network.h"

@interface GJContactTableViewCell ()

/* UI */
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

@end

@implementation GJContactTableViewCell

- (void)reloadCellWithContactEntity:(GJContactEntity *)contactEntity
{
    _nameLabel.text = [NSString stringWithFormat:@"%@ %@", contactEntity.firstName, contactEntity.lastName];
    [_avatarView loadImageFromURL:[NSURL URLWithString:contactEntity.imageUrl] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
