//
//  EHTextRenderer.h
//  TextRendering
//
//  Created by 손동우 on 2016. 7. 8..
//  Copyright © 2016년 easthelper. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EHTextRenderer : NSObject

@property (nonatomic, assign) CGPoint point;
@property (nonatomic, assign) int bufferWidth;
@property (nonatomic, assign) int bufferHeight;
@property (nonatomic, assign) float strokeWidth;

-(instancetype)initWithX:(int)x
                       y:(int)y
                fontSize:(int)fontSize
         foregroundColor:(UIColor *)foregroundColor
             strokeWidth:(float)strokeWidth
             strokeColor:(UIColor *)strokeColor
                     msg:(NSString *)msg;
    
+ (UIImage *)textImageAtX:(int)x
                        y:(int)y
                 fontSize:(int)fontSize
          foregroundColor:(UIColor *)foregroundColor
              strokeWidth:(float)strokeWidth
              strokeColor:(UIColor *)strokeColor
                      msg:(NSString *)msg;

+ (UIImage *)imageFromBuffer:(unsigned char *)buffer
                 bufferWidth:(NSUInteger)bufferWidth
                bufferHeight:(NSUInteger)bufferHeight
                bufferLength:(NSUInteger)bufferLength
                       scale:(CGFloat)scale;

-(void)drawTextToBuffer:(unsigned char *)buffer;

- (UIImage *)imageFromBuffer:(unsigned char *)buffer;

- (NSUInteger)bufferLength;
- (float)scale;

@end
