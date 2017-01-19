//
//  GJContactDetailsViewController.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <UIKit/UIKit.h>
#import "GJContactEntity+CoreDataClass.h"

@interface GJContactDetailsViewController : UIViewController

@property(nonatomic, strong) GJContactEntity *contactEntity;

@end

