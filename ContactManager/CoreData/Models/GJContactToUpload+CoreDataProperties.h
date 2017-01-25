//
//  GJContactToUpload+CoreDataProperties.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 25/01/17.
//  Copyright © 2017 GJ. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "GJContactToUpload+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface GJContactToUpload (CoreDataProperties)

+ (NSFetchRequest<GJContactToUpload *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *params;
@property (nullable, nonatomic, retain) NSData *image;
@property (nonatomic) BOOL isUploading;
@property (nonatomic) BOOL isFailed;
@property (nonatomic) BOOL isUploadPending;
@end

NS_ASSUME_NONNULL_END
