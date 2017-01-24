//
//  UIButton+Position.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "UIButton+Position.h"

@implementation UIButton(Position)

-(void) centerButtonAndImageWithSpacing:(CGFloat)spacing {
    self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacing);
    self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
}

@end
