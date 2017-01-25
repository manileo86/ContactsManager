//
//  GJContactEntity+CoreDataProperties.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 25/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "GJContactEntity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface GJContactEntity (CoreDataProperties)

+ (NSFetchRequest<GJContactEntity *> *)fetchRequest;

@property (nonatomic) int64_t contactId;
@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nullable, nonatomic, copy) NSString *email;
@property (nullable, nonatomic, copy) NSString *firstName;
@property (nullable, nonatomic, copy) NSString *imageUrl;
@property (nonatomic) BOOL isFavorite;
@property (nonatomic) BOOL isInfoFetched;
@property (nullable, nonatomic, copy) NSString *lastName;
@property (nullable, nonatomic, copy) NSString *phone;
@property (nullable, nonatomic, copy) NSDate *updatedAt;

@end

NS_ASSUME_NONNULL_END
