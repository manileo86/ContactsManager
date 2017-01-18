//
//  GJContactTableViewCell.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <UIKit/UIKit.h>
#import "GJContactEntity+CoreDataClass.h"

@protocol GJContactTableViewCellDelegate;

@interface GJContactTableViewCell : UITableViewCell

@property (weak, nonatomic) id <GJContactTableViewCellDelegate> delegate;

- (void)reloadCellWithContactEntity:(GJContactEntity *)contactEntity;
+ (NSString *)reuseIdentifier;

@end

@protocol GJContactTableViewCellDelegate <NSObject>

@optional

@end

