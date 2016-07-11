//
//  EHTextRenderer.m
//  TextRendering
//
//  Created by 손동우 on 2016. 7. 8..
//  Copyright © 2016년 easthelper. All rights reserved.
//

#import "EHTextRenderer.h"

@interface EHTextRenderer () {
    
}

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSDictionary *strokeAttribute;
@property (nonatomic, strong) NSDictionary *foregroundAttribute;

@end

const static NSUInteger bytesPerPixel = 4;
const static NSUInteger kBitsPerComponent = 8;
const static NSUInteger kBufferWidthMax = 512;
const static NSUInteger kBufferHeightMax = 512;
const static CGBitmapInfo kBitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;

@implementation EHTextRenderer

-(instancetype)initWithX:(int)x
                       y:(int)y
                fontSize:(int)fontSize
         foregroundColor:(UIColor *)foregroundColor
             strokeWidth:(float)strokeWidth
             strokeColor:(UIColor *)strokeColor
                     msg:(NSString *)msg {
    self = [super init];
    if (self) {
        [self _initWithX:x y:y
                fontSize:fontSize
         foregroundColor:foregroundColor
             strokeWidth:strokeWidth
             strokeColor:strokeColor
                     msg:msg];
    }
    return self;
}

-(void)_initWithX:(int)x
               y:(int)y
        fontSize:(int)fontSize
  foregroundColor:(UIColor *)foregroundColor
      strokeWidth:(float)strokeWidth
      strokeColor:(UIColor *)strokeColor
             msg:(NSString *)msg {
    // 스케일은 여기서 담당
    const float scale = self.scale;
    self.text = msg;
    self.strokeWidth = strokeWidth;
    self.point = CGPointMake(x, y);
    
    NSLog(@"%d,%d,%d %f, %@ ", x,y,fontSize,strokeWidth,msg);
    
    // handle scale
    UIFont *scaledfont = [UIFont systemFontOfSize:fontSize * scale];
    
    NSDictionary *strokeAttribute =
    @{
      NSFontAttributeName: scaledfont,
      NSStrokeColorAttributeName: strokeColor,
      NSStrokeWidthAttributeName: @(self.scaledStrokeWidth)
      };
    
    NSDictionary *foregroundAttribute =
    @{
      NSFontAttributeName: scaledfont,
      NSForegroundColorAttributeName: foregroundColor,
      
      // stroke 없이는 문자 렌더링 모양이 살짝 다르므로 stroke와 fill의 중심이 살짝 어긋나는 문제가 발생함.
      // 투명색으로 강제로 inner stroke 를 줌.
      NSStrokeColorAttributeName: [UIColor clearColor],
      NSStrokeWidthAttributeName: @(self.scaledStrokeWidth == 0 ? 0 : -1)
      };
    self.strokeAttribute = strokeAttribute;
    self.foregroundAttribute = foregroundAttribute;
    
    CGSize textPixelSize = [EHTextRenderer estimatedSizeWithString:msg
                                                        attributes:strokeAttribute
                                                       strokeWidth:self.scaledStrokeWidth];
    NSLog(@"g_renderedTextSize %@", NSStringFromCGSize(textPixelSize));
    
    // clipping with max buffer size
    _bufferWidth = MIN(textPixelSize.width, kBufferWidthMax * scale);
    _bufferHeight = MIN(textPixelSize.height, kBufferHeightMax * scale);
}

+ (void)drawTextToBufferAtX:(int)x
                          y:(int)y
                   fontSize:(int)fontSize
            foregroundColor:(UIColor *)foregroundColor
                strokeWidth:(float)strokeWidth
                strokeColor:(UIColor *)strokeColor
                        msg:(NSString *)msg
                     buffer:(unsigned char *)buffer
{
    EHTextRenderer *renderer = [[EHTextRenderer alloc] initWithX:x y:y
                                                        fontSize:fontSize
                                                 foregroundColor:foregroundColor
                                                     strokeWidth:strokeWidth
                                                     strokeColor:strokeColor
                                                             msg:msg];
    
    [renderer drawTextToBuffer:buffer];
}

+ (UIImage *)textImageAtX:(int)x
                        y:(int)y
                 fontSize:(int)fontSize
          foregroundColor:(UIColor *)foregroundColor
              strokeWidth:(float)strokeWidth
              strokeColor:(UIColor *)strokeColor
                      msg:(NSString *)msg
{
    EHTextRenderer *renderer = [[EHTextRenderer alloc] initWithX:x y:y
            fontSize:fontSize
     foregroundColor:foregroundColor
         strokeWidth:strokeWidth
         strokeColor:strokeColor
                 msg:msg];
    
    unsigned char *rawData = (unsigned char*) calloc(renderer.bufferLength, sizeof(unsigned char));
    
    [renderer drawTextToBuffer:rawData];
    UIImage *image = [renderer imageFromBuffer:rawData];
    
    free(rawData);
    
    return image;
}

