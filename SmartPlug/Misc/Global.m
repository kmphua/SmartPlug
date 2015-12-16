//
//  Global.m
//  SmartPlug
//
//  Created by Kevin Phua on 9/16/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Global.h"

@implementation Global

+ (UIColor *)colorWithType:(ColorType)type
{
    UIColor *color;
    switch (type) {
        case COLOR_TYPE_NAVBAR_BG:
        {
            color = [UIColor colorWithRed:79/255.0f green:171/255.0f blue:167/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_DEFAULT_BG:
        {
            color = [UIColor colorWithRed:239/255.0f green:244/255.0f blue:244/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_LINK:
        {
            color = [UIColor darkGrayColor];
            break;
        }
        case COLOR_TYPE_TITLE_BG_BLUE:
        {
            color = [UIColor colorWithRed:91/255.0f green:181/255.0f blue:206/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_TITLE_BG_RED:
        {
            color = [UIColor colorWithRed:253/255.0f green:98/255.0f blue:94/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_TITLE_BG_GREEN:
        {
            color = [UIColor colorWithRed:136/255.0f green:186/255.0f blue:63/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_TITLE_BG_YELLOW:
        {
            color = [UIColor colorWithRed:255/255.0f green:190/255.0f blue:21/255.0f alpha:1.0f];
            break;
        }
        default:
            break;
    }
    return color;
}

+ (CGImageRef)createQRImageForString:(NSString *)string size:(CGSize)size {
    // Setup the QR filter with our string
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage *image = [filter valueForKey:@"outputImage"];
    
    // Calculate the size of the generated image and the scale for the desired image size
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size.width / CGRectGetWidth(extent), size.height / CGRectGetHeight(extent));
    
    // Since CoreImage nicely interpolates, we need to create a bitmap image that we'll draw into
    // a bitmap context at the desired size;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // Create an image with the contents of our bitmap
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    // Cleanup
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return scaledImage;
}

+ (NSString *)getCurrentLang {
    //NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    //return language;
    return @"en";
}

@end
