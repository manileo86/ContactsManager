//
//  GJContactEntity+CoreDataProperties.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 25/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "GJContactEntity+CoreDataProperties.h"

@implementation GJContactEntity (CoreDataProperties)

+ (NSFetchRequest<GJContactEntity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"GJContactEntity"];
}

@dynamic contactId;
@dynamic createdAt;
@dynamic email;
@dynamic firstName;
@dynamic imageUrl;
@dynamic isFavorite;
@dynamic isInfoFetched;
@dynamic lastName;
@dynamic phone;
@dynamic updatedAt;

@end
