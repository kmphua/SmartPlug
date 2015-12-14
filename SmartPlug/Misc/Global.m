//
//  Global.m
//  PosApp
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
        case COLOR_TYPE_TEXTBOX_BG:
        case COLOR_TYPE_BUTTON_UP:
        {
            color = [UIColor colorWithRed:181/255.0f green:181/255.0f blue:181/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_LINK:
        case COLOR_TYPE_BUTTON_DOWN:
        {
            color = [UIColor colorWithRed:252/255.0f green:184/255.0f blue:48/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_LIST_BG:
        {
            color = [UIColor colorWithRed:160/255.0f green:160/255.0f blue:160/255.0f alpha:0.7f];
            break;
        }
        case COLOR_TYPE_BODY_BG:
        {
            color = [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:0.2f];
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

@end
