//
//  GJContactUploadHeaderView.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <UIKit/UIKit.h>
#import "GJContactToUpload+CoreDataClass.h"

@interface GJContactUploadHeaderView : UIView

+ (CGFloat)viewHeight;

@property(nonatomic, strong) GJContactToUpload *contactToUpload;

@end
