//
//  ViewController.m
//  TextRendering
//
//  Created by 손동우 on 2016. 6. 27..
//  Copyright © 2016년 easthelper. All rights reserved.
//

#import "ViewController.h"
#import "EHTextRenderer.h"

@interface ViewController () {
    int _bufferWidth;
    int _bufferHeight;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

const NSUInteger bytesPerPixel = 4;
const NSUInteger bitsPerComponent = 8;
const NSUInteger kBufferWidthMax = 512;
const NSUInteger kBufferHeightMax = 512;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    int fontSize = 30;
    NSString *text = @"안녕하세요\nHello PingPong";

    UIColor *foregroundColor = [UIColor redColor];
    UIColor *strokeColor = [UIColor blackColor];
    
//    UIImage *image = [EHTextRenderer textImageAtX:0 y:0
//                                          fontSize:fontSize
//                                   foregroundColor:foregroundColor
//                                       strokeWidth:2
//                                       strokeColor:strokeColor
//                                               msg:text];
    
    
    EHTextRenderer *renderer = [[EHTextRenderer alloc] initWithX:0 y:0
                                                        fontSize:fontSize
                                                 foregroundColor:foregroundColor
                                                     strokeWidth:2
                                                     strokeColor:strokeColor
                                                             msg:text];
    
    unsigned char *rawData = (unsigned char*) calloc(renderer.bufferLength, sizeof(unsigned char));
    
    [renderer drawTextToBuffer:rawData];
    UIImage *image = [renderer imageFromBuffer:rawData];
    
    free(rawData);
    
//
//    
    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0,
                                      image.size.width,
                                      image.size.height);
    
    self.label.font = [UIFont systemFontOfSize:fontSize];
    self.label.numberOfLines = 0;
    self.label.text = text;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
