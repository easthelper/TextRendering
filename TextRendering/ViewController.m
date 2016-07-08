//
//  ViewController.m
//  TextRendering
//
//  Created by 손동우 on 2016. 6. 27..
//  Copyright © 2016년 easthelper. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    int _bufferWidth;
    int _bufferHeight;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

const NSUInteger bytesPerPixel = 4;
const NSUInteger bitsPerComponent = 8;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    int fontSize = 30;
    const char * text = "King of Ping Pong\nKing of Ping Pong";
    float scale = self.scale;
    
    UIImage *image = [self IPhoneDrawTextToBufferAtX:0 y:0 fontSize:fontSize a:255 r:255 g:0 b:0 strokeWidth:5 sa:255 sr:255 sg:255 sb:255 msg:text];
    
    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0, _bufferWidth/scale, _bufferHeight/scale);
    
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
    // 스케일은 여기서 담당
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
    UIFont *scaledfont = [UIFont systemFontOfSize:fontSize * scale];
    float scaledStrokeWidth = strokeWidth * scale;
    
    NSDictionary *strokeAttribute =
    @{
      NSFontAttributeName: scaledfont,
      NSStrokeColorAttributeName: strokeColor,
      NSStrokeWidthAttributeName: @(scaledStrokeWidth)
      };
    
    NSDictionary *foregroundAttribute =
    @{
      NSFontAttributeName: scaledfont,
      NSForegroundColorAttributeName: foregroundColor,
      
      // stroke 없이는 문자 렌더링 모양이 살짝 다르므로 stroke와 fill의 중심이 살짝 어긋나는 문제가 발생함.
      // 투명색으로 강제로 inner stroke 를 줌.
      NSStrokeColorAttributeName: [UIColor clearColor],
      NSStrokeWidthAttributeName: @(-1)
      };
    
    CGSize scaledTextSize = [str sizeWithAttributes: strokeAttribute];
    
    // calculate pixelbased size
    int textWidth = scaledTextSize.width + scaledStrokeWidth;
    int textHeight = scaledTextSize.height + scaledStrokeWidth;
    
    CGSize textPixelSize = CGSizeMake(textWidth, textHeight);
    NSLog(@"g_renderedTextSize %@", NSStringFromCGSize(textPixelSize));
    
    // clipping buffer size
    _bufferWidth = MIN(textPixelSize.width, 512 * scale);
    _bufferHeight = MIN(textPixelSize.height, 512 * scale);

    unsigned char *rawData = (unsigned char*) calloc(self.bufferLength, sizeof(unsigned char));
    
    [self drawTextToBufferAtX:0 y:0
              strokeAttribute:strokeAttribute
          foregroundAttribute:foregroundAttribute
                  strokeWidth:scaledStrokeWidth
                          msg:str
                       buffer:rawData];
    
    // create image from rawdata
    UIImage *image = [self imageFromBuffer:rawData
                               bufferWidth:_bufferWidth
                              bufferHeight:_bufferHeight];
    
    free(rawData);
    
    return image;
}

-(void)drawTextToBufferAtX:(int)x
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
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 self.bitmapInfo);
    
    // CGContextSetAllowsAntialiasing( context, false );
    // CGContextSetInterpolationQuality( context, kCGInterpolationHigh );
    CGContextTranslateCTM(context, 0.0f, (_bufferHeight) );
    CGContextScaleCTM(context, 1.0f, -1.0f); //NOTE: NSString draws in UIKit referential i.e. renders upside-down compared to CGBitmapContext referential
    UIGraphicsPushContext(context);
    
    CGContextSetShouldSubpixelQuantizeFonts(context, false);
    CGContextSetShouldSubpixelPositionFonts(context, false);
//    CGContextSetShouldAntialias( context, false );
    // CGContextSetTextDrawingMode(context, kCGTextStroke);
    [str drawInRect:CGRectMake(0 + strokeWidth / 2, 0 + strokeWidth / 2, 10000, 512 * self.scale) withAttributes: strokeAttribute];
    
    // CGContextSetTextDrawingMode(context, kCGTextFill);
    [str drawInRect:CGRectMake(0 + strokeWidth / 2, 0 + strokeWidth / 2, 10000, 512 * self.scale) withAttributes: foregroundAttribute];
    
    UIGraphicsPopContext();
    CGContextRelease(context);
    
    CGColorSpaceRelease(colorSpace);
}

- (UIImage *)imageFromBuffer:(unsigned char *)buffer
                 bufferWidth:(NSUInteger)bufferWidth
                bufferHeight:(NSUInteger)bufferHeight {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create cgimage from rawdata
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              buffer,
                                                              self.bufferLength,
                                                              NULL);
    
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(_bufferWidth,
                                        _bufferHeight,
                                        bitsPerComponent,
                                        32,
                                        4*_bufferWidth,
                                        colorSpace,
                                        self.bitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    
    CGColorSpaceRelease(colorSpace);
    
    /*I get the current dimensions displayed here */
    NSLog(@"width=%zu, height: %zu", CGImageGetWidth(imageRef),
          CGImageGetHeight(imageRef) );
    
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:0];
    return image;
}

- (CGBitmapInfo)bitmapInfo {
    return kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
}

- (NSUInteger)bufferLength {
    return _bufferWidth * _bufferHeight * bytesPerPixel;
}

- (float)scale {
//    return [UIScreen mainScreen].scale;
    return 2;
}

@end
