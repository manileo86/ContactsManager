//
//  NSString+Additions.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "NSString+Additions.h"

@implementation NSString(Additions)

- (NSString *)stringGroupByFirstInitial {
    if (!self.length || self.length == 1)
        return self;
    return [self substringToIndex:1];
}

@end
