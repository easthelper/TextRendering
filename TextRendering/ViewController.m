//
//  ViewController.m
//  TextRendering
//
//  Created by 손동우 on 2016. 6. 27..
//  Copyright © 2016년 easthelper. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

CGSize g_renderedTextSize;
CGSize g_finalRenderedSize;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    int fontSize = 20;
    const char * text = "안녕하새오; 고생이 만아오\nhello world\nhello world\n";
    float scale = self.scale;
    
    UIImage *image = [self IPhoneDrawTextToBufferAtX:0 y:0 fontSize:fontSize a:255 r:255 g:0 b:0 strokeWidth:10 sa:255 sr:255 sg:255 sb:255 msg:text];
//    unsigned char *buffer = NULL;
//    [self drawTextToBufferAtX:0 y:0 fontSize:fontSize a:255 r:255 g:0 b:0 strokeWidth:10 sa:255 sr:255 sg:255 sb:255 msg:text buffer:&buffer];
    
    
    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0, g_finalRenderedSize.width/scale, g_finalRenderedSize.height/scale);
    
    self.label.font = [UIFont systemFontOfSize:fontSize];
    self.label.numberOfLines = 0;
    self.label.text = [NSString stringWithUTF8String:text];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIImage *)IPhoneDrawTextToBufferAtX:(int)x
                               y:(int)y
                        fontSize:(int)fontSize
                               a:(int)a
                               r:(int)r
                               g:(int)g
                               b:(int)b
                     strokeWidth:(float)strokeWidth
                              sa:(int)sa
                              sr:(int)sr
                              sg:(int)sg
                              sb:(int)sb
                             msg:(const char *)msg
{
    float scale = self.scale;
    NSString *str = [NSString stringWithUTF8String:msg];
    
    NSLog(@"%d,%d,%d %d,%d,%d,%d %f, %d,%d,%d,%d %@ ", x,y,fontSize,a,r,g,b,strokeWidth,sa,sr,sg,sb,str);
    
    UIColor *foregroundColor = [UIColor colorWithRed:r/255.f
                                               green:g/255.f
                                                blue:b/255.f
                                               alpha:a/255.f];
    UIColor *strokeColor = [UIColor colorWithRed:sr/255.f
                                           green:sg/255.f
                                            blue:sb/255.f
                                           alpha:sa/255.f];
    // handle scale
    UIFont *font = [UIFont systemFontOfSize:fontSize * scale];
    strokeWidth *= scale;
    
    NSDictionary *strokeAttribute =
    @{
      NSFontAttributeName: font,
      NSForegroundColorAttributeName: strokeColor,
      NSStrokeWidthAttributeName: @(strokeWidth)
      };
    
    NSDictionary *foregroundAttribute =
    @{
      NSFontAttributeName: font,
      NSForegroundColorAttributeName: foregroundColor,
      };
    
    CGSize textSize = [str sizeWithAttributes: strokeAttribute];
    int textWidth = textSize.width + strokeWidth * 2;
    int textHeight = textSize.height + strokeWidth * 2;
    
    g_renderedTextSize = CGSizeMake(textWidth, textHeight);
    NSLog(@"g_renderedTextSize %@", NSStringFromCGSize(g_renderedTextSize));
    CGSize size = g_renderedTextSize;
    // UIGraphicsBeginImageContext(size);
    // UIGraphicsBeginImageContextWithOptions (size, false, 2.0f);
    
    int bufferWidth = MIN(size.width, 512 * scale);
    int bufferHeight = MIN(size.height, 512 * scale);
    
    g_finalRenderedSize = CGSizeMake(bufferWidth, bufferHeight);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * bufferWidth;
    NSUInteger bitsPerComponent = 8;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bufferLength = bufferWidth * bufferHeight * bytesPerPixel;
    unsigned char *rawData = (unsigned char*) calloc(bufferLength, sizeof(unsigned char));
    
    CGContextRef context = CGBitmapContextCreate(
                                                 rawData,
                                                 bufferWidth,
                                                 bufferHeight,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // CGContextSetAllowsAntialiasing( context, false );
    // CGContextSetInterpolationQuality( context, kCGInterpolationHigh );
    CGContextTranslateCTM(context, 0.0f, (bufferHeight - strokeWidth) );
    CGContextScaleCTM(context, 1.0f, -1.0f); //NOTE: NSString draws in UIKit referential i.e. renders upside-down compared to CGBitmapContext referential
    UIGraphicsPushContext(context);
    
    CGContextSetShouldSubpixelQuantizeFonts(context, false);
    CGContextSetShouldSubpixelPositionFonts(context, false);
//    CGContextSetShouldAntialias( context, false );
    // CGContextSetTextDrawingMode(context, kCGTextStroke);
    [str drawInRect:CGRectMake(0 + strokeWidth, 0 + strokeWidth, 10000, 512) withAttributes: strokeAttribute];
    
    // CGContextSetTextDrawingMode(context, kCGTextFill);
    [str drawInRect:CGRectMake(0 + strokeWidth, 0 + strokeWidth, 10000, 512) withAttributes: foregroundAttribute];
    
    // UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // NSLog(@"image %@", NSStringFromCGSize(image.size));
    // NSLog(@"image %d", CGImageGetWidth(image.CGImage));
    
    UIGraphicsPopContext();
    CGContextRelease(context);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              rawData,
                                                              bufferLength,
                                                              NULL);
    
    
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(bufferWidth,
                                        bufferHeight,
                                        bitsPerComponent,
                                        32,
                                        4*bufferWidth,
                                        colorSpace,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    /*I get the current dimensions displayed here */
    NSLog(@"width=%zu, height: %zu", CGImageGetWidth(imageRef),
          CGImageGetHeight(imageRef) );
//    UIImage *image = [UIImage imageWithCGImage:imageRef];
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:scale orientation:0];
    
    free(rawData);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

-(void)drawTextToBufferAtX:(int)x
                                    y:(int)y
                             fontSize:(int)fontSize
                                    a:(int)a
                                    r:(int)r
                                    g:(int)g
                                    b:(int)b
                          strokeWidth:(float)strokeWidth
                                   sa:(int)sa
                                   sr:(int)sr
                                   sg:(int)sg
                                   sb:(int)sb
                                  msg:(const char *)msg
                    buffer:(unsigned char **)buffer
{
    float scale = self.scale;
    NSString *str = [NSString stringWithUTF8String:msg];
    
    NSLog(@"%d,%d,%d %d,%d,%d,%d %f, %d,%d,%d,%d %@ ", x,y,fontSize,a,r,g,b,strokeWidth,sa,sr,sg,sb,str);
    
    UIColor *foregroundColor = [UIColor colorWithRed:r/255.f
                                               green:g/255.f
                                                blue:b/255.f
                                               alpha:a/255.f];
    UIColor *strokeColor = [UIColor colorWithRed:sr/255.f
                                           green:sg/255.f
                                            blue:sb/255.f
                                           alpha:sa/255.f];
    // handle scale
    UIFont *font = [UIFont systemFontOfSize:fontSize * scale];
    strokeWidth *= scale;
    
    NSDictionary *strokeAttribute =
    @{
      NSFontAttributeName: font,
      NSForegroundColorAttributeName: strokeColor,
      NSStrokeWidthAttributeName: @(strokeWidth)
      };
    
    NSDictionary *foregroundAttribute =
    @{
      NSFontAttributeName: font,
      NSForegroundColorAttributeName: foregroundColor,
      };
    
    CGSize textSize = [str sizeWithAttributes: strokeAttribute];
    int textWidth = textSize.width + strokeWidth * 2;
    int textHeight = textSize.height + strokeWidth * 2;
    
    g_renderedTextSize = CGSizeMake(textWidth, textHeight);
    NSLog(@"g_renderedTextSize %@", NSStringFromCGSize(g_renderedTextSize));
    CGSize size = g_renderedTextSize;
    
    int bufferWidth = MIN(size.width, 512 * scale);
    int bufferHeight = MIN(size.height, 512 * scale);
    
    g_finalRenderedSize = CGSizeMake(bufferWidth, bufferHeight);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * bufferWidth;
    NSUInteger bitsPerComponent = 8;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bufferLength = bufferWidth * bufferHeight * bytesPerPixel;
    *buffer = (unsigned char*) calloc(bufferLength, sizeof(unsigned char));
    
    CGContextRef context = CGBitmapContextCreate(
                                                 buffer,
                                                 bufferWidth,
                                                 bufferHeight,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // CGContextSetAllowsAntialiasing( context, false );
    // CGContextSetInterpolationQuality( context, kCGInterpolationHigh );
    CGContextTranslateCTM(context, 0.0f, (bufferHeight - strokeWidth) );
    CGContextScaleCTM(context, 1.0f, -1.0f); //NOTE: NSString draws in UIKit referential i.e. renders upside-down compared to CGBitmapContext referential
    UIGraphicsPushContext(context);
    
    CGContextSetShouldSubpixelQuantizeFonts(context, false);
    CGContextSetShouldSubpixelPositionFonts(context, false);
    //    CGContextSetShouldAntialias( context, false );
    // CGContextSetTextDrawingMode(context, kCGTextStroke);
    [str drawInRect:CGRectMake(0 + strokeWidth, 0 + strokeWidth, 10000, 512) withAttributes: strokeAttribute];
    
    // CGContextSetTextDrawingMode(context, kCGTextFill);
    [str drawInRect:CGRectMake(0 + strokeWidth, 0 + strokeWidth, 10000, 512) withAttributes: foregroundAttribute];
    
    UIGraphicsPopContext();
    CGContextRelease(context);
    
    
//    free(rawData);
    CGColorSpaceRelease(colorSpace);
    
//    return image;
}


- (float)scale {
    return [UIScreen mainScreen].scale;
//    return 1;
}

@end
