//
//  VCFGenerator.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <Foundation/Foundation.h>
#import "GJContactEntity+CoreDataClass.h"

@interface VCFGenerator : NSObject
+ (NSString *)generateVCardStringFor:(GJContactEntity *)contact;

@end
