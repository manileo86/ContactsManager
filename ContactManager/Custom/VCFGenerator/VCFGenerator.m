//
//  VCFGenerator.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "VCFGenerator.h"
#import "NSData+Base64.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCache.h>

@implementation VCFGenerator

+ (NSString *)generateVCardStringFor:(GJContactEntity *)contact
{
    NSString *vcard = @"BEGIN:VCARD\nVERSION:3.0\n";
    
    // First name / Last name
    vcard = [vcard stringByAppendingFormat:@"N:%@;%@;;;\n",
             ((contact.lastName && contact.lastName.length>0) ? contact.lastName : @""),
             ((contact.firstName && contact.firstName.length>0) ? contact.firstName : @"")];
    
    vcard = [vcard stringByAppendingFormat:@"FN:%@ %@\n",
             ((contact.firstName && contact.firstName.length>0) ? contact.firstName : @""),
             ((contact.lastName && contact.lastName.length>0) ? contact.lastName : @"")];
    
    // Phone
    if (contact.phone && contact.phone.length>0)
    {
        NSString *phoneString = [NSString stringWithFormat:@"TEL;type=CELL:%@\n",contact.phone];
        vcard = [vcard stringByAppendingString:phoneString];
    }
    
    // Email
    if (contact.email && contact.email.length>0)
    {
        NSString *emailString = [NSString stringWithFormat:@"EMAIL;type=INTERNET;type=HOME:%@\n",contact.email];
        vcard = [vcard stringByAppendingString:emailString];
    }
    
    // Profile Pic
    if (contact.imageUrl && contact.imageUrl.length>0){
        if([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:contact.imageUrl]])
        {
            UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:contact.imageUrl];
            UIImage *thumbImage =  [VCFGenerator imageWithImage:image scaledToFillSize:CGSizeMake(128.0f, 128.0f)];
            NSData *imageData = UIImagePNGRepresentation(thumbImage);
            if (imageData)
            {
                vcard = [vcard stringByAppendingFormat:@"PHOTO;BASE64:%@\n",[imageData base64EncodedStringWithOptions:0]];
            }
        }
    }
    
    // end
    vcard = [vcard stringByAppendingString:@"END:VCARD"];
    
    return vcard;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
