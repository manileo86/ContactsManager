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
    
    //return [self substringToIndex:1];
    
    unichar c = [self characterAtIndex:0];
    NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
    if ([numericSet characterIsMember:c])
    {
       return @"#";
    }
    else
    {
        return [[NSString stringWithCharacters:&c length:1] lowercaseString];
    }
}

-(BOOL)isNumeric
{
    NSScanner *sc = [NSScanner scannerWithString:[self substringToIndex:1]];
    // We can pass NULL because we don't actually need the value to test
    // for if the string is numeric. This is allowable.
    if ( [sc scanFloat:NULL] )
    {
        // Ensure nothing left in scanner so that "42foo" is not accepted.
        // ("42" would be consumed by scanFloat above leaving "foo".)
        return [sc isAtEnd];
    }
    // Couldn't even scan a float :(
    return NO;
}

@end
