//
//  GJContactToUpload+CoreDataProperties.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 25/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "GJContactToUpload+CoreDataProperties.h"

@implementation GJContactToUpload (CoreDataProperties)

+ (NSFetchRequest<GJContactToUpload *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"GJContactToUpload"];
}

@dynamic params;
@dynamic image;
@dynamic isUploading;
@dynamic isFailed;
@dynamic isUploadPending;

@end
