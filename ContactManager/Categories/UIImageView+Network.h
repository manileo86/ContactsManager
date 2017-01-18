//
//  UIImage+Network.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <UIKit/UIKit.h>

@interface UIImageView(Network)

@property (nonatomic, copy) NSURL *imageURL;

- (void) loadImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholder;

@end