-(void)drawTextToBuffer:(unsigned char *)buffer {
    [self _drawTextToBufferAtX:self.scaledPoint.x y:self.scaledPoint.y
               strokeAttribute:self.strokeAttribute
           foregroundAttribute:self.foregroundAttribute
                   strokeWidth:self.scaledStrokeWidth
                           msg:self.text
                        buffer:buffer];
}


// 이곳에서 스케일 다루지 말 것??
-(void)_drawTextToBufferAtX:(int)x
                          y:(int)y
            strokeAttribute:(NSDictionary *)strokeAttribute
        foregroundAttribute:(NSDictionary *)foregroundAttribute
                strokeWidth:(float)strokeWidth
                        msg:(NSString *)str
                     buffer:(unsigned char *)buffer
{
    NSUInteger bytesPerRow = bytesPerPixel * _bufferWidth;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(
                                                 buffer,
                                                 _bufferWidth,
                                                 _bufferHeight,
                                                 kBitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kBitmapInfo);
    
    // CGContextSetAllowsAntialiasing( context, false );
    // CGContextSetInterpolationQuality( context, kCGInterpolationHigh );
    CGContextTranslateCTM(context, 0.0f, (_bufferHeight) );
    CGContextScaleCTM(context, 1.0f, -1.0f); //NOTE: NSString draws in UIKit referential i.e. renders upside-down compared to CGBitmapContext referential
    UIGraphicsPushContext(context);
    
    CGContextSetShouldSubpixelQuantizeFonts(context, false);
    CGContextSetShouldSubpixelPositionFonts(context, false);
    //    CGContextSetShouldAntialias( context, false );
    
    [str drawInRect:CGRectMake(0 + strokeWidth / 2, 0 + strokeWidth / 2, 10000, kBufferWidthMax * self.scale) withAttributes: strokeAttribute];
    [str drawInRect:CGRectMake(0 + strokeWidth / 2, 0 + strokeWidth / 2, 10000, kBufferWidthMax * self.scale) withAttributes: foregroundAttribute];
    
    UIGraphicsPopContext();
    CGContextRelease(context);
    
    CGColorSpaceRelease(colorSpace);
}

- (UIImage *)imageFromBuffer:(unsigned char *)buffer {
    return [EHTextRenderer imageFromBuffer:buffer
                               bufferWidth:self.bufferWidth
                              bufferHeight:self.bufferHeight
                              bufferLength:self.bufferLength
                                     scale:self.scale];
}

+ (UIImage *)imageFromBuffer:(unsigned char *)buffer
                 bufferWidth:(NSUInteger)bufferWidth
                bufferHeight:(NSUInteger)bufferHeight
                bufferLength:(NSUInteger)bufferLength
                       scale:(CGFloat)scale {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create cgimage from rawdata
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              buffer,
                                                              bufferLength,
                                                              NULL);
    
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(bufferWidth,
                                        bufferHeight,
                                        kBitsPerComponent,
                                        32,
                                        4*bufferWidth,
                                        colorSpace,
                                        kBitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    /*I get the current dimensions displayed here */
    NSLog(@"width=%zu, height: %zu", CGImageGetWidth(imageRef),
          CGImageGetHeight(imageRef) );
    
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:scale orientation:0];
    
    CGImageRelease(imageRef);
    
    return image;
}

+ (CGSize)estimatedSizeWithString:(NSString *)text
                       attributes:(NSDictionary *)attributes
                      strokeWidth:(float)strokeWidth {
    CGSize scaledTextSize = [text sizeWithAttributes: attributes];
    
    // calculate pixelbased size
    int textWidth = scaledTextSize.width + strokeWidth;
    int textHeight = scaledTextSize.height + strokeWidth;
    
    CGSize textPixelSize = CGSizeMake(textWidth, textHeight);
    NSLog(@"g_renderedTextSize %@", NSStringFromCGSize(textPixelSize));

    return textPixelSize;
}

- (NSUInteger)bufferLength {
    return _bufferWidth * _bufferHeight * bytesPerPixel;
}

- (float)scale {
    //    return [UIScreen mainScreen].scale;
    return 2;
}

- (float)scaledStrokeWidth {
    return _strokeWidth * self.scale;
}

- (CGPoint)scaledPoint {
    return CGPointMake(_point.x * self.scale, _point.y * self.scale);
}

@end
